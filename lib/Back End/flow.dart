import 'package:enhance_stepper/enhance_stepper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back End/blockchain.dart';
import 'package:mrtdeg/Back End/vote.dart';
import 'package:mrtdeg/Back End/splash.dart';
import 'package:mrtdeg/Back End/winner.dart';
import'package:mrtdeg/Back End/Confirm.dart';
import 'Gradientbutton.dart';

class FlowScreen extends StatefulWidget {
  @override
  _FlowScreenState createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  Blockchain blockchain = Blockchain();
  AlertStyle animation = AlertStyle(animationType: AnimationType.grow);
  String quorum_text = "Loading Quorum...";
  double quorum_circle = 0.0;
  int step = -1;
  late bool isMayor;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateQuorum());
  }

  Future<void> _mayorOrSayonara() async {
    Alert(
      context: context,
      title:"Asking the winner...",
      buttons: [],
      style: AlertStyle(
        animationType: AnimationType.fromTop,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        descStyle: TextStyle(fontWeight: FontWeight.bold),
        animationDuration: Duration(milliseconds: 400),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40.0),
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
    Future.delayed(Duration(milliseconds:500), () async =>
    {
      blockchain.query("mayor_or_sayonara", []).then((value) =>
      {
        Navigator.of(context).pop(),
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Winner()),
        )
      }).catchError((error) {
        Navigator.of(context).pop();
        if (error.toString().contains("has already been")) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Winner()),
          );
          return null;
        }
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


  // Future<void> _updateQuorum() async {
  //   Alert(
  //     context: context,
  //     title:"Getting election status...",
  //     buttons: [],
  //     style: AlertStyle(
  //       animationType: AnimationType.fromTop,
  //       isCloseButton: false,
  //       isOverlayTapDismiss: false,
  //       descStyle: TextStyle(fontWeight: FontWeight.bold),
  //       animationDuration: Duration(milliseconds: 400),
  //       alertBorder: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(40.0),
  //         side: BorderSide(
  //           color: Colors.white, // Added a red accent border to match your theme
  //           width: 2,
  //         ),
  //       ),
  //       titleStyle: TextStyle(
  //         color: Colors.black, // Making sure the title matches the theme
  //       ),
  //     ),
  //   ).show();
  //   Future.delayed(Duration(milliseconds:500), () async => {
  //     blockchain.queryView("get_status", [await blockchain.myAddr()]).then((value) => {
  //       Navigator.of(context).pop(),
  //       if (value[3] == false){
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => Winner()),
  //         )
  //       },
  //       setState(() {
  //         quorum_text = (value[0] != value[1])
  //             ? (value[0]-value[1]).toString() + " votes to quorum (" + value[1].toString() + "/" + value[0].toString() + ")"
  //             : "Quorum reached! (Total voters: "+value[0].toString()+")";
  //         quorum_circle = (value[1]/value[0]);
  //         print(value);
  //         if (value[4]){ //addr is a candidate
  //           step = 3;
  //           if (!value[3]) { //elections closed
  //             step = 4;
  //           }
  //         } else if (!value[3]){ //elections open
  //           step = 2;
  //         } else if (value[1] == value[0]) { //quorum reached
  //           if (value[2]) { //envelope not open
  //             step = 1;
  //           } else { //envelope opened
  //             step = 2;
  //           }
  //         } else { //start
  //           step = 0;
  //         }
  //       })
  //     }).catchError((error){
  //       Navigator.of(context).pop();
  //       Alert(
  //           context: context,
  //           type: AlertType.error,
  //           title:"Error",
  //           desc: blockchain.translateError(error),
  //           style: animation
  //       ).show();
  //     })
  //   });
  // }
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
            desc: blockchain.translateError(error),
            style: animation
        ).show();
      })
    });
  }


  Widget buildBody(BuildContext context) {
    List<EnhanceStep> steps;
    if (step == -1) {
      return Text("Loading...");
    } else if (step > 2) {
      // Steps for mayor to deposit funds and declare winner
      steps = [
        EnhanceStep(
          isActive: step >= 3,
          title: Text('Deposit some funds', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'You can deposit some funds to encourage people to vote for you',
                style: TextStyle(fontSize: 14.0, color: Colors.white),
              ),


              // ElevatedButton.icon(
              //   icon: Icon(Icons.account_balance_wallet),
              //   label: Text("Deposit"),
              //   // onPressed:  ,
              //   style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
              // ),
            ],
          ),
        ),
        EnhanceStep(
          isActive: step >= 4,
          title: Text('Declare the winner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Once everyone has confirmed their vote you can ask to declare the winner',
                style: TextStyle(fontSize: 14.0, color: Colors.white),
              ),
              SizedBox(height: 24.0),
              ElevatedButton.icon(
                icon: Icon(Icons.gavel),
                label: Text("Ask to declare"),
                onPressed: step == 4 ? _mayorOrSayonara : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
              ),
            ],
          ),
          icon: Icon(Icons.gavel),
        ),
      ];
    } else {
      // General steps for voting process
      steps = [
        EnhanceStep(
          isActive: step >= 0,
          title: Text(' Send your vote', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Every vote you cast overwrites the previous one',
                style: TextStyle(fontSize: 14.0, color: Colors.white),
              ),
              SizedBox(height: 24.0),
              GradientButton(
                text: "Vote",
                onPressed: step == 0 ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Vote(isConfirming: false)),
                ) : null,
                icon: Icon(Icons.how_to_vote, color: Colors.black),  // Ensure the icon color matches the text color for consistency
                width: 200,  // Optional: Adjust the width as necessary
                height: 50,  // Standard touch target height
              ),
            ],
          ),
        ),
        EnhanceStep(
          isActive: step >= 1,
          title: Text('Confirm your vote', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'When the quorum is reached you can confirm your vote',
                style: TextStyle(fontSize: 14.0, color: Colors.white),
              ),
              SizedBox(height: 24.0),
              GradientButton(
                text: "Confirm",
                icon: Icon(Icons.check_circle_outline, color: Colors.black),  // Add the icon with the appropriate color
                onPressed: step == 1 ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Confirm(isConfirming: true)),  // Corrected typo "Confrim" to "Confirm"
                ) : null,
                width: 200,  // Optional width setting
                height: 50,  // Standard button height
              )
            ],
          ),
        ),
        EnhanceStep(
          isActive: step >= 2,
          title: Text('Declare the winner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Once everyone has confirmed their vote you can ask to declare the winner',
                style: TextStyle(fontSize: 14.0, color: Colors.white),
              ),
              SizedBox(height: 24.0),
              GradientButton(
                text: "Ask to declare",
                icon: Icon(Icons.gavel, color: Colors.black),  // Specify the icon and its color
                onPressed: step == 2 ? _mayorOrSayonara : null,  // Conditionally enable the button
                width: 200,  // Optionally specify the width, or use double.infinity for full width
                height: 50,  // Standard touch target height
              )
            ],
          ),
        ),
      ];
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.blue.shade800, Colors.blue.shade200],
        ),
      ),
      child: EnhanceStepper(
        type: StepperType.vertical,
        physics: ClampingScrollPhysics(),
        currentStep: step > 2 ? step - 3 : step, // Adjust index based on conditional steps
        onStepTapped: (index) {
          setState(() {
            step = step > 2 ? index + 3 : index;
          });
        },
        steps: steps,
        onStepContinue: step < steps.length - 1 ? () => setState(() { step++; }) : null,
        onStepCancel: step > 0 ? () => setState(() { step--; }) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: PreferredSize(
          child: Container(
            child: AppBar(
              title: Text("ElectDz",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,

                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.background,
              elevation: 0.0,
              centerTitle: true,
              actions: <Widget>[
                Padding(
                    padding: EdgeInsets.only(right: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        blockchain.logout();
                        setState(() {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => SplashScreen()),
                                (Route<dynamic> route) => false,
                          );
                        });
                      },
                      child: Icon(
                        Icons.logout,
                        size: 26.0,
                      ),
                    )
                ),
              ],
            ),
          ),
          preferredSize:  Size(MediaQuery.of(context).size.width, 45),
        ),
        body: Column(
            children:[
              Card(
                elevation: 5,  // Gives a shadow effect under the card
                shape: RoundedRectangleBorder(  // Ensures that the Card remains rounded
                  borderRadius: BorderRadius.circular(10.0),  // Adjust radius as needed
                ),
                child: Container(
                  width: 400,  // Specify the width of the Card
                  height: 65,  // Specify the height of the Card
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),  // Match this radius with the Card's radius
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,  // Gradient starts at the top left corner
                      end: Alignment.bottomRight,  // Gradient ends at the bottom right corner
                      colors: [
                        Colors.white,  // Starting color of the gradient
                        Colors.blue,  // Ending color of the gradient
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
              Expanded(
                  child: buildBody(context)
              )
            ]
        )
    );
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('isMayor', isMayor));
  }
}