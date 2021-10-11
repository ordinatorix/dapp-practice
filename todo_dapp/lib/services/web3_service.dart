// // ignore_for_file: avoid_print

/// The web3dart package has not yet fully implemente the metamask support. 


// import 'dart:async';
// // import 'dart:convert';
// import 'dart:html';
// // import 'dart:typed_data';

// import 'package:http/http.dart';
// import 'package:todo_dapp/model/check_toggled.dart';
// import 'package:todo_dapp/model/task.dart';
// import 'package:web3dart/web3dart.dart';
// import 'package:web3dart/browser.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// import 'package:todo_dapp/abi/todo.g.dart';

// class Web3Service {
//   Web3Service() {
//     _initWeb3Client();
//   }
//   final StreamController<List<Task>> _taskListController =
//       StreamController<List<Task>>.broadcast();
//   Stream<List<Task>> get taskListStream => _taskListController.stream;

//   late StreamSubscription<checkToggled> checkToggledSubscription;
//   late StreamSubscription<taskCreated> taskCreatedSubscription;
//   List<Task> taskList = [];
//   late Web3Client _web3Client;
//   late int _chainId;
//   final Client _httpClient = Client();
//   static const String rpcUrl = 'http://localhost:8545';
//   final Uri _wsUri = Uri.parse('ws://localhost:8545/');

//   final EthereumAddress _contractAddress =
//       EthereumAddress.fromHex('0x5FbDB2315678afecb367f032d93F642f64180aa3');
//   static const String _privateKey =
//       '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

//   late EthereumAddress ownerAddress;
//   late Credentials _localCredentials;
//   late CredentialsWithKnownAddress _metamaskCredentials;
//   late Ethereum? eth;
//   late bool _isMetamask;
//   bool _isListenning = false;

//   late Todo _contract;
//   bool get isReady => _isListenning;

//   /// initialize web3
//   ///
//   void _initWeb3Client() async {
//     print('init web3 client');
//     if (_metamaskExist()) {
//       print('metamask is available');

//       await _getCredentials();
//       await _requestMetamaskConnection();
//     } else {
//       print('metamask is unavailable');
//       await _connectViaLocalhost();

//       await _getCredentials();
//     }

//     _contract = Todo(
//       address: _contractAddress,
//       client: _web3Client,
//       chainId: _chainId,
//     );
//     print('contract is: $_contract');

    
    
//     await fetchAllTask();
//     _subscribeToTaskCreatedEvent();
//     _subscribeToCheckToggledEvent();
//   }

//   /// Check t see if metamask is available to client.
//   bool _metamaskExist() {
//     eth = window.ethereum;

//     if (eth == null) {
//       print('MetaMask is not available');
//       return _isMetamask = false;
//     }
//     _isMetamask = eth!.isMetaMask;
//     return _isMetamask;
//   }

//   /// Dispose this service, and cancel any subscrition
//   ///
//   void dispose() async {
//     await taskCreatedSubscription.cancel();
//     await checkToggledSubscription.cancel();
//   }

//   /// Request metaMask access.
//   Future<void> _requestMetamaskConnection() async {
//     try {
//       _web3Client = Web3Client.custom(eth!.asRpcService());
//       _metamaskCredentials = await eth!.requestAccount();
     
//       _chainId = await _web3Client.getNetworkId();
//       print('metamask chainID: $_chainId');
//       print('Using ${_metamaskCredentials.address}');
//       _isListenning = await _web3Client.isListeningForNetwork();
//       print(
//           'metamaskClient is listening: $_isListenning');
//     } catch (e) {
//       print('error from requesting account: $e');
//     }
//   }

//   /// Connect to blockchain using address in localhost
//   Future<void> _connectViaLocalhost() async {
//     print('connecting using local host');
//     _web3Client = Web3Client(rpcUrl, _httpClient, socketConnector: () {
//       return WebSocketChannel.connect(_wsUri).cast<String>();
//     });
//     _chainId = await _web3Client.getNetworkId();
//     print('local host chainID: $_chainId');
//     _isListenning = await _web3Client.isListeningForNetwork();
//      print(
//           'localClient is listening: $_isListenning');
//   }

//   /// convert taskcreatedd event to Task
//   ///
//   List<Task> _taskListFromEvent(List<dynamic> event) {
//     print('converting fetched task to Task');
//     return event
//         .map(
//           (e) => Task(
//             id: int.parse(e[0].toString()),
//             date: DateTime.fromMillisecondsSinceEpoch(e[1].toInt() * 10 ^ 3),
//             content: e[2] as String,
//             author: e[3] as String,
//             checked: e[4] as bool,
//             checkedDate:
//                 DateTime.fromMillisecondsSinceEpoch(e[5].toInt() * 10 ^ 3),
//           ),
//         )
//         .toList();
//   }

//   /// Get owner credentials
//   ///
//   Future<void> _getCredentials() async {
//     print('getting credentials');
//     _localCredentials = EthPrivateKey.fromHex(_privateKey);
//     ownerAddress = await _localCredentials.extractAddress();
//   }

//   /// Create a task.
//   /// This send a transaction to execute the contracts to create task function.
//   ///
//   Future<void> createTask(
//       {required String content, required String author}) async {
//     print('creating task');

//     final transationHash = await _contract.createTask(content, author,
//         credentials: _isMetamask ? _metamaskCredentials : _localCredentials);
//     print('created task transaction hash: $transationHash');
//   }

