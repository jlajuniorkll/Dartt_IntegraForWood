import 'package:flutter/material.dart';

import 'progress_step.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final List<ProgressStep>? steps;
  /// Quando false, só a lista de passos (útil após concluir o fluxo no diálogo).
  final bool showSpinner;

  const LoadingWidget({
    super.key,
    this.message,
    this.steps,
    this.showSpinner = true,
  });

  @override
  Widget build(BuildContext context) {
    final stepsList = steps ?? [];
    final hasSteps = stepsList.isNotEmpty;

    return Center(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner) const CircularProgressIndicator(),
            if (showSpinner && hasSteps) const SizedBox(height: 24),
            if (!showSpinner && hasSteps) const SizedBox(height: 4),
            if (hasSteps) ...[
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
            ],
            if (!hasSteps && message != null && message!.isNotEmpty) ...[
              if (showSpinner) const SizedBox(height: 16),
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
