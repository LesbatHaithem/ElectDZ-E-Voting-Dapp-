import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back End/blockchain.dart';
import 'package:mrtdeg/Back End/splash.dart';
import 'package:mrtdeg/Back End/utils.dart';
import 'package:mrtdeg/Back End/winnerModel.dart';
import 'package:web3dart/json_rpc.dart';

class Winner extends StatefulWidget {
  @override
  _WinnerState createState() => _WinnerState();
}

class _WinnerState extends State<Winner> {
  Blockchain blockchain = Blockchain();

  late ConfettiController _controllerCenter;
  List<WinnerModel> candidates = [new WinnerModel("Loading",BigInt.zero,BigInt.zero)];
  bool? valid;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateCandidates());
    _controllerCenter = ConfettiController(duration: const Duration(seconds: 5));
  }


  Future<void> _updateCandidates() async {
    Alert(
        context: context,
        title:"Getting results...",
        buttons: [],
      style: AlertStyle(
        animationType: AnimationType.fromTop,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        descStyle: TextStyle(fontWeight: FontWeight.bold,fontFamily: 'Times new Roman'),
        animationDuration: Duration(milliseconds: 400),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: Colors.white, // Added a red accent border to match your theme
            width: 2,
          ),
        ),
        titleStyle: TextStyle(
          color: Colors.black, // Making sure the title matches the theme
        ),
      ),
    ).show();
    Future.delayed(Duration(milliseconds:500), () => {
      blockchain.queryView("get_results", []).then((value) {
        Navigator.of(context).pop();  // Ensure navigator is popped in both success and error cases
        print(value);
        setState(() {
          candidates = [];
          for (int i = 0; i < value[0].length; i++) {
            candidates.add(new WinnerModel(value[0][i].toString(), value[1][i], value[2][i]));
          }
          candidates.sort((a, b) {
            if (a.souls == b.souls) {
              return b.votes!.compareTo(a.votes!);
            } else {
              return b.souls!.compareTo(a.souls!);
            }
          });
          valid = true;
        });
        _controllerCenter.play();
        Future.delayed(Duration(seconds: 5), () {
          _controllerCenter.stop();
        });
      }).catchError((error) {
        Navigator.of(context).pop();  // This ensures that any UI blocking elements are removed even on error
        print('Error fetching results: $error');
        String errorMessage = (error is RPCError) ? blockchain.translateError(error) : error.toString();
        if (error.toString().contains("invalid")) {
          errorMessage = "Elections are invalid (there was a tie).";
          setState(() {
            valid = false;
          });
        }
        Alert(
            context: context,
            type: AlertType.error,
            title: "Error",
            desc: errorMessage
        ).show();
      },)
    });
  }


  @override
  Widget build(BuildContext context) {
// Initialize 'body' to a default widget to ensure it's never null.
    Widget body = Center(
      child: Text("Unknown state",
        style: TextStyle(fontSize: 40, color: Colors.red),
      ),
    );
    if (valid == null){
      body = Center(
        child: Container(
          margin: const EdgeInsets.only(top: 30.0),
          child: Column(
            children: <Widget>[
              Text("Loading...",
                style: TextStyle(fontSize: 40),
              )
            ],
          ),
        ),
      );
    } else if (valid == false){
      body = Center(
        child: Container(
          margin: const EdgeInsets.only(top: 30.0),
          child: Column(
            children: <Widget>[
              Text("Invalid Elections",
                style: TextStyle(fontSize: 40, color: Colors.white),
              ),
              Text("There was a tie, so no new Mayor.!",
                  textAlign: TextAlign.center
              ),
              SizedBox(height: 170),
              Image.asset("assets/sayonara.png",
                  width: MediaQuery.of(context).size.width * 0.8
              ),
              SizedBox(height: 50),
              ElevatedButton(
                  onPressed: () => {
                    blockchain.logout(),
                    setState(() {
                      Navigator.pushAndRemoveUntil(
                        context,
                        SlideRightRoute(
                            page: SplashScreen()
                        ),

                            (Route<dynamic> route) => false,
                      );
                    })
                  },
                  child: Text("Log Out")
              ),
            ],
          ),
        ),
      );
    } else if (valid == true){
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
                          leading: Text(
                              "👑",
                              style: TextStyle(fontSize: 25)
                          ),
                          trailing: SvgPicture.string(
                            Jdenticon.toSvg("${candidates[0].addr}"),
                            fit: BoxFit.fill,
                            height: 50,
                            width: 50,
                          ),
                          title: Text("${candidates[0].addr}"),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                      height:15
                  ),
                  Text(
                      "Ranked List",
                      style: TextStyle(fontSize: 40)
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                    child: ListView.builder(
                      itemCount: candidates.length,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            leading: ExcludeSemantics(
                              child: Stack(
                                  children: [
                                    SvgPicture.string(
                                      Jdenticon.toSvg("${candidates[index].addr}"),
                                      fit: BoxFit.fill,
                                      height: 50,
                                      width: 50,
                                    ),
                                    Text(
                                        (() {
                                          switch(index){
                                            case 0: return "🥇";
                                            case 1: return "🥈";
                                            case 2: return "🥉";
                                          }
                                          return "";
                                        }()),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(fontSize: 30)
                                    ),
                                  ]
                              ),
                            ),
                            title: Text(
                                "${candidates[index].addr}",
                                style: TextStyle(color: Colors.black)
                            ),
                            subtitle: Text(' 🗳 Votes: ' + candidates[index].votes.toString()),
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
              blastDirectionality: BlastDirectionality
                  .explosive, // don't specify a direction, blast randomly
              shouldLoop:
              true, // start again as soon as the animation is finished
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.red,
                Colors.yellowAccent,
                Colors.purple
              ],
            ),
          ),
        ],
      );
    }
    //render
    return Scaffold(
        backgroundColor: (valid == false)
            ? Colors.red
            : Colors.white,
        appBar: PreferredSize(
          child: Container(
            child: AppBar(
              title: Text("ElectDz",style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,

              ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              centerTitle: true,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
          ),
          preferredSize: Size(MediaQuery.of(context).size.width, 45),
        ),
        body: body
    );

  }
}