class AaveDepositEvent {
  String user;
  double amount;
  String reserve;

  AaveDepositEvent({
    required this.user,
    required this.reserve,
    required this.amount,
  });
}
