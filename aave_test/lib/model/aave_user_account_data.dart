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
    return 'totalCollateralEth: $totalCollateralEth, totalDebtETH: $totalDebtETH, availableBorrowsETH: $availableBorrowsETH; currentLiquidationThreshold: $currentLiquidationThreshold; max ltv: $ltv; healthFactor: $healthFactor;  ';
  }
}
