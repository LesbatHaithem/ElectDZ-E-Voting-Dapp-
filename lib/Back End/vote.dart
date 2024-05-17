import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back End/blockchain.dart';
import 'package:web3dart/json_rpc.dart';
import'Gradientbutton.dart';


class Vote extends StatefulWidget {
  final bool isConfirming;

  Vote({Key? key, required this.isConfirming}) : super(key: key);

  @override
  _VoteState createState() => _VoteState();
}

class _VoteState extends State<Vote> {
  final _formKey = GlobalKey<FormState>();
  final text_secret = TextEditingController();

  String quorum_text = "Loading Quorum...";
  double quorum_circle = 0.0;
  int step = -1;


  Blockchain blockchain = Blockchain();
  List<dynamic> candidates = [];
  List<dynamic> firstNames = [];
  List<dynamic> lastNames = [];
  int _selected = -1;

  bool _isConfirmButtonDisabled = false;  // Added this line

  void initState(){
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateCandidates());
    print("Candidates loaded: $candidates");

  }


  Future<void> _updateCandidates() async {
    var alert = Alert(
      context: context,
      title: "Getting candidates...",
      desc: "Please wait while we fetch the candidate details.",
      buttons: [],
      style: AlertStyle(
        animationType: AnimationType.grow,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        overlayColor: Colors.white,
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
    );
    alert.show();

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Just for delay
      print("Attempting to fetch candidates...");
      var value = await blockchain.queryView("getCandidateNames", []);
      print("Fetched data: $value"); // Log the raw returned data
      Navigator.of(context).pop(); // Close the alert after getting response
      if (value != null && value.length >= 3) {
        setState(() {
          candidates = value[0];
          firstNames = value[1];
          lastNames = value[2];
          print("Candidates: $candidates");
          print("First Names: $firstNames");
          print("Last Names: $lastNames");
        });
      } else {
        print("Error: Data received is not as expected.");
        throw Exception('Received data is not in the expected format or is incomplete.');
      }
    } catch (error) {
      print("Error fetching candidates: $error");
      Navigator.of(context).pop(); // Ensure to close the alert in case of error
      var errorMessage = (error is RPCError) ? blockchain.translateError(error) : "An unknown error occurred: $error";
      Alert(
          context: context,
          type: AlertType.error,
          title: "Error",
          desc: errorMessage
      ).show();
    }
  }



  bool checkSelection(){
    if (_selected == -1){
      Alert(
        context: context,
        type: AlertType.error,
        title:"Error",
        desc: (widget.isConfirming)
            ? "Please select the Mayor you voted"
            : "Please select the Mayor you want to vote",
        style: AlertStyle(
          animationType: AnimationType.grow,
          isCloseButton: false,
          isOverlayTapDismiss: false,
          overlayColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
          alertBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
            side: BorderSide(
              color:Theme.of(context).colorScheme.secondary,
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
      title:"Getting election status...",
      buttons: [],
      style: AlertStyle(
        animationType: AnimationType.grow,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        overlayColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
          side: BorderSide(
            color:Theme.of(context).colorScheme.secondary,
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
    Future.delayed(Duration(milliseconds:500), () async => {
      blockchain.queryView("get_status", [await blockchain.myAddr()]).then((value) => {
        Navigator.of(context).pop(),
        if (value[3] == false){
        },
        setState(() {
          quorum_text = (value[0] != value[1])
              ? (value[0]-value[1]).toString() + " Elections open (" + value[1].toString() + "/" + value[0].toString() + ")"
              : "Elections closed ";
          quorum_circle = (value[1]/value[0]);
          print(value);
          if (value[4]){ //addr is a candidate
            step = 3;
            if (!value[3]) { //elections closed
              step = 4;
            }
          } else if (!value[3]){ //elections open
            step = 2;
          } else if (value[1] == value[0]) { //quorum reached
            if (value[2]) { //envelope not open
              step = 1;
            } else { //envelope opened
              step = 2;
            }
          } else { //start
            step = 0;
          }
        })
      }).catchError((error){
        Navigator.of(context).pop();
        Alert(
          context: context,
          type: AlertType.error,
          title:"Error",
          desc: blockchain.translateError(error),
          style: AlertStyle(
            animationType: AnimationType.grow,
            isCloseButton: false,
            isOverlayTapDismiss: false,
            overlayColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
            alertBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
              side: BorderSide(
                color:Theme.of(context).colorScheme.secondary,
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
      })
    });
  }

  Future<void> _sendVote() async {
    if (!checkSelection())
      return;

    List<dynamic> args = [blockchain.encodeVote(BigInt.parse(text_secret.text), candidates[_selected],)];

    Alert(
      context: context,
      title:"Sending your vote...",
      buttons: [],
      style: AlertStyle(
        animationType: AnimationType.grow,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        overlayColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
          side: BorderSide(
            color:Theme.of(context).colorScheme.secondary,
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
    Future.delayed(const Duration(milliseconds:500), () => {
      blockchain.query("cast_envelope", args).then((value) => {
        Navigator.of(context).pop(),
        Alert(
            style: AlertStyle(
              animationType: AnimationType.grow,
              isCloseButton: false,
              isOverlayTapDismiss: false,
              overlayColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
              alertBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
                side: BorderSide(
                  color:Theme.of(context).colorScheme.secondary,
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
            title:"OK",
            desc: "Your vote has been casted!"
        ).show()
      }).catchError((error){
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
                  color:Theme.of(context).colorScheme.secondary,
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
            title:"Error",
            desc: (error is NoSuchMethodError)
                ? error.toString()
                : error.toString()//blockchain.translateError(error)
        ).show();
      })
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
          padding: const EdgeInsets.fromLTRB(0 , 0,16,0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: AppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              title: Text('Vote', style: TextStyle(fontWeight: FontWeight.bold,color:Colors.black)),
              elevation: 0,
              centerTitle: true,
              actions: [
                // Lottie.asset(
                //   'assets/voting_animation.json' ,
                // ),
              ],
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
                          style: TextStyle(fontSize: 20 , fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                        child: ListView.builder(
                          itemCount: candidates.length,
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: (){
                                setState(() {
                                  _selected = index;
                                });
                              },
                              child: Card(
                                color: (_selected == index)
                                    ? Colors.blue.withOpacity(0.9)  // This will make the card blue when selected
                                    : Theme.of(context).colorScheme.background.withOpacity(1),
                                child: Padding(
                                  padding: EdgeInsets.all(8.0), // Add padding to the card
                                  child: Center( // Center the content horizontally and vertically
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            image: DecorationImage(
                                              image: AssetImage("assets/candidate.png"),
                                              fit: BoxFit.cover, // Use cover to maintain aspect ratio
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 20), // Add some space between image and text
                                        Column(

                                          children: [

                                            Text(
                                              "${firstNames[index]} ${lastNames[index]}",
                                              style: TextStyle(
                                                color: (_selected == index)
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Secret code',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary), // Change color here
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black), // Change color here
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue, width: 2.0), // Change color and width here
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
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 200,  // Set the width of the button here, can be parameterized
                                child: GradientButton(
                                  text: "Cast Vote",  // Set the button text to "Cast Vote"
                                  onPressed: () {  // Assuming you have a similar logic to disable the button
                                    _sendVote();  // Function to execute when the button is pressed
                                  },
                                  width: 200,  // Adjust the width to match your UI design
                                  height: 50,  // Standard touch target height
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
                            elevation: 5,  // Gives a shadow effect under the card
                            shape: RoundedRectangleBorder(  // Ensures that the Card remains rounded
                              borderRadius: BorderRadius.circular(10.0),  // Adjust radius as needed
                            ),
                            child: Container(
                              width: 300,  // Specify the width of the Card
                              height: 70,  // Specify the height of the Card
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