//   /// Fetch all tasks
//   /// This send a call to read the contracts to fetch all task function.
//   Future<List<Task?>> fetchAllTask() async {
//     print('fetching tasks');
//     try {
//       final fetchedTaskList = await _contract.fetchAllTasks(atBlock:const BlockNum.current());

//       taskList = _taskListFromEvent(fetchedTaskList);

//       print('finalTaskList: $taskList ');
//       _taskListController.add(List.from(taskList));
//       return taskList;
//     } catch (e) {
//       print('error is: $e');
//       return [];
//     }
//   }

//   /// Toggle check mark on todo task
//   /// This send a transaction to execute the contracts toggle checked function.
//   ///
//   Future<void> toggleCheck({required int id}) async {
//     print('toggling check');
//     final checkResponse = await _contract.toggleCheck(BigInt.from(id),
//         credentials: _localCredentials);

//     print('check Response: $checkResponse');
//   }

//   /// Subscribe to task created event
//   ///
//   void _subscribeToTaskCreatedEvent() {
//     print('subscribe To TaskCreated Event');

//     taskCreatedSubscription =
//         _contract.taskCreatedEvents().listen((event) async {
//       print('new task creation event id: ${event.id}');

//       final Task newTask = Task(
//         id: event.id.toInt(),
//         date: DateTime.fromMillisecondsSinceEpoch(event.date.toInt() * 10 ^ 3),
//         content: event.content,
//         author: event.author,
//         checked: event.checked,
//         checkedDate: null,
//       );

//       bool didUpdate = await updateTaskList(createdTask: newTask);
//       if (didUpdate) {
//         print('adding to controller');
//         _taskListController.add(List.from(taskList));
//       }
//     });
//   }

//   /// Subscribe to check toggle event
//   ///
//   void _subscribeToCheckToggledEvent() {
//     print('subscribe to check toggle event');

//     checkToggledSubscription =
//         _contract.checkToggledEvents().listen((event) async {
//       print('new toggle event: ${event.id}');
//       final CheckStatus _checkStatus = CheckStatus(
//         id: event.id.toInt(),
//         checked: event.checked,
//         updateDate: DateTime.fromMillisecondsSinceEpoch(
//             event.dateChecked.toInt() * 10 ^ 3),
//       );
//       print('old List: $taskList');
//       bool didUpdate = await updateTaskList(newStatus: _checkStatus);
//       print('new List: $taskList');
//       if (didUpdate) {
//         print('adding to controller');
//         _taskListController.add(List.from(taskList));
//       }
//     });
//   }

//   void sendFunds() async {
//     print('sending funds. to metamask addr?: $_isMetamask');
//     await getOwnerBalance();


//     await _web3Client.sendTransaction(
//       // _metamaskCredentials,
//       _localCredentials,
//       Transaction(
//         to: _isMetamask
//             ? _metamaskCredentials.address
//             : EthereumAddress.fromHex(
//                 '0x90f79bf6eb2c4f870365e785982e1f101e93b906'),
//         value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 10),
//       ),
//       chainId: _chainId,
//     );
//     await getOwnerBalance();
//     print('sent');
//   }

//   /// get eth balance of cotract owner.
//   ///
//   Future<void> getOwnerBalance() async {
//     print('getting owner balance');
//     var balance = await _web3Client.getBalance(ownerAddress);
//     var balance1 = await _web3Client.getBalance(
//         EthereumAddress.fromHex('0x90f79bf6eb2c4f870365e785982e1f101e93b906'));
//     var balance2 = await _web3Client.getBalance(
//         EthereumAddress.fromHex('0xc11F45A5f077C1552988b2DEEB7FF43686e58AFf'));
//     print(
//         'owner balance is: ${balance.getInEther}; 1: ${balance1.getInEther}; 2: ${balance2.getInEther}');
//   }

//   Future<bool> updateTaskList({Task? createdTask, CheckStatus? newStatus}) {
//     print(
//         'updating task list | createdTask: $createdTask, newStatus: $newStatus');
//     print('current task list: $taskList');

//     final bool containsCreatedTask = taskList.any((element) =>
//         ((element.id == createdTask?.id) || (element.id == newStatus?.id)));

//     if (createdTask == null && newStatus == null) {
//       print(
//           'no new task or contains created task: $containsCreatedTask | returning');
//       return Future.value(false);
//     } else if (containsCreatedTask) {
//       print('containsCreatedTask');
//       if (newStatus != null) {
//         if (taskList[newStatus.id].checked != newStatus.checked) {
//           var yo = Task(
//               id: newStatus.id,
//               date: taskList[newStatus.id].date,
//               content: taskList[newStatus.id].content,
//               author: taskList[newStatus.id].author,
//               checked: newStatus.checked,
//               checkedDate: newStatus.updateDate);
//           taskList.replaceRange(
//               taskList[newStatus.id].id, taskList[newStatus.id].id + 1, [yo]);

//           print('updating check:$taskList');
//           return Future.value(true);
//         }
//       }
//       print('nothing to add');
//       return Future.value(false);
//     } else {
//       print('contains created task?: $containsCreatedTask ');

//       taskList.add(createdTask!);
//       print('new task list: $taskList');
//       return Future.value(true);
//     }
//   }
// }
