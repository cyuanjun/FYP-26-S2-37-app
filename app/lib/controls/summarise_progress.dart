import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/ai_gateway.dart';
import '../core/seq_log.dart';

/// CONTROL — SummariseProgress (AI). Reads the AiGateway, which proxies the
/// summarise-progress Edge Function. AI scope per build-plan §5.
class SummariseProgress {
  SummariseProgress(this._ref);

  final Ref _ref;

  Future<ProgressSummary> call() {
    SeqLog.msg('summarise-progress', 'HistoryScreen', 'SummariseProgress', 'summarise()');
    SeqLog.msg('summarise-progress', 'SummariseProgress', 'AiGateway', 'summariseProgress()');
    return _ref.read(aiGatewayProvider).summariseProgress();
  }
}

final summariseProgressProvider = Provider<SummariseProgress>(SummariseProgress.new);

/// Generated on demand when the AI-summary sheet opens; auto-disposes on close so
/// each open re-runs against fresh data.
final aiSummaryProvider = FutureProvider.autoDispose<ProgressSummary>(
  (ref) => ref.read(summariseProgressProvider).call(),
);
