class CheckStatus {
  int id;
  bool checked;
  DateTime updateDate;

  CheckStatus({
    required this.id,
    required this.checked,
    required this.updateDate,
  });
  @override
  String toString() {
    return 'id: $id, checked: $checked, checked date: $updateDate';
  }
}
