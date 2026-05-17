import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class TraceLog {
  final String step;
  final String message;
  final bool isSuccess;

  TraceLog({required this.step, required this.message, this.isSuccess = true});
}

class AIService {
  /// Simulates an SSE connection receiving Antigravity trace logs from the backend.
  Stream<TraceLog> getAgentTraceStream() async* {
    final logs = [
      TraceLog(step: '1/4', message: 'Analyzing extracted document profile...', isSuccess: true),
      TraceLog(step: '2/4', message: 'Querying vector DB for Pakistan local scholarships...', isSuccess: true),
      TraceLog(step: '3/4', message: 'Evaluating gap requirements: Missing Domicile.', isSuccess: false),
      TraceLog(step: '4/4', message: 'Drafting professor recommendation email...', isSuccess: true),
    ];

    for (final log in logs) {
      await Future.delayed(const Duration(seconds: 2));
      yield log;
    }
  }
}
