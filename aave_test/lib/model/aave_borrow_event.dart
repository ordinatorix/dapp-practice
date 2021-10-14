class AaveBorrowEvent {
  String userAddress;
  String reserve;
  double amount;
  double borrowRateMode;
  double borrowRate;

  AaveBorrowEvent({
    required this.userAddress,
    required this.reserve,
    required this.amount,
    required this.borrowRateMode,
    required this.borrowRate,
  });
  @override
  String toString() {
    return 'User: $userAddress;\n Reserve:$reserve;\n Amount: $amount;\n borrow rate mode: $borrowRateMode;\n borrow Rate: $borrowRate.';
  }
}
