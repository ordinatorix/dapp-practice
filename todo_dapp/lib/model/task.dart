class Task {
  Task({
    required this.id,
    required this.date,
    required this.content,
    required this.author,
    required this.checked,
    required this.checkedDate,
  });
  int id;
  DateTime date;
  String content;
  String author;
  bool checked;
  DateTime? checkedDate;

  @override
  String toString() {
    return 'id: $id, date: $date, content: $content, author: $author, checked: $checked, checked date: $checkedDate';
  }
}
