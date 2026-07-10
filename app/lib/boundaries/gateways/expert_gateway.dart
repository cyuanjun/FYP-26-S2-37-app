import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/deliverable.dart';
import '../../entities/enums.dart';
import '../../entities/expert_category.dart';
import '../../entities/expert_profile.dart';
import '../../entities/expert_service.dart';
import '../../entities/expert_summary.dart';
import '../../entities/public_profile.dart';
import '../../entities/service_request.dart';
import '../../entities/service_request_summary.dart';

// (#) The whole expert marketplace side of Supabase: the expert directory,
// (#) service listings, requests, deliverables, and the review RPCs. Controls use
// (#) it to browse experts and run an engagement start to finish. Payment is faked.
class ExpertGateway {
  // (#) Keeps the Supabase client used across all marketplace calls.
  ExpertGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client for every query here

  // (#) The safe public columns to pull when embedding a person's identity.
  static const _identitySelect =
      'id, first_name, last_name, username, avatar_url, level, bio';

  // (#) Lists the active expert categories, A to Z, for the browse filters.
  Future<List<ExpertCategory>> listCategories() async {
    final rows = await _client
        .from('expert_categories')
        .select()
        .eq('is_active', true)
        .order('label', ascending: true);
    return rows.map(ExpertCategory.fromJson).toList();
  }

  // (#) Loads every expert with their identity and services, best-rated first.
  // (#) RLS only shows live services to anyone but the expert who owns them.
  Future<List<ExpertSummary>> listExperts() async {
    final rows = await _client
        .from('expert_profiles')
        .select('*, identity:public_profiles!expert_profiles_id_fkey('
            '$_identitySelect), services:expert_services(*)')
        .order('rating_avg', ascending: false);
    return rows
        .map((r) => ExpertSummary(
              identity:
                  PublicProfile.fromJson(r['identity'] as Map<String, dynamic>),
              profile: ExpertProfile.fromJson(r),
              services: ((r['services'] as List?) ?? const [])
                  .map((s) => ExpertService.fromJson(s as Map<String, dynamic>))
                  .toList(),
            ))
        .toList();
  }

  // (#) Loads every live service plus who offers it, cheapest first.
  Future<List<ServiceListing>> listServices() async {
    final rows = await _client
        .from('expert_services')
        .select('*, expert:expert_profiles!expert_services_expert_user_id_fkey('
            '*, identity:public_profiles!expert_profiles_id_fkey('
            '$_identitySelect))')
        .eq('status', 'live')
        .order('price_cents', ascending: true);
    return rows.map((r) {
      final expert = r['expert'] as Map<String, dynamic>;
      return ServiceListing(
        service: ExpertService.fromJson(r),
        expertIdentity:
            PublicProfile.fromJson(expert['identity'] as Map<String, dynamic>),
        expertProfile: ExpertProfile.fromJson(expert),
      );
    }).toList();
  }

  // (#) The embedded columns to pull with each request: its service,
  // (#) deliverables, and whether a review exists.
  static const _requestSelect = '*, '
      'service:expert_services!service_requests_expert_service_id_fkey(*), '
      'deliverables(*), reviews:expert_reviews(id)';

  // (#) Lists the requests a user has bought, newest first, for MY PURCHASES.
  Future<List<ServiceRequestSummary>> listMyRequests(String userId) async {
    final rows = await _client
        .from('service_requests')
        .select('$_requestSelect, other:public_profiles!'
            'service_requests_expert_user_id_fkey($_identitySelect)')
        .eq('user_id', userId)
        .order('requested_at', ascending: false);
    return rows.map(_summaryFromRow).toList();
  }

  // (#) Lists the requests coming in to an expert, newest first, for their inbox.
  Future<List<ServiceRequestSummary>> listIncomingRequests(
      String expertId) async {
    final rows = await _client
        .from('service_requests')
        .select('$_requestSelect, other:public_profiles!'
            'service_requests_user_id_fkey($_identitySelect)')
        .eq('expert_user_id', expertId)
        .order('requested_at', ascending: false);
    return rows.map(_summaryFromRow).toList();
  }

