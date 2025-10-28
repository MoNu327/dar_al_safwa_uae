import 'package:majan/presentation/widgets/common_errors_widget.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommonErrorsWidget(),
              // const Icon(Icons.error_outline, color: Colors.red, size: 64),
              // const SizedBox(height: 16),
              // CustomTextWidget(
              //   title: message ?? 'Something went wrong.',
              //   textAlign: TextAlign.center,
              // ),
              // const SizedBox(height: 24),
              // if (onRetry != null)
              //   ElevatedButton(
              //     onPressed: onRetry,
              //     child: const Text('Retry'),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}
