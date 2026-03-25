import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';

class ContentArea extends StatelessWidget {
  const ContentArea({
    super.key,
    required this.runtime,
    required this.data,
    this.widgetName,
    required this.isLoading,
    this.error,
    this.onEvent,
    this.onRetry,
  });

  final Runtime runtime;
  final DynamicContent data;
  final FullyQualifiedWidgetName? widgetName;
  final bool isLoading;
  final String? error;
  final void Function(String name, DynamicMap arguments)? onEvent;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE53935)),
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF49515A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    if (widgetName == null) {
      return const Center(
        child: Text(
          'Select a page from the sidebar',
          style: TextStyle(fontSize: 14, color: Color(0xFF788391)),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: RemoteWidget(
            runtime: runtime,
            data: data,
            widget: widgetName!,
            onEvent: (String name, DynamicMap arguments) {
              onEvent?.call(name, arguments);
            },
          ),
        ),
      ),
    );
  }
}
