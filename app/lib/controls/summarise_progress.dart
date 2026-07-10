import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/ai_gateway.dart';
import '../core/seq_log.dart';

// (#) One of the two AI use cases in scope: SummariseProgress. It asks the AI gateway
// (#) for a plain-English recap of the user's recent training; the gateway proxies the
// (#) summarise-progress Edge Function so the OpenAI key never ships in the app.
class SummariseProgress {
  SummariseProgress(this._ref);

  final Ref _ref;

  // (#) Calls the AI gateway and hands the resulting summary back to the sheet.
  Future<ProgressSummary> call() {
    SeqLog.msg('summarise-progress', 'HistoryScreen', 'SummariseProgress', 'summarise()');
    SeqLog.msg('summarise-progress', 'SummariseProgress', 'AiGateway', 'summariseProgress()');
    return _ref.read(aiGatewayProvider).summariseProgress();
  }
}

// (#) Provider the history screen uses to reach the control.
final summariseProgressProvider = Provider<SummariseProgress>(SummariseProgress.new);

// (#) Runs the summary when the AI sheet opens. autoDispose means it clears on close,
// (#) so opening the sheet again re-summarises against the latest data.
final aiSummaryProvider = FutureProvider.autoDispose<ProgressSummary>(
  (ref) => ref.read(summariseProgressProvider).call(),
);
