import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/expert_gateway.dart';
import '../core/seq_log.dart';
import '../entities/expert_service.dart';
import '../entities/validators.dart';
import 'authenticate.dart';
import 'browse_experts.dart';

// (#) This file is the expert portal's self-service editing: managing service
// (#) listings and editing the professional profile.

// (#) Creates or edits an expert's service listing. It first checks the price is
// (#) valid, then inserts (when the id is empty) or updates through the gateway,
// (#) and refreshes both the expert directory and the marketplace listings.
class PublishService {
  PublishService(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway

  // (#) Saves the given service: create if it has no id, otherwise update.
  Future<void> call(ExpertService service) async {
    if (!Validators.validPriceCents(service.priceCents)) return; // guard input
    final creating = service.id.isEmpty;
    SeqLog.msg('publish-service', 'ServiceEditorScreen', 'PublishService',
        '${creating ? 'create' : 'update'}(${service.name})');
    SeqLog.msg('publish-service', 'PublishService', 'ExpertGateway',
        creating ? 'createService' : 'updateService');
    final gateway = _ref.read(expertGatewayProvider);
    if (creating) {
      await gateway.createService(service);
    } else {
      await gateway.updateService(service);
    }
    _ref.invalidate(expertsProvider);
    _ref.invalidate(serviceListingsProvider);
  }
}

// (#) Hands the service editor screen the PublishService control.
final publishServiceProvider = Provider<PublishService>(PublishService.new);

// (#) Edits the expert's professional info. It checks the years-coaching value,
// (#) saves the title, about, credentials and specialties via the gateway, then
// (#) refreshes the directory.
class UpdateExpertProfile {
  UpdateExpertProfile(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway and user id

  // (#) Validates then saves the expert's professional profile fields.
  Future<void> call({
    required String title,
    required int yearsCoaching,
    required String about,
    required List<String> credentials,
    required List<String> specialties,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    if (!Validators.validYearsCoaching(yearsCoaching)) return; // guard input
    SeqLog.msg('manage-professional-info', 'ProfessionalInfoScreen',
        'UpdateExpertProfile', 'save()');
    SeqLog.msg('manage-professional-info', 'UpdateExpertProfile',
        'ExpertGateway', 'updateExpertProfile');
    await _ref.read(expertGatewayProvider).updateExpertProfile(
          userId,
          title: title,
          yearsCoaching: yearsCoaching,
          about: about,
          credentials: credentials,
          specialties: specialties,
        );
    _ref.invalidate(expertsProvider);
  }
}

// (#) Hands the professional-info screen the UpdateExpertProfile control.
final updateExpertProfileProvider =
    Provider<UpdateExpertProfile>(UpdateExpertProfile.new);
