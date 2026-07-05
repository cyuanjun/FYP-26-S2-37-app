import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/deliverable.dart';
import '../../entities/expert_category.dart';
import '../../entities/expert_profile.dart';
import '../../entities/expert_service.dart';
import '../../entities/expert_summary.dart';
import '../../entities/public_profile.dart';
import '../../entities/service_request.dart';
import '../../entities/service_request_summary.dart';

/// BOUNDARY (gateway) — the expert marketplace (#6 cluster): directory reads
/// through `public_profiles`, service requests, deliverables, and the
/// SECURITY DEFINER transition/review RPCs. Payment is simulated — prices are
/// display figures only.
class ExpertGateway {
  ExpertGateway(this._client);

  final SupabaseClient _client;

  static const _identitySelect =
      'id, first_name, last_name, username, avatar_url, level, bio';

  Future<List<ExpertCategory>> listCategories() async {
    final rows = await _client
        .from('expert_categories')
        .select()
        .eq('is_active', true)
        .order('label', ascending: true);
    return rows.map(ExpertCategory.fromJson).toList();
  }

  /// Every expert with identity + their services (RLS trims embedded services
  /// to `live` for everyone but the owning expert). Top-rated first.
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

  /// All live services + who offers them. Cheapest first.
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

  static const _requestSelect = '*, '
      'service:expert_services!service_requests_expert_service_id_fkey(*), '
      'deliverables(*), reviews:expert_reviews(id)';

  /// The client's engagements, newest first (MY PURCHASES + #6.2 footer).
  Future<List<ServiceRequestSummary>> listMyRequests(String userId) async {
    final rows = await _client
        .from('service_requests')
        .select('$_requestSelect, other:public_profiles!'
            'service_requests_expert_user_id_fkey($_identitySelect)')
        .eq('user_id', userId)
        .order('requested_at', ascending: false);
    return rows.map(_summaryFromRow).toList();
  }

  /// The expert's inbox, newest first.
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

  ServiceRequestSummary _summaryFromRow(Map<String, dynamic> r) =>
      ServiceRequestSummary(
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
        reviewed: ((r['reviews'] as List?) ?? const []).isNotEmpty,
      );

  /// Insert with the price snapshotted from the service (simulated payment).
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

  // Status transitions + review go through the SECURITY DEFINER RPCs — direct
  // table writes are revoked (20260707090000).
  Future<void> acceptRequest(String requestId) =>
      _client.rpc('accept_service_request', params: {'p_request': requestId});

  Future<void> declineRequest(String requestId) =>
      _client.rpc('decline_service_request', params: {'p_request': requestId});

  Future<void> completeRequest(String requestId) =>
      _client.rpc('complete_service_request', params: {'p_request': requestId});

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

  /// Plain insert — the deliverables RLS policy already restricts writes to
  /// the engagement's expert.
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

  /// Follow-heart bookmark: read-modify-write of the caller's own profile row
  /// (the privileged-column guard only watches role/status).
  Future<void> setFollowedExperts(String userId, List<String> expertIds) =>
      _client
          .from('profiles')
          .update({'followed_expert_ids': expertIds}).eq('id', userId);
}

final expertGatewayProvider =
    Provider<ExpertGateway>((ref) => ExpertGateway(Supabase.instance.client));
