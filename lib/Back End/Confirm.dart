import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:mrtdeg/Back%20End/blockchain.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../UI/Gradientbutton.dart';
import 'dart:ui'; // Import for the blur effect

class Confirm extends StatefulWidget {
  final bool isConfirming;

  Confirm({Key? key, required this.isConfirming}) : super(key: key);

  @override
  _ConfirmState createState() => _ConfirmState();
}

class _ConfirmState extends State<Confirm> {
  final _formKey = GlobalKey<FormState>();
  final textSecretController = TextEditingController();
  bool _obscureText = true;

  double timeRemainingCircle = 0.0;
  String timeRemainingText = "00:00:00";
  bool _isVotingPeriodEnded = false;
  int step = -1;
  int numberOfVoters = 0; // New state variable for number of voters

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

  Timer? _timer;
  Timer? _voterCountTimer; // New timer for fetching number of votes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGroupsAndCandidates());
    _loadDeadline();
    _startTimer();
    _startVoterCountTimer(); // Start the voter count timer
  }

  @override
  void dispose() {
    _timer?.cancel();
    _voterCountTimer?.cancel(); // Cancel the voter count timer
    textSecretController.dispose();
    super.dispose();
  }

  Future<void> _fetchNumberOfVoters() async {
    try {
      final result = await blockchain.queryView("get_vote_count", []);
      if (result.isNotEmpty) {
        setState(() {
          numberOfVoters = int.tryParse(result[0].toString()) ?? 0;
        });
      }
    } catch (error) {
      print("Error fetching number of voters: $error");
    }
  }

  void _startVoterCountTimer() {
    _voterCountTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _fetchNumberOfVoters();
    });
  }

  Future<void> _loadDeadline() async {
    final result = await blockchain.queryView("get_deadline", []);
    if (result.isNotEmpty) {
      final deadline = result[0] as BigInt;
      final currentTime = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final timeRemaining = deadline - currentTime;

      if (!mounted) return;

      setState(() {
        if (timeRemaining > BigInt.zero) {
          final hours = (timeRemaining / BigInt.from(3600)).toInt();
          final minutes = ((timeRemaining % BigInt.from(3600)) / BigInt.from(60)).toInt();
          final seconds = (timeRemaining % BigInt.from(60)).toInt();

          timeRemainingText = "$hours:$minutes:$seconds";
          timeRemainingCircle = timeRemaining.toDouble() / deadline.toDouble();
          _isVotingPeriodEnded = false;
        } else {
          timeRemainingText = "Voting period has ended";
          timeRemainingCircle = 1.0;
          _isVotingPeriodEnded = true;
        }
      });
    } else {
      if (!mounted) return;

      setState(() {
        timeRemainingText = "Failed to get status";
        timeRemainingCircle = 0.0;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      final currentTime = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final result = await blockchain.queryView("get_deadline", []);
      if (result.isNotEmpty) {
        final deadline = result[0] as BigInt;
        final timeRemaining = deadline - currentTime;

        if (!mounted) return;

        setState(() {
          if (timeRemaining > BigInt.zero) {
            final hours = (timeRemaining / BigInt.from(3600)).toInt();
            final minutes = ((timeRemaining % BigInt.from(3600)) / BigInt.from(60)).toInt();
            final seconds = (timeRemaining % BigInt.from(60)).toInt();

            timeRemainingText = "$hours:$minutes:$seconds";
            timeRemainingCircle = timeRemaining.toDouble() / deadline.toDouble();
            _isVotingPeriodEnded = false;
          } else {
            timeRemainingText = "Voting period has ended";
            timeRemainingCircle = 1.0;
            _isVotingPeriodEnded = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  Future<void> _updateGroupsAndCandidates() async {
    AwesomeDialog(
      context: context,
      customHeader: CircularProgressIndicator(),
      dialogType: DialogType.info,
      headerAnimationLoop: false,
      animType: AnimType.topSlide,
      title: "Getting groups and candidates...",
      desc: "Please wait while we fetch the group and candidate details.",
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            Text("Please wait while we fetch the group and candidate details.", textAlign: TextAlign.center),
          ],
        ),
      ),
    ).show();

    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final groupDetails = await blockchain.queryView("getGroupDetails", []);
        final candidateDetails = await blockchain.queryView("getCandidateDetails", []);
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
          candidates = candidateDetails[0];
          firstNames = candidateDetails[1];
          lastNames = candidateDetails[2];
          imageUrls = candidateDetails[3];
        });
      } catch (error) {
        Navigator.of(context).pop();
        AwesomeDialog(
          context: context,
          customHeader: Icon(
            Icons.error,
            size: 50,
            color: Theme.of(context).colorScheme.error,
          ),
          dialogType: DialogType.error,
          headerAnimationLoop: false,
          animType: AnimType.topSlide,
          title: "Error",
          desc: error.toString(),
          btnOkOnPress: () {},
        ).show();
      }
    });
  }

  bool checkSelection() {
    if (_selectedGroup == -1) {
      AwesomeDialog(
        context: context,
        customHeader: Icon(
          Icons.warning,
          size: 70,
          color: Theme.of(context).colorScheme.primary,
        ),
        dialogType: DialogType.error,
        headerAnimationLoop: false,
        animType: AnimType.topSlide,
        title: "Error",
        desc: (widget.isConfirming) ? "Please select the group you voted for" : "Please select the group you want to vote for",
        btnOkOnPress: () {},
      ).show();
      return false;
    }
    return true;
  }

  Future<void> _openVote() async {
    if (!checkSelection()) return;
    if (textSecretController.text.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        headerAnimationLoop: false,
        animType: AnimType.topSlide,
        title: "Error",
        desc: "Please enter a secret code.",
        btnOkOnPress: () {},
      ).show();
      return;
    }

    List<dynamic> args = [
      BigInt.parse(textSecretController.text),
      groupAddresses[_selectedGroup]
    ];

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      headerAnimationLoop: false,
      animType: AnimType.topSlide,
      title: "Confirming your vote...",
      desc: "",
    ).show();

    Future.delayed(const Duration(milliseconds: 500), () {
      blockchain.query("confirm_envelope", args).then((value) {
        Navigator.of(context).pop();
        AwesomeDialog(
          context: context,
          customHeader: Icon(
            Icons.check_circle,
            size: 50,
            color: Theme.of(context).colorScheme.secondary,
          ),
          dialogType: DialogType.success,
          headerAnimationLoop: false,
          animType: AnimType.topSlide,
          title: "Success",
          desc: "Your vote has been confirmed!",
          btnOkOnPress: () {},
        ).show();
      }).catchError((error) {
        Navigator.of(context).pop();
        AwesomeDialog(
          context: context,
          customHeader: Icon(
            Icons.error,
            size: 50,
            color: Theme.of(context).colorScheme.error,
          ),
          dialogType: DialogType.error,
          headerAnimationLoop: false,
          animType: AnimType.topSlide,
          title: "Error",
          desc: error.toString(),
          btnOkOnPress: () {},
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
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: AppBar(
              backgroundColor: Colors.transparent,
              title: Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              elevation: 0,
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          ClipRRect(
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
                            'Confirm Your Previous Vote',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          CarouselSlider(
                            options: CarouselOptions(
                              autoPlay: true,
                              autoPlayInterval: Duration(seconds: 3),
                              height: 60,
                              viewportFraction: 1.0,
                            ),
                            items: [
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '$timeRemainingText',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '$numberOfVoters votes cast',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          StaggeredGrid.count(
                            crossAxisCount: 1,
                            mainAxisSpacing: 4.0,
                            crossAxisSpacing: 4.0,
                            children: List.generate(groups.length, (int groupIndex) {
                              var group = groups[groupIndex];
                              var validCandidates = group['candidates'].where((candidate) => candidates.contains(candidate)).toList();
                              validCandidates.remove(groupAddresses[groupIndex]);
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
                                                          Padding(
                                                            padding: const EdgeInsets.all(10.0),
                                                            child: Container(
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
                              labelText: 'Enter your Secret code',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20), // Rounded corners
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20), // Rounded corners
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20), // Rounded corners
                                borderSide: BorderSide(color: Colors.blue, width: 2.0),
                              ),
                              contentPadding: EdgeInsets.all(16.0),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureText,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a secret code';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            controller: textSecretController,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 20),
                          Column(
                            children: [
                              Container(
                                width: 200,
                                child: GradientButton(
                                  text: "Confirm Vote",
                                  onPressed: _isVotingPeriodEnded ? null : () => _openVote(),
                                  width: 150,
                                  height: 50,
                                ),
                              ),
                              SizedBox(height: 20), // Add space under the button
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
