import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_service.dart';
import '../../core/constants.dart';

final traceStreamProvider = StreamProvider<TraceLog>((ref) {
  final aiService = ref.read(aiServiceProvider);
  return aiService.getAgentTraceStream();
});

class TracePanel extends ConsumerStatefulWidget {
  const TracePanel({super.key});

  @override
  ConsumerState<TracePanel> createState() => _TracePanelState();
}

class _TracePanelState extends ConsumerState<TracePanel> {
  final List<TraceLog> _logs = [];

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<TraceLog>>(traceStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        setState(() {
          _logs.add(next.value!);
        });
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.borderRadiusLarge),
          topRight: Radius.circular(AppConstants.borderRadiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Antigravity Agent Trace',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  color: AppConstants.secondaryColor,
                  strokeWidth: 2,
                ),
              )
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${log.step}]',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.message,
                          style: TextStyle(
                            color: log.isSuccess ? AppConstants.secondaryColor : AppConstants.warningColor,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
