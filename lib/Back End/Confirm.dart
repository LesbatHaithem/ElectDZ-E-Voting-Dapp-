import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back%20End/blockchain.dart';
import 'Gradientbutton.dart';

class Confirm extends StatefulWidget {
  final bool isConfirming;

  Confirm({Key? key, required this.isConfirming}) : super(key: key);

  @override
  _ConfirmState createState() => _ConfirmState();
}

class _ConfirmState extends State<Confirm> {
  final _formKey = GlobalKey<FormState>();
  final text_secret = TextEditingController();
  AlertStyle animation = AlertStyle(animationType: AnimationType.grow);

  String quorum_text = "Loading Quorum...";
  double quorum_circle = 0.0;
  int step = -1;

  Blockchain blockchain = Blockchain();
  List<dynamic> candidates = [];
  List<dynamic> firstNames = [];
  List<dynamic> lastNames = [];
  List<dynamic> imageUrls = [];
  List<dynamic> groups = [];
  List<dynamic> groupNames = [];
  List<dynamic> groupPictures = [];
  List<dynamic> groupAddresses = [];

  List<bool> _expandedGroup = [];
  int _selectedGroup = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGroupsAndCandidates());
  }

  Future<void> _updateGroupsAndCandidates() async {
    Alert(
      context: context,
      title: "Getting groups and candidates...",
      desc: "Please wait while we fetch the group and candidate details.",
      buttons: [],
      style: AlertStyle(
        animationType: AnimationType.grow,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        overlayColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
          side: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
            width: 1,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        titleStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        descStyle: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        animationDuration: Duration(milliseconds: 500),
        alertElevation: 0,
        buttonAreaPadding: EdgeInsets.all(20),
        alertPadding: EdgeInsets.all(20),
      ),
    ).show();

    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final groupDetails = await blockchain.queryView("getAllDetails", []);
        Navigator.of(context).pop();
        setState(() {
          groupNames = groupDetails[0];
          groupPictures = groupDetails[1];
          groupAddresses = groupDetails[2].map((group) => group[0]).toList(); // Extract group addresses
          groups = List.generate(groupDetails[0].length, (index) {
            return {
              'name': groupNames[index],
              'pictureUrl': groupPictures[index],
              'candidateAddresses': groupDetails[2][index]
            };
          });
          candidates = groupDetails[3];
          firstNames = groupDetails[4];
          lastNames = groupDetails[5];
          imageUrls = groupDetails[6];
          _expandedGroup = List<bool>.filled(groups.length, false);
        });
      } catch (error) {
        Navigator.of(context).pop();
        Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: error.toString(),
        ).show();
      }
    });
  }

  bool checkSelection() {
    if (_selectedGroup == -1) {
      Alert(
        context: context,
        type: AlertType.error,
        title: "Error",
        desc: (widget.isConfirming)
            ? "Please select the group you voted for"
            : "Please select the group you want to vote for",
        style: AlertStyle(
          animationType: AnimationType.grow,
          isCloseButton: false,
          isOverlayTapDismiss: false,
          overlayColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
          alertBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
            side: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          titleStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          descStyle: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          animationDuration: const Duration(milliseconds: 500),
          alertElevation: 0,
        ),
      ).show();
      return false;
    }
    return true;
  }

  Future<void> _updateQuorum() async {
    Alert(
      context: context,
      title: "Getting election status...",
      buttons: [],
      style: AlertStyle(
        animationType: AnimationType.fromTop,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        descStyle: TextStyle(fontWeight: FontWeight.bold),
        animationDuration: Duration(milliseconds: 400),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40.0),
          side: BorderSide(color: Colors.white, width: 2),
        ),
        titleStyle: TextStyle(color: Colors.black),
      ),
    ).show();
    Future.delayed(Duration(milliseconds: 500), () async => {
      blockchain.queryView("get_status", [await blockchain.myAddr()]).then((value) => {
        Navigator.of(context).pop(),
        setState(() {
          quorum_text = (value[0] != value[1])
              ? "${value[0] - value[1]} votes to quorum (${value[1]}/${value[0]})"
              : "Quorum reached! (Total voters: ${value[0]})";
          quorum_circle = value[1] / value[0];
          print(value);
          if (value[1] == value[0]) {
            if (value[2]) { // envelope not open
              step = 1;
            } else { // envelope opened
              step = 2;
            }
          } else { // start or quorum not reached
            step = 0;
          }
        })
      }).catchError((error) {
        Navigator.of(context).pop();
        Alert(
            context: context,
            type: AlertType.error,
            title: "Error",
            desc: blockchain.translateError(error),
            style: animation
        ).show();
      })
    });
  }

  Future<void> _openVote() async {
    if (!checkSelection()) return;

    print("Selected group: $_selectedGroup");
    print("Secret text: ${text_secret.text}");

    List<dynamic> args = [
      BigInt.parse(text_secret.text), // secret as BigInt
      groupAddresses[_selectedGroup] // group address
    ];

    print("Arguments passed to blockchain: $args");

    Alert(
      context: context,
      title: "Confirming your vote...",
      buttons: [],
      style: AlertStyle(
        animationType: AnimationType.grow,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        overlayColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
          side: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
            width: 1,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        titleStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        descStyle: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        animationDuration: const Duration(milliseconds: 500),
        alertElevation: 0,
        buttonAreaPadding: const EdgeInsets.all(20),
        alertPadding: const EdgeInsets.all(20),
      ),
    ).show();
    Future.delayed(const Duration(milliseconds: 500), () {
      blockchain.query("open_envelope", args).then((value) {
        Navigator.of(context).pop();
        Alert(
          style: AlertStyle(
            animationType: AnimationType.grow,
            isCloseButton: false,
            isOverlayTapDismiss: false,
            overlayColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
            alertBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
              side: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 1,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.background,
            titleStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            descStyle: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            animationDuration: const Duration(milliseconds: 500),
            alertElevation: 0,
            buttonAreaPadding: const EdgeInsets.all(20),
            alertPadding: const EdgeInsets.all(20),
          ),
          context: context,
          type: AlertType.success,
          title: "OK",
          desc: "Your vote has been confirmed!",
        ).show();
      }).catchError((error) {
        Navigator.of(context).pop();
        Alert(
          style: AlertStyle(
            animationType: AnimationType.grow,
            isCloseButton: false,
            isOverlayTapDismiss: false,
            overlayColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
            alertBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
              side: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 1,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.background,
            titleStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            descStyle: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            animationDuration: const Duration(milliseconds: 500),
            alertElevation: 0,
            buttonAreaPadding: const EdgeInsets.all(20),
            alertPadding: const EdgeInsets.all(20),
          ),
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: blockchain.translateError(error),
        ).show();
      });
    });
  }

  Future<void> _handleRefresh() async {
    return await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: AppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              title: Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              elevation: 0,
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LiquidPullToRefresh(
          onRefresh: _handleRefresh,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
            child: ListView(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'Confirm your previous vote',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                        child: ExpansionPanelList(
                          expansionCallback: (int index, bool isExpanded) {
                            setState(() {
                              _expandedGroup[index] = !isExpanded;
                            });
                          },
                          children: groups.map<ExpansionPanel>((group) {
                            int groupIndex = groups.indexOf(group);
                            return ExpansionPanel(
                              headerBuilder: (BuildContext context, bool isExpanded) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _expandedGroup[groupIndex] = !isExpanded;
                                      _selectedGroup = groupIndex;
                                    });
                                  },
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: NetworkImage(group['pictureUrl']),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      group['name'],
                                      style: TextStyle(
                                        color: (_selectedGroup == groupIndex)
                                            ? Colors.blue
                                            : Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: group['candidateAddresses'].map<Widget>((candidate) {
                                  int candidateIndex = candidates.indexOf(candidate);
                                  return ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: NetworkImage(imageUrls[candidateIndex]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      "${firstNames[candidateIndex]} ${lastNames[candidateIndex]}",
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              isExpanded: _expandedGroup[groupIndex],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Secret code',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue, width: 2.0),
                          ),
                          contentPadding: EdgeInsets.all(16.0),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a secret code';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        controller: text_secret,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 200,
                                child: GradientButton(
                                  text: "Confirm Vote",
                                  onPressed: () {
                                    _openVote();
                                  },
                                  width: 200,
                                  height: 50,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Container(
                              width: 405,
                              height: 115,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.blue,
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    leading: CircularProgressIndicator(
                                      color: Colors.green,
                                      value: quorum_circle,
                                    ),
                                    trailing: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30.0),
                                          side: BorderSide(
                                            color: Colors.blue,
                                            width: 1.0,
                                          ),
                                        ),
                                      ),
                                      onPressed: _updateQuorum,
                                      child: Text("Update"),
                                    ),
                                    title: Text('$quorum_text'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
