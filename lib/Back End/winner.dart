import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back%20End/blockchain.dart';
import 'package:mrtdeg/Back%20End/splash.dart';
import 'package:mrtdeg/Back%20End/utils.dart';
import 'package:mrtdeg/Back%20End/winnerModel.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:mrtdeg/Back%20End/Gradientbutton.dart';

class Winner extends StatefulWidget {
  @override
  _WinnerState createState() => _WinnerState();
}

class _WinnerState extends State<Winner> {
  Blockchain blockchain = Blockchain();

  late ConfettiController _controllerCenter;
  List<WinnerModel> groups = [WinnerModel("Loading", BigInt.zero, "Loading", "")];
  bool? valid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGroups());
    _controllerCenter = ConfettiController(duration: const Duration(seconds: 5));
  }

  Future<void> _updateGroups() async {
    print("Fetching groups...");
    Alert(
      context: context,
      title: "Getting results...",
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

    Future.delayed(const Duration(milliseconds: 500), () {
      blockchain.queryView("get_results", []).then((value) {
        Navigator.of(context).pop();
        print("Results fetched successfully: $value");
        setState(() {
          groups = [];
          for (int i = 0; i < value[0].length; i++) {
            String groupAddr = value[0][i].toString();
            BigInt votes = BigInt.parse(value[1][i].toString());
            String groupName = value[2][i].toString();
            String pictureUrl = value[3][i].toString();

            groups.add(WinnerModel(groupAddr, votes, groupName, pictureUrl));
          }
          // Sort groups by votes in descending order
          groups.sort((a, b) => b.votes!.compareTo(a.votes!));
          valid = true;
          print("Groups updated and sorted. 'valid' set to true.");
        });
        _controllerCenter.play();
        Future.delayed(const Duration(seconds: 5), () {
          _controllerCenter.stop();
        });
      }).catchError((error) {
        Navigator.of(context).pop();
        print('Error fetching results: $error');
        String errorMessage = (error is RPCError) ? blockchain.translateError(error) : error.toString();
        if (error.toString().contains("invalid")) {
          errorMessage = "Elections are invalid (there was a tie). InvalidElections!";
          setState(() {
            valid = false;
            print("Election results invalid due to tie. 'valid' set to false.");
          });
        }
        Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: errorMessage,
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
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize 'body' to a default widget to ensure it's never null.
    Widget body = Center(
      child: Text("Unknown state", style: TextStyle(fontSize: 40, color: Colors.red)),
    );
    if (valid == null) {
      body = Center(
        child: Container(
          margin: const EdgeInsets.only(top: 30.0),
          child: Column(
            children: <Widget>[
              Text("Loading Page ", style: TextStyle(fontSize: 40)),
            ],
          ),
        ),
      );
    } else if (valid == false) {
      body = Center(
        child: Container(
          margin: const EdgeInsets.only(top: 30.0),
          child: Column(
            children: <Widget>[
              Text("Invalid Elections", style: TextStyle(fontSize: 40, color: Colors.black)),
              Text(
                "There was a tie, so no new Mayor.!",
                style: TextStyle(fontSize: 25, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 70),
              Image.asset("assets/invalid.png", width: MediaQuery.of(context).size.width * 0.8),
              SizedBox(height: 50),
              GradientButton(
                text: "Log Out",
                onPressed: () {
                  blockchain.logout();
                  setState(() {
                    Navigator.pushAndRemoveUntil(
                      context,
                      SlideRightRoute(page: SplashScreen()),
                          (Route<dynamic> route) => false,
                    );
                  });
                },
                icon: Icon(Icons.logout, color: Colors.black), // Add an icon if it suits your design
                width: 200, // Optional: Adjust the width as necessary
                height: 50, // Standard touch target height
              ),
            ],
          ),
        ),
      );
    } else if (valid == true) {
      body = Stack(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 30.0),
              child: Column(
                children: <Widget>[
                  Card(
                    color: Colors.yellow,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Text("👑", style: TextStyle(fontSize: 25)),
                          title: Text("${groups[0].groupName}"),
                          subtitle: Text("Votes: ${groups[0].votes}"),
                        ),
                        Image.network(groups[0].pictureUrl!, fit: BoxFit.cover),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  Text("Ranked List", style: TextStyle(fontSize: 40)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            title: Text("${groups[index].groupName}", style: TextStyle(color: Colors.black)),
                            subtitle: Text('🗳 Votes: ${groups[index].votes}'),
                            trailing: Container(
                              width: 40,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(groups[index].pictureUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controllerCenter,
              blastDirectionality: BlastDirectionality.explosive, // don't specify a direction, blast randomly
              shouldLoop: true, // start again as soon as the animation is finished
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.red,
                Colors.yellowAccent,
                Colors.purple,
              ],
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: PreferredSize(
        child: Container(
          child: AppBar(
            title: Text("ElectDz", style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            centerTitle: true,
          ),
        ),
        preferredSize: Size(MediaQuery.of(context).size.width, 45),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white, // Start color of the gradient
              Colors.blue, // End color of the gradient
            ],
          ),
        ),
        child: body, // Your original body widget
      ),
    );
  }
}
