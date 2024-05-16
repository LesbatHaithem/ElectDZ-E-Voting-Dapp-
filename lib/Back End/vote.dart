import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:mrtdeg/Back End/blockchain.dart';
import 'package:web3dart/json_rpc.dart';

class Vote extends StatefulWidget {
  final bool isConfirming;

  Vote({Key? key, required this.isConfirming}) : super(key: key);

  @override
  _VoteState createState() => _VoteState();
}

class _VoteState extends State<Vote> {
  Blockchain blockchain = Blockchain();
  AlertStyle animation = AlertStyle(animationType: AnimationType.grow);

  final text_souls = TextEditingController();
  final text_secret = TextEditingController();

  List<dynamic> candidates = [];
  List<dynamic> candidates_locked = [];
  List<dynamic> deposited = [];
  int _selected = -1;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateCandidates());
        print("Candidates loaded: $candidates");

  }
  Future<void> _updateCandidates() async {
    Alert(
        context: context,
        title:"Getting candidates...",
        buttons: [],
      style: AlertStyle(
        animationType: AnimationType.fromTop,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        descStyle: TextStyle(fontWeight: FontWeight.bold,fontFamily: 'Times new Roman',),
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
      blockchain.queryView("get_candidates", []).then((value) => {
        Navigator.of(context).pop(),
        setState(() {
          print("Raw data from blockchain: $value");
          value[0].removeWhere((item) => item.toString() == "0x0000000000000000000000000000000000000000");
          value[1].removeWhere((item) => item.toString() == "0x0000000000000000000000000000000000000000");
          value[2].removeWhere((item) => item == BigInt.zero);
          candidates = value[0];
          candidates_locked = value[1];
          deposited = value[2];
          print("Filtered candidates: $candidates");
        })
      }).catchError((error){
        Navigator.of(context).pop();
        Alert(
            context: context,
            type: AlertType.error,
            title:"Error",
            desc: (error is RPCError) ? blockchain.translateError(error) : "?"+error.toString()
        ).show();
      })





    });
  }
  bool checkSelection(){
    if (_selected == -1){
      Alert(
          context: context,
          type: AlertType.error,
          title:"Error",
          desc: (widget.isConfirming)
              ? "Please select the mayor you voted"
              : "Please select the mayor you want to vote",
        style: AlertStyle(
          animationType: AnimationType.fromBottom,
          isCloseButton: false,
          isOverlayTapDismiss: false,
          descStyle: TextStyle(fontWeight: FontWeight.bold,
            ),
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
      return false;
    }
    return true;
  }
  Future<void> _openVote() async {
    if (!checkSelection())
      return;

    List<dynamic> args = [BigInt.parse(text_secret.text), candidates[_selected]];
    Alert(
        context: context,
        title:"Confirming your vote...",
        buttons: [],
        style: AlertStyle(
          animationType: AnimationType.grow,
          isCloseButton: false,
          isOverlayTapDismiss: false,
        )
    ).show();
    Future.delayed(Duration(milliseconds:500), () => {
      blockchain.query("open_envelope", args, wei: BigInt.parse(text_souls.text)).then((value) => {
        Navigator.of(context).pop(),
        Alert(
            context: context,
            type: AlertType.success,
            title:"OK",
            desc: "Your vote has been Confirmed !",
            style: animation
        ).show()
      }).catchError((error){
        Navigator.of(context).pop();
        Alert(
            context: context,
            type: AlertType.error,
            title:"Error",
            desc: blockchain.translateError(error),
            style: animation
        ).show();
      })
    });
  }
  Future<void> _sendVote() async {
    if (!checkSelection())
      return;

    List<dynamic> args = [blockchain.encodeVote(BigInt.parse(text_secret.text), candidates[_selected], BigInt.parse(text_souls.text))];
    Alert(
        context: context,
        title:"Sending your vote...",
        buttons: [],
        style: AlertStyle(
          animationType: AnimationType.grow,
          isCloseButton: false,
          isOverlayTapDismiss: false,
        )
    ).show();
    Future.delayed(Duration(milliseconds:500), () => {
      blockchain.query("cast_envelope", args).then((value) => {
        Navigator.of(context).pop(),
        Alert(
            context: context,
            type: AlertType.success,
            title:"OK",
            desc: "Your vote has been casted!",
            style: animation

        ).show()
      }).catchError((error){
        Navigator.of(context).pop();
        Alert(
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Center(
        child: Container(
          margin: const EdgeInsets.only(top: 0.0),
          child: SingleChildScrollView(
            child: SizedBox(
              height:700,

              child: Column(
                children: <Widget>[
                  Text(
                    (widget.isConfirming)
                        ? 'Confirm Previous Vote'
                        : 'Vote The New Mayor',
                    style: TextStyle(fontSize: 30),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 15.0, bottom: 0.0),
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
                                ? Colors.lightBlueAccent
                                : Colors.white,
                            child: ListTile(
                              leading: ExcludeSemantics(
                                child: SvgPicture.string(
                                  Jdenticon.toSvg("${candidates[index]}"),
                                  fit: BoxFit.fill,
                                  height: 50,
                                  width: 50,
                                ),
                              ),
                              title: Text(
                                 // index == 0 ? "Guessoum Abdennour \n${candidates[index]}" :
                                 // index == 1 ? "Lesbat Haithem \n${candidates[index]}" :
                                  "${candidates[index]}",
                                  style: TextStyle(color: (_selected == index)
                                      ? Colors.white
                                      : Colors.black,
                                  )
                              ),
                              subtitle: Text(
                                  'Deposited: ' + blockchain.soulsUnit(deposited[index])
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Text(
                      "How many ETH ?"
                  ),
                  SizedBox(
                    height:130,
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Column(
                        children: [
                          TextField(
                            decoration: new InputDecoration(hintText: "Amount"),
                            keyboardType: TextInputType.number,
                            controller: text_souls,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                          SizedBox(
                            height:10,
                          ),
                          Wrap(
                              children:[
                                InputChip(
                                    label: Text('5 ETH'),
                                    onSelected: (bool) => {text_souls.text = "5000000000000000000"}
                                ),
                                SizedBox(width:8),
                                InputChip(
                                    label: Text('1 ETH'),
                                    onSelected: (bool) => {text_souls.text = "1000000000000000000"}
                                ),
                                SizedBox(width:8),
                                InputChip(
                                    label: Text('0.5 ETH'),
                                    onSelected: (bool) => {text_souls.text = "500000000000000000"}
                                ),
                                SizedBox(width:8),
                                InputChip(
                                    label: Text('0.01 ETH'),
                                    onSelected: (bool) => {text_souls.text = "10000000000000000"}
                                ),
                              ]
                          ),
                        ]
                    ),
                  ),
                  Text(
                      (widget.isConfirming)
                          ? "Enter your secret"
                          : "Create your secret"
                  ),
                  SizedBox(
                    height:40,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      decoration: new InputDecoration(hintText: "Secret in numbers"),
                      keyboardType: TextInputType.number,
                      controller: text_secret,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  ElevatedButton(
                      onPressed:
                      (widget.isConfirming)
                          ? _openVote
                          : _sendVote
                      ,
                      child: Text(
                          (widget.isConfirming)
                              ? "Confirm Vote"
                              : "Send Vote"
                      )
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

  }
}