import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_dapp/model/check_toggled.dart';
import 'package:todo_dapp/task_list.dart';
import 'package:todo_dapp/view_model/todo_screen_model.dart';

import 'model/task.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late TodoScreenModel listModel;
  late Task? createdTask;
  late CheckStatus? newStatus;

  @override
  void didChangeDependencies() async {
    print('change in dependencies todo screen');
    listModel = Provider.of<TodoScreenModel>(context);
    listModel.taskList = Provider.of<List<Task>>(context);
    print('received list: ${listModel.taskList}');

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    print('building TodoScreen()');

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo List'),
        actions: [
          ElevatedButton(
            onPressed: listModel.sendFunds,
            child: const Text('send money'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Connect Wallet'),
          ),
        ],
      ),
      body: listModel.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : listModel.taskList.isEmpty
              ? const Center(
                  child: Text('no task yet'),
                )
              : TaskList(
                  taskList: listModel.taskList,
                  checkTask: listModel.checkTask,
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: listModel.createTask,
        child: const Icon(Icons.ac_unit),
      ),
    );
  }
}
