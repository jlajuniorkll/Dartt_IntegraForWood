import 'package:flutter/material.dart';

import 'progress_step.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final List<ProgressStep>? steps;

  const LoadingWidget({super.key, this.message, this.steps});

  @override
  Widget build(BuildContext context) {
    final stepsList = steps ?? [];
    final hasSteps = stepsList.isNotEmpty;

    return Center(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (hasSteps) ...[
              const SizedBox(height: 24),
              ...stepsList.map(
                (step) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStepIcon(step.status),
                      const SizedBox(width: 12),
                      Text(
                        step.label,
                        style: TextStyle(
                          color: step.status == StepStatus.current
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          fontWeight: step.status == StepStatus.current
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(message!),
            ],
          ],
        ),
    );
  }

  Widget _buildStepIcon(StepStatus status) {
    switch (status) {
      case StepStatus.done:
        return Icon(
          Icons.check_circle,
          color: Colors.green.shade600,
          size: 24,
        );
      case StepStatus.current:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
      case StepStatus.pending:
        return Icon(
          Icons.radio_button_unchecked,
          color: Colors.grey.shade400,
          size: 24,
        );
    }
  }
}
