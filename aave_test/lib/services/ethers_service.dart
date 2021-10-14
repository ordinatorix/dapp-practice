// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:aave_test/model/aave_borrow_event.dart';
import 'package:aave_test/model/aave_user_account_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web3/flutter_web3.dart';

class EthereumService {
  /// constructor
  EthereumService() {
    _initEthService();
  }

  late Web3Provider _web3Provider;
  late String _currentSignerAddress;
  late String _currentChain;
  late Signer _currentSigner;
  late bool _isMetaMask;

  late String _lendingPoolAbi;
  late String _lendingPoolProxyAbi;
  final String _lendingPoolProxyAddress =
      '0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe';

  late Interface _proxyIface;
  late Interface _lendingPoolIface;

  late Contract _proxyContract;

  /// initialize service.
  ///
  void _initEthService() async {
    await _getAbi();
    await connectProvider();
    await contractSetup();
    await getBalance();
    await getLatestBlock();
    await queryEventBlockWithFilter(fromBlock: 27669332, toBlock: 27669334);
    await getUserAccountData(address: _currentSignerAddress);
    _listenForBorrowEvents();
  }

  /// get abi code from file.
  ///
  Future<void> _getAbi() async {
    print('getting ABI');
    // use rootbundle to get proxy abi file
    final String _proxyAbiFile =
        await rootBundle.loadString('lib/abi/aave_proxy.abi.json');
    final _proxyJsonAbi = jsonDecode(_proxyAbiFile);
    _lendingPoolProxyAbi = jsonEncode(_proxyJsonAbi);
    _proxyIface = Interface(_lendingPoolProxyAbi);

// use root bundle to get aave lending abi file
    final String _aaveLendingAbiFile =
        await rootBundle.loadString('lib/abi/aave_lending_pool.abi.json');
    final _aaveLendingJsonAbi = jsonDecode(_aaveLendingAbiFile);
    _lendingPoolAbi = jsonEncode(_aaveLendingJsonAbi);
    _lendingPoolIface = Interface(_lendingPoolAbi);
  }

  /// Setup Contract
  ///
  Future<void> contractSetup() async {
    // setup proxy contract
    print('Setting up contract');
    if (_isMetaMask) {
      _proxyContract = Contract(
        _lendingPoolProxyAddress,
        _proxyIface,
        _currentSigner,
      );
    }
  }

  /// reset param
  ///
  void clear() {}

  /// Dispose of service
  ///
  void dispose() {
    clear();
  }

  /// Connect to provider
  ///
  Future<void> connectProvider() async {
    print('connecting to provider');
    if (Ethereum.isSupported) {
      _isMetaMask = true;
      try {
        _web3Provider = provider!;
        _currentSigner = _web3Provider.getSigner();
        final _account = await ethereum!.requestAccount();
        if (_account.isNotEmpty) {
          _currentSignerAddress = _account.first;
        }
      } on EthereumUserRejected {
        print('user rejected requiest');
      } catch (e) {
        print('error is: $e');
      }
    }
  }

  /// get signer balance.
  ///

  Future<void> getBalance() async {
    print('getting current balance');
    BigInt _currentBalance = await _web3Provider.getSigner().getBalance();
    var _ethBalance = EthUtils.formatEther(_currentBalance.toString());
    print('current balance in eth: $_ethBalance');
  }

  /// send funds to address.
  ///
  Future<void> sendFunds(
      {required String receiver, required double amountInEth}) async {
    print('Sending funds');
    final formatedAmount =
        BigInt.from(EthUtils.parseUnit(amountInEth.toString()).toDouble);
    final sendTx = await _currentSigner.sendTransaction(
        TransactionRequest(to: receiver, value: formatedAmount));
    final TransactionReceipt txReceipt = await sendTx.wait();
    print('tx receipt: $txReceipt');
  }

  /// get latest blocks
  ///
  Future<void> getLatestBlock() async {
    print('getting latest block');
    try {
      var latestBlock = await _web3Provider.getLastestBlock();
      print('latest block: $latestBlock');
    } catch (e) {
      print('error is: $e');
    }
  }

  /// query block for borrow events on specified block range.
  /// If range is not specified, returns the latest block
  ///
  Future<void> queryEventBlockWithFilter({int? fromBlock, int? toBlock}) async {
    print('getting querying block with filter');
    try {
      final filter = EventFilter(address: _lendingPoolProxyAddress);
      final List<Event> events = await _proxyContract.queryFilter(
        filter,
        fromBlock,
        toBlock,
      );
      final List decoded = EthUtils.defaultAbiCoder
          .decode(["address", "uint256", "uint256", "uint256"], events[1].data);
      print('decoded event data: $decoded');
    } catch (e) {
      print('error is: $e');
    }
  }

  /// get user account data from aave.
  ///
  Future<void> getUserAccountData({required String address}) async {
    print('getting user accnt data');
    try {
      final String data =
          _lendingPoolIface.encodeFunctionData("getUserAccountData", [address]);
      final TransactionRequest txRequest =
          TransactionRequest(to: _lendingPoolProxyAddress, data: data);
      String callTx = await _web3Provider.getSigner().call(txRequest);

      AaveUserAccountData userAccntData = _decodeUserAccountData(callTx);
      print('callTx:\n $userAccntData');
    } catch (e) {
      print('error is: $e');
    }
  }

  /// listen for borrow events emitted by AaVe
  ///
  void _listenForBorrowEvents() {
    print('listenning for event');

    String eventHash = _lendingPoolIface.getEventTopic("Borrow");

    var filter = EventFilter(topics: [eventHash]); // filter event based on hash

    _web3Provider.onFilter(filter, (event) {
      Event resultingEvent = Event.fromJS(event);

      AaveBorrowEvent borrowEvent = _decodeBorrowEvent(resultingEvent);

      print(borrowEvent);
    });
  }

  /// Decode user account data.
  AaveUserAccountData _decodeUserAccountData(String callTx) {
    List decodedRes =
        _lendingPoolIface.decodeFunctionResult("getUserAccountData", callTx);

    AaveUserAccountData userAccntData = AaveUserAccountData(
        totalCollateralEth:
            double.parse(EthUtils.formatEther(decodedRes[0].toString())),
        totalDebtETH:
            double.parse(EthUtils.formatEther(decodedRes[1].toString())),
        availableBorrowsETH:
            double.parse(EthUtils.formatEther(decodedRes[2].toString())),
        currentLiquidationThreshold:
            double.parse(EthUtils.formatUnits(decodedRes[3].toString(), 2)),
        ltv: double.parse(EthUtils.formatUnits(decodedRes[4].toString(), 2)),
        healthFactor:
            double.parse(EthUtils.formatEther(decodedRes[5].toString())));
    return userAccntData;
  }

  /// Decode borrow event
  AaveBorrowEvent _decodeBorrowEvent(Event resultingEvent) {
    var decodedReserve =
        EthUtils.defaultAbiCoder.decode(["address"], resultingEvent.topics[1]);

    var decodedData = EthUtils.defaultAbiCoder.decode(
        ["address", "uint256", "uint256", "uint256"], resultingEvent.data);
    AaveBorrowEvent borrowEvent = AaveBorrowEvent(
      userAddress: decodedData[0].toString(),
      reserve: decodedReserve[0].toString(),
      amount: double.parse(EthUtils.formatEther(decodedData[1].toString())),
      borrowRateMode: double.parse(decodedData[2].toString()),
      borrowRate: double.parse(decodedData[3].toString()),
    );
    return borrowEvent;
  }
}
