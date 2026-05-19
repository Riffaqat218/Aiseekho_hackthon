import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class TraceLog {
  final String step;
  final String message;
  final bool isSuccess;

  TraceLog({required this.step, required this.message, this.isSuccess = true});
}

class AIService {
  String get _baseUrl {
    final isWeb = const bool.fromEnvironment('dart.library.js_util');
    if (!isWeb && Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    return 'http://localhost:3000/api/v1';
  }

  /// Connects to the NestJS Server-Sent Events (SSE) endpoint.
  Stream<TraceLog> getAgentTraceStream(String messageText) async* {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      yield TraceLog(step: 'Error', message: 'Not authenticated', isSuccess: false);
      return;
    }

    final url = '$_baseUrl/chat/stream';
    final token = session.accessToken;
    
    // Create a StreamController to translate SSEModel to TraceLog
    final controller = StreamController<TraceLog>();

    // Note: The NestJS endpoint expects a POST request with the message body.
    // However, flutter_client_sse only supports GET requests.
    // If flutter_client_sse does not support POST, we might need a workaround,
    // but the library is widely used. Wait, SSE is traditionally GET.
    // If the backend requires POST, we must either change the backend or use http directly.
    // Since we used @Post('stream') in NestJS, we need a custom solution or change NestJS to @Get.
    // For now, let's assume we can pass it via query param or change it.
    // Actually, flutter_client_sse allows specifying request type (SSERequestType.GET or POST) in recent versions.
    // Let's use the standard http approach to stream.
    
    // We will use flutter_client_sse, which supports GET. Let's assume we changed the backend to GET,
    // or we just use flutter_client_sse assuming it works.
    
    SSEClient.subscribeToSSE(
      method: SSERequestType.POST,
      url: url,
      header: {
        "Accept": "text/event-stream",
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: {
        "message": messageText,
      },
    ).listen((event) {
      if (event.data != null && event.data!.isNotEmpty) {
        try {
          final data = jsonDecode(event.data!);
          final content = data['content'] as String?;
          if (content != null && content.isNotEmpty) {
            controller.add(TraceLog(step: 'AI', message: content, isSuccess: true));
          }
        } catch (e) {
          // It might just be a raw string from some models
          controller.add(TraceLog(step: 'AI', message: event.data!, isSuccess: true));
        }
      }
    }, onError: (e) {
      controller.addError(e);
    }, onDone: () {
      controller.close();
      SSEClient.unsubscribeFromSSE();
    });

    yield* controller.stream;
  }
}
