// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:todo_dapp/model/check_toggled.dart';

import 'package:todo_dapp/model/task.dart';
import 'package:todo_dapp/services/ethereum_service.dart';
// import 'package:todo_dapp/services/web3_service.dart';

class TodoScreenModel extends ChangeNotifier {
  List<Task?> taskList = [];
  late int _taskNumber;
  // final Web3Service _web3Service;
  final EthereumService _web3Service;
  bool isLoading = true;

  TodoScreenModel(this._web3Service) {
    _init();
  }

  /// set state to idle
  void _setIdle() {
    print('idle state');
    isLoading = false;
    notifyListeners();
  }

  /// set state to busy
  void _setBusy() {
    print('Busy state');
    isLoading = true;
    notifyListeners();
  }

  /// init todo screen model
  void _init() async {
    print('init todoScreenModel()');
    print('initial taskList: $taskList');

    _setIdle();
  }

  void sendFunds() {
    print('sending funds');
    _web3Service.sendFunds();
  }

  /// toggle check status
  void checkTask({required int id}) async {
    print('toggled check');
    await _web3Service.toggleCheck(id: id);
  }

  /// create new task
  Future<void> createTask() async {
    print('create task');
    _setBusy();
    _taskNumber = taskList.isNotEmpty ? taskList.last!.id + 1 : 0;
    await _web3Service.createTask(
        content: 'new task$_taskNumber', author: 'me');

    isLoading = false;
    print('is loading: $isLoading');
  }
}
