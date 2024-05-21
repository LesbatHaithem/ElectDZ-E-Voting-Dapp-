import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back%20End/blockchain.dart';
import 'package:mrtdeg/Back%20End/vote.dart';
import 'package:mrtdeg/Back%20End/splash.dart';
import 'package:mrtdeg/Back%20End/winner.dart';
import 'package:mrtdeg/Back%20End/Confirm.dart';
import 'Gradientbutton.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlowScreen extends StatefulWidget {
  @override
  _FlowScreenState createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  final Blockchain blockchain = Blockchain();
  final AlertStyle animation = AlertStyle(animationType: AnimationType.grow);
  final PageController _pageController = PageController();
  final GlobalKey _overlayKey = GlobalKey();

  String quorumText = "Loading Quorum...";
  double quorumCircle = 0.0;
  int step = 0;
  bool showOverlay = false;

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
    // Add more lists of image URLs for other steps if needed
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialUpdateQuorum());
    _checkFirstVisit();
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

  Future<void> _mayorOrSayonara() async {
    _showAlert("Asking the winner...");
    await Future.delayed(Duration(milliseconds: 500));

    try {
      await blockchain.query("mayor_or_sayonara", []);
      _navigateToWinnerPage();
    } catch (error) {
      Navigator.of(context).pop();
      if (error.toString().contains("has already been")) {
        _navigateToWinnerPage();
      } else {
        //_showErrorAlert(blockchain.translateError(error));
      }
    }
  }

  Future<void> _initialUpdateQuorum() async {
    _showAlert("Getting election status...");
    await Future.delayed(Duration(milliseconds: 500));

    try {
      final value = await blockchain.queryView("get_status", [await blockchain.myAddr()]);
      Navigator.of(context).pop();
      setState(() {
        quorumText = value[0] != value[1]
            ? "${value[0] - value[1]} votes to quorum (${value[1]}/${value[0]})"
            : "Quorum reached! (Total voters: ${value[0]})";
        quorumCircle = value[1] / value[0];
        step = _determineStep(value);
      });
    } catch (error) {
      Navigator.of(context).pop();
      //_showErrorAlert(blockchain.translateError(error));
    }
  }

  Future<void> _updateQuorum() async {
    _showAlert("Getting election status...");
    await Future.delayed(Duration(milliseconds: 500));

    try {
      final value = await blockchain.queryView("get_status", [await blockchain.myAddr()]);
      Navigator.of(context).pop();
      if (!value[3]) {
        _navigateToWinnerPage();
      } else {
        setState(() {
          quorumText = value[0] != value[1]
              ? "${value[0] - value[1]} votes to quorum (${value[1]}/${value[0]})"
              : "Quorum reached! (Total voters: ${value[0]})";
          quorumCircle = value[1] / value[0];
          step = _determineStep(value);
        });
      }
    } catch (error) {
      Navigator.of(context).pop();
      //_showErrorAlert(blockchain.translateError(error));
    }
  }

  int _determineStep(List<dynamic> value) {
    if (value[4]) { // addr is a candidate
      return !value[3] ? 4 : 3; // elections closed
    } else if (!value[3]) { // elections open
      return 2;
    } else if (value[1] == value[0]) { // quorum reached
      return value[2] ? 1 : 2; // envelope not open
    } else { // start
      return 0;
    }
  }

  void _showAlert(String title) {
    Alert(
      context: context,
      title: title,
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
  }

  void _showErrorAlert(String error) {
    Alert(
      context: context,
      type: AlertType.error,
      title: "Error",
      desc: error,
      style: animation,
    ).show();
  }

  void _navigateToWinnerPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Winner()),
    );
  }

  List<Widget> _buildSteps() {
    if (step == -1) {
      return [Center(child: Text("Loading..."))];
    } else if (step > 2) {
      // Steps for mayor to deposit funds and declare winner
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
            ElevatedButton.icon(
              icon: Icon(Icons.gavel),
              label: Text("Ask to declare"),
              onPressed: step == 4 ? _mayorOrSayonara : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            ),
          ],
          imageUrls: imageUrlsPerStep[1],
        ),
      ];
    } else {
      // General steps for voting process
      return [
        _buildStep(
          title: 'Cast your vote',
          description: 'Every vote you cast overwrites the previous one',
          actions: [
            Padding(
              padding: const EdgeInsets.all(60.0),
              child: GradientButton(
                text: "Vote",
                onPressed: step == 0 ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => Vote(isConfirming: false))) : null,
                icon: Icon(Icons.how_to_vote, color: Colors.black),
                width: 200,
                height: 50,
              ),
            ),
          ],
          imageUrls: imageUrlsPerStep[0],
        ),
        _buildStep(
          title: 'Confirm your vote',
          description: 'When the quorum is reached you can confirm your vote',
          actions: [
            Padding(
              padding: const EdgeInsets.all(60.0),
              child: GradientButton(
                text: "Confirm",
                icon: Icon(Icons.check_circle_outline, color: Colors.black),
                onPressed: step == 1 ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => Confirm(isConfirming: true))) : null,
                width: 200,
                height: 50,
              ),
            ),
          ],
          imageUrls: imageUrlsPerStep[1],
        ),
        _buildStep(
          title: 'Declare the winner',
          description: 'Once everyone has confirmed their vote you can ask to declare the winner',
          actions: [
            Padding(
              padding: const EdgeInsets.all(60.0),
              child: GradientButton(
                text: "Ask to declare",
                icon: Icon(Icons.gavel, color: Colors.black),
                onPressed: step == 2 ? _mayorOrSayonara : null,
                width: 200,
                height: 50,
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

  Widget _buildQuorumCard() {
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
          leading: CircularProgressIndicator(color: Colors.green, value: quorumCircle),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0), side: BorderSide(color: Colors.blue, width: 1.0)),
            ),
            onPressed: () => _updateQuorum(),
            child: Text("Update"),
          ),
          title: Text(quorumText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: AppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              title: Text('ElectDz', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
              elevation: 0,
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
          Column(
            children: [
              _buildQuorumCard(),
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