  // (#) Builds a request summary from one embedded row, folding in its service,
  // (#) the other party, deliverables, and whether it has been reviewed.
  ServiceRequestSummary _summaryFromRow(Map<String, dynamic> r) {
    // expert_reviews.service_request_id is UNIQUE, so PostgREST embeds the
    // review one-to-one: a single object (or null), not a list.
    final reviews = r['reviews'];
    return ServiceRequestSummary(
      request: ServiceRequest.fromJson(r),
      service: r['service'] == null
          ? null
          : ExpertService.fromJson(r['service'] as Map<String, dynamic>),
      otherParty: r['other'] == null
          ? null
          : PublicProfile.fromJson(r['other'] as Map<String, dynamic>),
      deliverables: ((r['deliverables'] as List?) ?? const [])
          .map((d) => Deliverable.fromJson(d as Map<String, dynamic>))
          .toList(),
      reviewed: reviews is Map || (reviews is List && reviews.isNotEmpty),
    );
  }

  // (#) Places a new request, copying the service's current price onto it as the
  // (#) quote. Payment is simulated so this is just a row insert.
  Future<void> createRequest({
    required String userId,
    required ExpertService service,
    required String message,
  }) =>
      _client.from('service_requests').insert({
        'user_id': userId,
        'expert_service_id': service.id,
        'expert_user_id': service.expertUserId,
        'quoted_price_cents': service.priceCents,
        'request_message': message.trim(),
      });

  // (#) Status changes and reviews all go through server-side RPCs, since direct
  // (#) table writes for these are blocked.

  // (#) Expert accepts a request via the accept_service_request RPC.
  Future<void> acceptRequest(String requestId) =>
      _client.rpc('accept_service_request', params: {'p_request': requestId});

  // (#) Expert turns a request down via the decline_service_request RPC.
  Future<void> declineRequest(String requestId) =>
      _client.rpc('decline_service_request', params: {'p_request': requestId});

  // (#) Marks a request finished via the complete_service_request RPC.
  Future<void> completeRequest(String requestId) =>
      _client.rpc('complete_service_request', params: {'p_request': requestId});

  // (#) Client leaves a star rating and comment via the submit_expert_review RPC.
  Future<void> submitReview({
    required String requestId,
    required int rating,
    required String body,
  }) =>
      _client.rpc('submit_expert_review', params: {
        'p_request': requestId,
        'p_rating': rating,
        'p_body': body,
      });

  // (#) Expert delivers the finished work as a deliverable row. RLS already
  // (#) makes sure only that engagement's expert can write it.
  Future<void> sendDeliverable({
    required String requestId,
    required String title,
    String? note,
    required List<DeliverableSection> sections,
  }) =>
      _client.from('deliverables').insert({
        'service_request_id': requestId,
        'title': title.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'sections': sections.map((s) => s.toJson()).toList(),
      });

  // (#) Creates a new service listing owned by the expert. RLS pins it to them,
  // (#) and the editor decides whether it starts as a draft or goes live.
  Future<void> createService(ExpertService service) =>
      _client.from('expert_services').insert(_servicePayload(service));

  // (#) Saves edits to the expert's own service listing, whole row at once.
  Future<void> updateService(ExpertService service) => _client
      .from('expert_services')
      .update(_servicePayload(service))
      .eq('id', service.id);

  // (#) Turns a service object into the column map used for insert and update.
  Map<String, dynamic> _servicePayload(ExpertService s) => {
        'expert_user_id': s.expertUserId,
        'status': s.status.name,
        'name': s.name.trim(),
        'description': s.description?.trim(),
        'detail_bullets': s.detailBullets,
        'category': s.category,
        'fulfillment': s.fulfillment.dbValue,
        'pricing_model': s.pricingModel.dbValue,
        'price_cents': s.priceCents,
        'duration_weeks': s.durationWeeks,
        'accepting_bookings': s.acceptingBookings,
        'response_time': s.responseTime.dbValue,
      };

  // (#) Saves an expert's editable bio fields. Rating and verification columns
  // (#) are locked off and only ever change through the RPCs.
  Future<void> updateExpertProfile(
    String id, {
    required String title,
    required int yearsCoaching,
    required String about,
    required List<String> credentials,
    required List<String> specialties,
  }) =>
      _client.from('expert_profiles').update({
        'title': title.trim(),
        'years_coaching': yearsCoaching,
        'about': about.trim(),
        'credentials': credentials,
        'specialties': specialties,
      }).eq('id', id);

  // (#) Saves the user's list of hearted experts back onto their own profile row.
  Future<void> setFollowedExperts(String userId, List<String> expertIds) =>
      _client
          .from('profiles')
          .update({'followed_expert_ids': expertIds}).eq('id', userId);
}

// (#) Riverpod provider handing out the expert gateway on the live client.
final expertGatewayProvider =
    Provider<ExpertGateway>((ref) => ExpertGateway(Supabase.instance.client));
