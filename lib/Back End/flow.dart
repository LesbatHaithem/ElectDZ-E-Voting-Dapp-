import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back%20End/blockchain.dart';
import 'package:mrtdeg/Back%20End/vote.dart';
import 'package:mrtdeg/Back%20End/splash.dart';
import 'package:mrtdeg/Back%20End/winner.dart';
import 'package:mrtdeg/Back%20End/Confirm.dart';
import 'Gradientbutton.dart';

class FlowScreen extends StatefulWidget {
  @override
  _FlowScreenState createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  final Blockchain blockchain = Blockchain();
  final AlertStyle animation = AlertStyle(animationType: AnimationType.grow);
  final PageController _pageController = PageController();

  String quorumText = "Loading Quorum...";
  double quorumCircle = 0.0;
  int step = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateQuorum());
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
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Winner()));
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
        ),
      ];
    } else {
      // General steps for voting process
      return [
        _buildStep(
          title: 'Send your vote',
          description: 'Every vote you cast overwrites the previous one',
          actions: [
            GradientButton(
              text: "Vote",
              onPressed: step == 0 ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => Vote(isConfirming: false))) : null,
              icon: Icon(Icons.how_to_vote, color: Colors.black),
              width: 200,
              height: 50,
            ),
          ],
        ),
        _buildStep(
          title: 'Confirm your vote',
          description: 'When the quorum is reached you can confirm your vote',
          actions: [
            GradientButton(
              text: "Confirm",
              icon: Icon(Icons.check_circle_outline, color: Colors.black),
              onPressed: step == 1 ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => Confirm(isConfirming: true))) : null,
              width: 200,
              height: 50,
            ),
          ],
        ),
        _buildStep(
          title: 'Declare the winner',
          description: 'Once everyone has confirmed their vote you can ask to declare the winner',
          actions: [
            GradientButton(
              text: "Ask to declare",
              icon: Icon(Icons.gavel, color: Colors.black),
              onPressed: step == 2 ? _mayorOrSayonara : null,
              width: 200,
              height: 50,
            ),
          ],
        ),
      ];
    }
  }

  Widget _buildStep({required String title, required String description, required List<Widget> actions}) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
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
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 35)),
            SizedBox(height: 100.0),
            Text(description, style: TextStyle(fontSize: 18.0, color: Colors.black)),
            SizedBox(height: 100.0),
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
        height: 65,
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
            onPressed: _updateQuorum,
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
              actions: <Widget>[
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
      body: Column(
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
        ],
      ),
    );
  }

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(DiagnosticsProperty<bool>('isMayor', step > 2));
  // }
}
