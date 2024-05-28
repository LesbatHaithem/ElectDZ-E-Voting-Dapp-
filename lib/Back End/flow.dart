import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back%20End/blockchain.dart';
import 'package:mrtdeg/Back%20End/vote.dart';
import 'package:mrtdeg/Back%20End/splash.dart';
import 'package:mrtdeg/Back%20End/winner.dart';
import 'package:mrtdeg/Back%20End/Confirm.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class FlowScreen extends StatefulWidget {
  @override
  _FlowScreenState createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  final Blockchain blockchain = Blockchain();
  final AlertStyle animation = AlertStyle(animationType: AnimationType.grow);
  final PageController _pageController = PageController();
  final GlobalKey _overlayKey = GlobalKey();

  double timeRemainingCircle = 0.0;
  String timeRemainingText = "Loading...";
  BigInt? totalDuration;
  int step = 0;
  bool showOverlay = false;
  bool _isPressedVote = false;
  bool _isPressedConfirm = false;
  bool _isPressedDeclare = false;
  Timer? _timer;

  final List<List<String>> imageUrlsPerStep = [
    [
      'https://white-high-quokka-246.mypinata.cloud/ipfs/QmV8N4SoYvz9wnatC57uPckVuPoNsRNPrcAAeR2kCDEhax',
      'https://white-high-quokka-246.mypinata.cloud/ipfs/QmW7c8xJP3Yxs5SoK8rwRgew3Gn6xbV3umtrPUB2xfgyoh',
      'https://white-high-quokka-246.mypinata.cloud/ipfs/QmYYM5R5pqkNGjes8kTpUMRo7gfwDPZzV7DTCziX6vYzEg',
      'https://white-high-quokka-246.mypinata.cloud/ipfs/QmZYwdYy83ajbPXcQ85Ey7gP93rrvHxYfGKDv6reiiwca6',
    ],
    [
      'https://white-high-quokka-246.mypinata.cloud/ipfs/QmTnXhXzSHHwgZzR5Y7zNAF3DU87pKUMCFL1bSeMnYaRga',
      'https://white-high-quokka-246.mypinata.cloud/ipfs/QmWjfzn3qE3VmhvFWxM99HnmrgpdnEivEg4vm4iD4MaLxv',
      'https://white-high-quokka-246.mypinata.cloud/ipfs/QmSGEqUgPg3X8kThv9J2atRrDxhDEJHzWaq3HAJDQDZKqA',
      'https://white-high-quokka-246.mypinata.cloud/ipfs/Qmb18RQhZSesitQ253WkxKWjonQPAFUXtpYCwuT6DuNzmF',
    ],
    [
      'https://white-high-quokka-246.mypinata.cloud/ipfs/QmQJ2uhGpz5zo1iVHzRXG9qFhzsYGAaRLZ4WmcFNKVf5ps',
      'https://white-high-quokka-246.mypinata.cloud/ipfs/QmUysMzk5VA4brrwuTGic71VG9FvRPDofdGwnFnf71S2p6',
    ],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeadline());
    _checkFirstVisit();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkFirstVisit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstVisit = prefs.getBool('isFirstVisit') ?? true;
    if (isFirstVisit) {
      setState(() {
        showOverlay = true;
      });
      prefs.setBool('isFirstVisit', false);
    }
  }

  Future<void> _loadDeadline() async {
    try {
      final result = await blockchain.queryView("get_deadline", []);
      if (result.isNotEmpty) {
        final deadline = BigInt.parse(result[0].toString());
        final currentTime = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);
        if (totalDuration == null) {
          totalDuration = deadline - currentTime;
        }
        final timeRemaining = deadline - currentTime;

        if (!mounted) return;

        setState(() {
          if (timeRemaining > BigInt.zero) {
            final hours = (timeRemaining ~/ BigInt.from(3600)).toInt();
            final minutes = ((timeRemaining % BigInt.from(3600)) ~/ BigInt.from(60)).toInt();
            final seconds = (timeRemaining % BigInt.from(60)).toInt();

            timeRemainingText = "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} remaining";
            timeRemainingCircle = timeRemaining.toDouble() / totalDuration!.toDouble();
          } else {
            timeRemainingText = "Voting period has ended";
            timeRemainingCircle = 0.0;
          }
        });
      } else {
        if (!mounted) return;

        setState(() {
          timeRemainingText = "Failed to get status";
          timeRemainingCircle = 0.0;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        timeRemainingText = "Failed to get status";
        timeRemainingCircle = 0.0;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      await _loadDeadline();
    });
  }

  Future<void> _validCandidateCheck() async {
    _showLoadingDialog("Checking the winner...", "Please wait while we fetch the vote results.");

    try {
      final deadlineResult = await blockchain.queryView("get_deadline", []);

      if (deadlineResult.isEmpty) {
        throw Exception("No deadline found.");
      }

      final deadline = BigInt.parse(deadlineResult[0].toString());
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (currentTime > deadline.toInt()) {
        await blockchain.query("valid_candidate_check", []);
      } else {
        throw Exception("Voting period has not ended yet.");
      }

      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Winner()),
      );
    } catch (error) {
      Navigator.of(context).pop();

      if (error.toString().contains("has already been")) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Winner()),
        );
        return;
      }

      _showErrorDialog(error.toString());
    }
  }

  void _showLoadingDialog(String title, String description) {
    AwesomeDialog(
      context: context,
      customHeader: CircularProgressIndicator(),
      dialogType: DialogType.info,
      headerAnimationLoop: false,
      animType: AnimType.topSlide,
      title: title,
      desc: description,
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
      showCloseIcon: false,
    ).show();
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      headerAnimationLoop: false,
      animType: AnimType.topSlide,
      title: "Error",
      desc: message,
      btnOkOnPress: () {},
      btnOkColor: Theme.of(context).colorScheme.secondary,
    ).show();
  }

  List<Widget> _buildSteps() {
    if (step == -1) {
      return [Center(child: Text("Loading..."))];
    } else if (step > 2) {
      return [
        _buildStep(
          title: 'Deposit some funds',
          description: 'You can deposit some funds to encourage people to vote for you',
          actions: [],
          imageUrls: imageUrlsPerStep[0],
        ),
        _buildStep(
          title: 'Declare the winner',
          description: 'Once everyone has confirmed their vote you can ask to declare the winner',
          actions: [
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPressedDeclare = true;
                  });

                  Future.delayed(Duration(milliseconds: 300), () {
                    setState(() {
                      _isPressedDeclare = false;
                    });
                    if (step == 4) _validCandidateCheck();
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 50,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: _isPressedDeclare
                        ? [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.5),
                        spreadRadius: 20,
                        blurRadius: 30,
                      )
                    ]
                        : [],
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "See Results ",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          imageUrls: imageUrlsPerStep[1],
        ),
      ];
    } else {
      return [
        _buildStep(
          title: 'Cast your vote',
          description: 'Tap vote and Select your Preferred Political party , Please Create a Secret Code and Tap Cast Vote',
          actions: [
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPressedVote = true;
                  });

                  Future.delayed(Duration(milliseconds: 300), () {
                    setState(() {
                      _isPressedVote = false;
                    });
                    if (step == 0)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Vote(isConfirming: false),
                        ),
                      );
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 50,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: _isPressedVote
                          ? [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.5),
                          spreadRadius: 20,
                          blurRadius: 30,
                        )
                      ]
                          : [],
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Vote",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          imageUrls: imageUrlsPerStep[0],
        ),
        _buildStep(
          title: 'Confirm your vote',
          description: 'Tap Confirm & Confirm your Previous Vote , Make sure you Enter the same Secret Code you created earlier ',
          actions: [
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPressedConfirm = true;
                  });

                  Future.delayed(Duration(milliseconds: 300), () {
                    setState(() {
                      _isPressedConfirm = false;
                    });
                    if (step == 1)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Confirm(isConfirming: true),
                        ),
                      );
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 50,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: _isPressedConfirm
                          ? [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.5),
                          spreadRadius: 20,
                          blurRadius: 30,
                        )
                      ]
                          : [],
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Confirm",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          imageUrls: imageUrlsPerStep[1],
        ),
        _buildStep(
          title: 'Declare the winner',
          description: 'Once The Voting Period Ended you can Tap See Results To See the Statistics and Who Won 👑 ',
          actions: [
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPressedDeclare = true;
                  });

                  Future.delayed(Duration(milliseconds: 300), () {
                    setState(() {
                      _isPressedDeclare = false;
                    });
                    if (step == 2) _validCandidateCheck();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 50,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: _isPressedDeclare
                          ? [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.5),
                          spreadRadius: 20,
                          blurRadius: 30,
                        )
                      ]
                          : [],
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "See Results",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          imageUrls: imageUrlsPerStep[2],
        ),
      ];
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _buildSteps().length,
            (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          width: step == index ? 12.0 : 8.0,
          height: step == index ? 12.0 : 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: step == index ? Colors.blue : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe, color: Colors.white, size: 100),
                  Text(
                    "Slide to navigate",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showOverlay = false;
                      });
                    },
                    child: Text("Got it!"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep({required String title, required String description, required List<Widget> actions, required List<String> imageUrls}) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 16.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 27))),
            SizedBox(height: 8.0),
            Text(description, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 20),
            CarouselSlider(
              options: CarouselOptions(
                height: 300,
                enlargeCenterPage: true,
                autoPlay: true,
                aspectRatio: 16 / 9,
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: true,
                autoPlayAnimationDuration: Duration(milliseconds: 800),
                viewportFraction: 1,
              ),
              items: imageUrls.map((url) {
                return Builder(
                  builder: (BuildContext context) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Container(
        width: 400,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.blue]),
        ),
        child: ListTile(
          leading: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.green,
                value: timeRemainingCircle,
                strokeWidth: 5.0,
              ),
              Text(
                "${(timeRemainingCircle * 100).toStringAsFixed(0)}%",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
                side: BorderSide(color: Colors.blue, width: 1.0),
              ),
            ),
            onPressed: () => _loadDeadline(),
            child: Text("Update"),
          ),
          title: Text(timeRemainingText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend the body behind the app bar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: AppBar(
              backgroundColor: Colors.transparent, // Make the app bar transparent
              title: Text(
                'ElectDz',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevation: 0, // Remove the app bar shadow
              centerTitle: true,
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      blockchain.logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => SplashScreen()),
                            (Route<dynamic> route) => false,
                      );
                    },
                    child: Icon(Icons.logout, size: 26.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.6, // Adjust the opacity for fading effect
              child: Image.asset(
                'assets/background.png', // Your background image asset
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: 80), // Add padding to avoid content being obscured by the app bar
              _buildTimerCard(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      step = index;
                    });
                  },
                  children: _buildSteps(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2.8),
                child: _buildStepIndicator(),
              ),
            ],
          ),
          if (showOverlay) _buildOverlay(),
        ],
      ),
    );
  }
}
