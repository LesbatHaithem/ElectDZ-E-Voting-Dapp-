import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back%20End/blockchain.dart';
import 'package:mrtdeg/Back%20End/splash.dart';
import 'package:mrtdeg/Back%20End/utils.dart';
import 'package:mrtdeg/Back%20End/winnerModel.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:mrtdeg/Back%20End/Gradientbutton.dart';
import 'package:mrtdeg/Back%20End/flow.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:ui'; // Import for the blur effect

class Winner extends StatefulWidget {
  @override
  _WinnerState createState() => _WinnerState();
}

class _WinnerState extends State<Winner> {
  Blockchain blockchain = Blockchain();

  late ConfettiController _controllerCenter;
  List<WinnerModel> groups = [WinnerModel("Loading", BigInt.zero, "Loading", "", 0)];
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
          BigInt totalVotes = BigInt.zero;
          for (int i = 0; i < value[1].length; i++) {
            totalVotes += BigInt.parse(value[1][i].toString());
          }
          for (int i = 0; i < value[0].length; i++) {
            String groupAddr = value[0][i].toString();
            BigInt votes = BigInt.parse(value[1][i].toString());
            String groupName = value[2][i].toString();
            String pictureUrl = value[3][i].toString();
            double percentage = (votes / totalVotes * 100).toDouble();

            groups.add(WinnerModel(groupAddr, votes, groupName, pictureUrl, percentage));
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
                icon: Icon(Icons.logout, color: Colors.black),
                width: 200,
                height: 50,
              ),
            ],
          ),
        ),
      );
    } else if (valid == true) {
      body = Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Top Winner
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  color: Colors.yellow,
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: Text("👑", style: TextStyle(fontSize: 25)),
                              title: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  groups[0].groupName!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              subtitle: Text("Votes: ${groups[0].votes} (${groups[0].percentage!.toStringAsFixed(2)}%)"),
                            ),
                            Container(
                              height: 350,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(30),
                                  bottomRight: Radius.circular(30),
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(groups[0].pictureUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Ranked List
                Expanded(
                  child: MasonryGridView.builder(
                    gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 4.0,
                    itemCount: groups.length - 1,
                    itemBuilder: (context, index) {
                      final group = groups[index + 1];
                      String leadingIcon = "🏅";
                      if (index == 0) {
                        leadingIcon = "🥈";
                      } else if (index == 1) {
                        leadingIcon = "🥉";
                      }
                      return Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        color: Colors.white,
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    leading: Text(leadingIcon, style: TextStyle(fontSize: 25)),
                                    title: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(
                                        group.groupName!,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    subtitle: Text("Votes: ${group.votes} (${group.percentage!.toStringAsFixed(2)}%)"),
                                  ),
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(30),
                                        bottomRight: Radius.circular(30),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(group.pictureUrl!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
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
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controllerCenter,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: true,
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
        preferredSize: Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: AppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              title: Text('Winner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => FlowScreen()),
                      (Route<dynamic> route) => false,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white,
              Colors.blue,
            ],
          ),
        ),
        child: body,
      ),
    );
  }
}
