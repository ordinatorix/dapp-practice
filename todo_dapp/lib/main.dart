import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_dapp/services/ethereum_service.dart';
// import 'package:todo_dapp/model/check_toggled.dart';
// import 'package:todo_dapp/services/web3_service.dart';

import 'package:todo_dapp/todo_screen.dart';
import 'package:todo_dapp/view_model/todo_screen_model.dart';

import 'model/task.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final EthereumService _web3 = EthereumService();
  @override
  Widget build(BuildContext context) {
    print('building main()');
    return MultiProvider(
      providers: [
        StreamProvider<List<Task>>.value(
          value: _web3.taskListStream,
          initialData: const [],
        ),
      ],
      child: ChangeNotifierProvider(
        create: (context) => TodoScreenModel(_web3),
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: const TodoScreen(),
        ),
      ),
    );
  }
}
