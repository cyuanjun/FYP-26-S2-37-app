import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/expert_gateway.dart';
import '../core/seq_log.dart';
import '../entities/expert_service.dart';
import 'authenticate.dart';
import 'browse_experts.dart';

/// CONTROLs — the expert portal's self-service management (US45–US47):
/// create/edit service listings (#21.2, `PublishService` per bce §2.4) and
/// edit the professional profile (#24.1).

class PublishService {
  PublishService(this._ref);

  final Ref _ref;

  /// Create when [service].id is empty, otherwise update. Refreshes both the
  /// expert's own summary and the client-facing marketplace lists.
  Future<void> call(ExpertService service) async {
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

final publishServiceProvider = Provider<PublishService>(PublishService.new);

class UpdateExpertProfile {
  UpdateExpertProfile(this._ref);

  final Ref _ref;

  Future<void> call({
    required String title,
    required int yearsCoaching,
    required String about,
    required List<String> credentials,
    required List<String> specialties,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
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

final updateExpertProfileProvider =
    Provider<UpdateExpertProfile>(UpdateExpertProfile.new);
