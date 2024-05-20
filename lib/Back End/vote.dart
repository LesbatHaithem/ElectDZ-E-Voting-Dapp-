import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back%20End/blockchain.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'Gradientbutton.dart';
import 'winner.dart';
import 'dart:ui'; // Import for the blur effect

class Vote extends StatefulWidget {
  final bool isConfirming;

  Vote({Key? key, required this.isConfirming}) : super(key: key);

  @override
  _VoteState createState() => _VoteState();
}

class _VoteState extends State<Vote> {
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
              'candidates': groupDetails[2][index]
            };
          });
          candidates = groupDetails[3];
          firstNames = groupDetails[4];
          lastNames = groupDetails[5];
          imageUrls = groupDetails[6];
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
        if (value[3] == false){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Winner()),
          )
        },
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
            desc: error.toString(),
            style: animation
        ).show();
      })
    });
  }

  Future<void> _sendVote() async {
    if (!checkSelection())
      return;

    List<dynamic> args = [
      blockchain.encodeVote(BigInt.parse(text_secret.text), groupAddresses[_selectedGroup]) // Use group address
    ];

    Alert(
      context: context,
      title: "Sending your vote...",
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
      blockchain.query("cast_envelope", args).then((value) {
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
          desc: "Your vote has been cast!",
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
          desc: error.toString(), // blockchain.translateError(error)
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
              title: Text('Vote', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
                        'Vote The New Mayor',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      StaggeredGrid.count(
                        crossAxisCount: 1,
                        mainAxisSpacing: 4.0,
                        crossAxisSpacing: 4.0,
                        children: List.generate(groups.length, (int groupIndex) {
                          var group = groups[groupIndex];
                          var validCandidates = group['candidates'].where((candidate) => candidates.contains(candidate)).toList();
                          validCandidates.remove(groupAddresses[groupIndex]); // Remove the group address
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedGroup = groupIndex;
                              });
                            },
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              color: (_selectedGroup == groupIndex) ? Colors.lightBlueAccent : Colors.white,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: Colors.white.withOpacity(0.2),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading: Container(
                                              width: 40,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                image: DecorationImage(
                                                  image: NetworkImage(group['pictureUrl']),
                                                  fit: BoxFit.cover,
                                                  onError: (exception, stackTrace) {
                                                    setState(() {
                                                      group['pictureUrl'] = 'assets/placeholder.png';
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              group['name'],
                                              style: TextStyle(
                                                color: (_selectedGroup == groupIndex) ? Colors.black : Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          CarouselSlider(
                                            options: CarouselOptions(
                                              height: 200,
                                              enlargeCenterPage: true,
                                              autoPlay: true,
                                              aspectRatio: 16 / 9,
                                              autoPlayCurve: Curves.fastOutSlowIn,
                                              enableInfiniteScroll: true,
                                              autoPlayAnimationDuration: Duration(milliseconds: 400),
                                              viewportFraction: 0.8,
                                            ),
                                            items: validCandidates.map<Widget>((candidate) {
                                              int candidateIndex = candidates.indexOf(candidate);
                                              return Builder(
                                                builder: (BuildContext context) {
                                                  return Column(
                                                    children: [
                                                      Container(
                                                        width: 100,
                                                        height: 100,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(20),
                                                          image: DecorationImage(
                                                            image: NetworkImage(imageUrls[candidateIndex]),
                                                            fit: BoxFit.cover,
                                                            onError: (exception, stackTrace) {
                                                              setState(() {
                                                                imageUrls[candidateIndex] = 'assets/placeholder.png';
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                      Text(
                                                        "${firstNames[candidateIndex]} ${lastNames[candidateIndex]}",
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
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
                                  text: "Cast Vote",
                                  onPressed: () {
                                    _sendVote();
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
