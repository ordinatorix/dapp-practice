// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_web3/ethereum.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:todo_dapp/model/check_toggled.dart';
import 'package:todo_dapp/model/task.dart';

class EthereumService {
  /// constructor
  EthereumService() {
    _initService();
  }
  Web3Provider? _web3Provider;
  late Signer currentSigner;
  late String _abiCode;
  late Contract todo;
  late bool _isMetamask;
  late bool _isLocal;
  List<Task> taskList = [];
  JsonRpcProvider? rpcProvider;
  String currentAddress = '';
  int currentChain = -1;

  bool wcConnected = false;

  final String _contractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
  final StreamController<List<Task>> _taskListController =
      StreamController<List<Task>>.broadcast();
  Stream<List<Task>> get taskListStream => _taskListController.stream;

  /// fetch contract abi.
  _getAbi() async {
    String abiStringFile = await rootBundle.loadString("lib/abi/todo.abi.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
  }

  ///init ethereum service.
  ///
  void _initService() async {
    print('init eth service');
    await _getAbi();
    if (Ethereum.isSupported) {
      print('ethereum is supported');
      await _connectProvider();
      contractSetup();
      ethereum!.onAccountsChanged((accs) {
        _clear();
      });

      ethereum!.onChainChanged((chain) {
        _clear();
      });
    } else {
      print('using default rpc provider');
      await _initTestProvider();
    }
    fetchAllTask();
    _subscribeToTaskCreatedEvent();
    _subscribeToCheckToggledEvent();
  }

  /// Setup todo contract.
  /// Use [_abiCode] from the contract.
  /// Provide [Signer]that will use the contract.
  contractSetup() {
    print('setup contract');
    if (_isMetamask) {
      todo = Contract(
        _contractAddress,
        Interface(_abiCode),
        currentSigner,
      );
    } else if (_isLocal) {
      todo = Contract(_contractAddress, Interface(_abiCode), currentSigner);
    }
  }

  /// Initialize test provider.
  /// This allow for read-only interaction with the blockchain.
  _initTestProvider() async {
    rpcProvider = JsonRpcProvider();
    final accts = await rpcProvider!.listAccounts();
    print('provider is:  $rpcProvider');
    print('network is: ${await rpcProvider!.getNetwork()}');

    if (accts.isNotEmpty) {
      print('accounts: $accts');
      currentAddress = accts.first;
    }
    _isLocal = true;
  }

  /// reset
  _clear() {
    currentAddress = '';
    currentChain = -1;
    wcConnected = false;
  }

  /// Dispose this service, and cancel any subscrition
  ///
  void dispose() async {
    todo.off('taskCreated');
    todo.off('checkToggled');
    _clear();
  }

  /// Connect to [provider] via wallet (e.g. Metamask)
  _connectProvider() async {
    print('connecting provider');
    if (Ethereum.isSupported) {
      try {
        final accs = await ethereum!.requestAccount();
        if (accs.isNotEmpty) {
          print('accounts: $accs');
          currentAddress = accs.first;
          currentChain = await ethereum!.getChainId();
        }
        _web3Provider = provider;

        currentSigner = _web3Provider!.getSigner();
        _isMetamask = true;
      } on EthereumUserRejected {
        print('user rejected connection');
      } catch (e) {
        print('error is: $e');
      }

      await getLastestBlock();
    }
  }

  /// Get latest block.
  getLastestBlock() async {
    print(await _web3Provider!.getLastestBlock());
    print(await _web3Provider!.getLastestBlockWithTransaction());
  }

  /// Convert [taskCreated] event to [Task].
  ///
  List<Task> _taskListFromEvent(List<dynamic> event) {
    print('converting fetched task to Task');
    return event
        .map(
          (e) => Task(
            id: int.parse(e[0].toString()),
            date: DateTime.fromMillisecondsSinceEpoch(
                int.parse(e[1].toString()) * 1000),
            content: e[2] as String,
            author: e[3] as String,
            checked: e[4] as bool,
            checkedDate: DateTime.fromMillisecondsSinceEpoch(
                int.parse(e[5].toString()) * 1000),
          ),
        )
        .toList();
  }

  /// Fetch all [Task].
  ///
  void fetchAllTask() async {
    try {
      final fetchedTaskList = await todo.call<List>('fetchAllTasks');

      print('raw fetch : $fetchedTaskList');

      taskList = _taskListFromEvent(fetchedTaskList);
      print('task list: $taskList');

      _taskListController.add(taskList);
    } catch (e) {
      print('error is: $e');
    }
  }

  /// Create a new [Task].
  ///
  createTask({required String content, required String author}) async {
    try {
      final createTaskTx = await todo.send('createTask', [content, author]);
      final recu = await createTaskTx.wait();
      print('recu : $recu');
    } on EthereumUserRejected {
      print('user rejected tx');
    } catch (e) {
      print('error is: $e');
    }
  }

  /// Toggle check on existing [Task].
  ///
  toggleCheck({required int id}) async {
    try {
      final toggleTx = await todo.send('toggleCheck', [BigInt.from(id)]);
      final txReceipt = await toggleTx.wait();
      print('toggleTx receipt: $txReceipt');
    } on EthereumUserRejected {
      print('user rejected tx');
    } catch (e) {
      print('error is: $e');
    }
  }

  /// Subscribe to [taskCreated] event.
  void _subscribeToTaskCreatedEvent() {
    print('subscribe To TaskCreated Event');

    todo.on('taskCreated', (id, date, content, author, checked, event) async {
      final receivedList = [id, date, content, author, checked];
      final newTask = _taskListFromEvent(receivedList);
      // final Task newTask = Task(
      //   id: int.parse(id.toString()),
      //   date: DateTime.fromMillisecondsSinceEpoch(
      //       int.parse(date.toString()) * 1000),
      //   content: content as String,
      //   author: author as String,
      //   checked: checked as bool,
      //   checkedDate: null,
      // );

      bool didUpdate = await updateTaskList(createdTask: newTask.first);
      if (didUpdate) {
        print('adding to controller');
        _taskListController.add(List.from(taskList));
      }
    });
  }

  /// Get event in the last 50 blocks.
  querychain() async {
    final filter = todo.getFilter('taskCreated');
    await todo.queryFilter(filter, -50);
  }

  /// Subscribe to [checkToggled] event.
  void _subscribeToCheckToggledEvent() {
    print('subscribe to check toggle event');

    try {
      todo.on('checkToggled', (id, checked, dateChecked, event) async {
        final CheckStatus _checkStatus = CheckStatus(
          id: int.parse(id.toString()),
          checked: checked as bool,
          updateDate: DateTime.fromMillisecondsSinceEpoch(
              int.parse(dateChecked.toString()) * 1000),
        );
        print('old List: $taskList');
        bool didUpdate = await updateTaskList(newStatus: _checkStatus);
        print('new List: $taskList');
        if (didUpdate) {
          print('adding to controller');
          _taskListController.add(List.from(taskList));
        }
      });
    } catch (e) {
      print('error is: $e');
    }
  }

  /// get eth balance of specified addresses.
  ///
  Future<void> getBalances() async {
    print('getting owner balance');
    var balance = await currentSigner.getBalance();
    var balance1 = await _web3Provider!
        .getBalance('0x90f79bf6eb2c4f870365e785982e1f101e93b906');
    var balance2 = await _web3Provider!
        .getBalance('0xc11F45A5f077C1552988b2DEEB7FF43686e58AFf');
    // print('owner balance is: $balance;');
    print('owner balance is: $balance; 1: $balance1; 2: $balance2');
  }

  /// Send funds to address
  ///
  void sendFunds() async {
    print('sending funds. to metamask addr?: $_isMetamask');
    try {
      await getBalances();
      final TransactionRequest request = TransactionRequest(
        to: '0xc11F45A5f077C1552988b2DEEB7FF43686e58AFf',
        value: EthUtils.parseEther('1.0').toBigInt,
      );
      final fundTx = await currentSigner.sendTransaction(request);
      final fundTxReceipt = await fundTx.wait();
      print('receipt logs: ${fundTxReceipt.logs}');

      await getBalances();
      print('sent');
    } on EthereumUserRejected {
      print('user rejected tx');
    } catch (e) {
      print('error is: $e');
    }
  }

  /// Update [taskList].

  Future<bool> updateTaskList({Task? createdTask, CheckStatus? newStatus}) {
    print(
        'updating task list | createdTask: $createdTask, newStatus: $newStatus');
    print('current task list: $taskList');

    final bool containsCreatedTask = taskList.any((element) =>
        ((element.id == createdTask?.id) || (element.id == newStatus?.id)));

    if (createdTask == null && newStatus == null) {
      print(
          'no new task or contains created task: $containsCreatedTask | returning');
      return Future.value(false);
    } else if (containsCreatedTask) {
      print('containsCreatedTask');
      if (newStatus != null) {
        if (taskList[newStatus.id].checked != newStatus.checked) {
          var yo = Task(
              id: newStatus.id,
              date: taskList[newStatus.id].date,
              content: taskList[newStatus.id].content,
              author: taskList[newStatus.id].author,
              checked: newStatus.checked,
              checkedDate: newStatus.updateDate);
          taskList.replaceRange(
              taskList[newStatus.id].id, taskList[newStatus.id].id + 1, [yo]);

          print('updating check:$taskList');
          return Future.value(true);
        }
      }
      print('nothing to add');
      return Future.value(false);
    } else {
      print('contains created task?: $containsCreatedTask ');

      taskList.add(createdTask!);
      print('new task list: $taskList');
      return Future.value(true);
    }
  }
}
