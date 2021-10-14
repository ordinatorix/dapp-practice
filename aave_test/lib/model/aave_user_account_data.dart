class AaveUserAccountData {
  double totalCollateralEth;
  double totalDebtETH;
  double availableBorrowsETH;
  double currentLiquidationThreshold;
  double ltv;
  double healthFactor;
  AaveUserAccountData({
    required this.totalCollateralEth,
    required this.totalDebtETH,
    required this.availableBorrowsETH,
    required this.currentLiquidationThreshold,
    required this.ltv,
    required this.healthFactor,
  });
  @override
  String toString() {
    return 'totalCollateralEth: $totalCollateralEth;\n totalDebtETH: $totalDebtETH;\n availableBorrowsETH: $availableBorrowsETH;\n currentLiquidationThreshold: $currentLiquidationThreshold;\n max ltv: $ltv;\n healthFactor: $healthFactor;  ';
  }
}
