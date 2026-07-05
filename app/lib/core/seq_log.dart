import 'package:flutter/foundation.dart';

/// Runtime traceability logger (bce-design §6). Each Control emits
/// `SEQ <useCase> <from> -> <to> : <message>` at every Boundary→Control→Entity/gateway
/// hop, so real run sequences can be regenerated into Mermaid sequence diagrams.
/// Debug-only — stripped from release builds.
abstract final class SeqLog {
  static void msg(String useCase, String from, String to, String message) {
    if (kDebugMode) {
      debugPrint('SEQ $useCase $from -> $to : $message');
    }
  }
}
