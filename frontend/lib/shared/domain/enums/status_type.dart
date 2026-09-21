enum StatusType {
  pending,
  active,
  approved,
  rejected,
  completed,
  cancelled,
  inReview,
  flagged;

  String get displayName {
    switch (this) {
      case StatusType.pending:
        return 'Pending';
      case StatusType.active:
        return 'Active';
      case StatusType.approved:
        return 'Approved';
      case StatusType.rejected:
        return 'Rejected';
      case StatusType.completed:
        return 'Completed';
      case StatusType.cancelled:
        return 'Cancelled';
      case StatusType.inReview:
        return 'In Review';
      case StatusType.flagged:
        return 'Flagged';
    }
  }
}
