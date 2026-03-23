/// Status of a progress step in the loading flow.
enum StepStatus {
  pending,
  current,
  done,
}

/// Represents a single step in the loading progress.
class ProgressStep {
  final String label;
  final StepStatus status;

  const ProgressStep({
    required this.label,
    this.status = StepStatus.pending,
  });

  ProgressStep copyWith({String? label, StepStatus? status}) {
    return ProgressStep(
      label: label ?? this.label,
      status: status ?? this.status,
    );
  }
}
