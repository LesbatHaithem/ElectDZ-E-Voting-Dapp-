import 'package:http/http.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';


class Blockchain {

  String? contractAddr;
  late Client httpClient;
  late Web3Client ethClient;
  late Credentials creds;
  late DeployedContract contract;

  Blockchain(){
    SharedPreferences.getInstance().then((prefs) => {
      creds = EthPrivateKey.fromHex(prefs.getString('key')!),
      contractAddr = prefs.getString("contract")
    });
    httpClient = new Client();
    String apiUrl = "http://192.168.17.60:7545";
    ethClient = new Web3Client(apiUrl, httpClient);
    rootBundle.loadString("assets/abi.json").then((value) => {
      contract = loadContract(value),
      print("Contract: " + contractAddr!)
    });
  }

  DeployedContract loadContract(String abi){
    final contract = DeployedContract(ContractAbi.fromJson(abi, "Mayor"), EthereumAddress.fromHex(contractAddr!));
    return contract;
  }

  Future<List<dynamic>> queryView(String fun, List<dynamic> args) async {
    print("Calling blockchain function: " + fun);
    return ethClient.call(
      sender: await creds.address,
      contract: contract,
      function: contract.function(fun),
      params: args,


    );
  }

  Future<Future<String>> query(String fun, List<dynamic> args, {BigInt? wei}) async {
    if (wei == null)
      wei = BigInt.zero;
    return ethClient.sendTransaction(
        creds,
        Transaction.callContract(
      contract: contract,
      function: contract.function(fun),
      parameters: args,
      value: EtherAmount.inWei(wei),
      maxGas: 999999,
    ),
        chainId: 1337,
        fetchChainIdFromNetworkId: false
    );
  }

  String translateError(RPCError error) {
    String errorMessage = error.message;
    // This assumes that error.message is directly accessible and contains the error message.
    // Adjust according to your actual RPCError structure.

    if (errorMessage.contains("revert")) {
      // Split on "revert" and take the second part, which is the error message post-revert
      List<String> parts = errorMessage.split("revert");
      if (parts.length > 1) {
        // Further clean up to remove any trailing characters or quotation marks
        return parts[1].trim().replaceAll(RegExp(r'[."]+$'), "");
      }
    }

    // Default to returning the full error message if not processed above
    return errorMessage;
  }

  Future<bool> check() async {
    try {
      var blockNumber = await ethClient.getBlockNumber();
      print("Current block number: $blockNumber");
      return true;  // Connection is good
    } catch (error) {
      print("Blockchain connection failedd: $error");
      return false; // Connection failed
    }
  }

  void logout(){
    SharedPreferences.getInstance().then((prefs) => {
      prefs.remove('key'),
      prefs.remove('contract')
    });
  }

  Future<EthereumAddress> myAddr() async {
    EthereumAddress address = await creds.address;
    return address;
  }

  Uint8List encodeVote(BigInt secret, EthereumAddress addr, BigInt wei) {
    List<dynamic> parameters = [secret,addr, wei];
    AbiType type = TupleType(
      [UintType(),AddressType(), UintType()],
    );
    print(type);
    final sink = LengthTrackingByteSink();

    type.encode(parameters, sink);
    return keccak256(sink.asBytes());

  }

  String soulsUnit(BigInt souls){
    double wei = souls.toDouble();
    if (wei >= 10000000000000000){
      return (wei/1000000000000000000).toString() + " ETH";
    } else if (wei >= 10000000){
      return (wei/1000000000).toString() + " GWEI";
    } else {
      return wei.toString() + " WEI";
    }
  }
}