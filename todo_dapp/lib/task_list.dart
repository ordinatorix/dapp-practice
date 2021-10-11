import 'package:flutter/material.dart';

import 'model/task.dart';

class TaskList extends StatefulWidget {
  final List<Task?> taskList;
  final Function checkTask;
  const TaskList({Key? key, required this.taskList, required this.checkTask})
      : super(key: key);

  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  @override
  Widget build(BuildContext context) {
    print('building taskList()');
    return ListView.builder(
        itemCount: widget.taskList.length,
        itemBuilder: (context, id) {
          return CheckboxListTile(
              title: Text(widget.taskList[id]!.content),
              value: widget.taskList[id]!.checked,
              onChanged: (_) {
                widget.checkTask(id: id);
              });
        });
  }
}
