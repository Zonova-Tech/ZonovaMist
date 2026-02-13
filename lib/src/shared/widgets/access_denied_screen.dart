import 'package:flutter/material.dart';

class AccessDeniedScreen extends StatelessWidget {
  final String message;
  final String? permissionLabel;
  final bool showBackButton;

  const AccessDeniedScreen({
    super.key,
    required this.message,
    this.permissionLabel,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBackButton
          ? AppBar(
              title: const Text('Access Denied'),
            )
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (permissionLabel != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Required permission: $permissionLabel',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (showBackButton) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
