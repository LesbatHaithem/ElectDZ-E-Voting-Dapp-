import 'dart:io';
import 'package:lottie/lottie.dart';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrtdeg/Back End/splash.dart';
import 'package:mrtdeg/Back End/utils.dart';
import 'Gradientbutton.dart';



class QRScreen extends StatefulWidget {
  @override
  _QRScreenState createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0, color: Colors.white);
  final keyController = TextEditingController();
  bool canMove = true;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  bool process(String? addr) {
    bool success = false;
    setState(() {
      if (addr != null && addr.length == 42) {
        SharedPreferences.getInstance().then((sp) {
          sp.setString("contract", addr);
          Navigator.pushAndRemoveUntil(
            context,
            SlideRightRoute(page: SplashScreen()),
                (Route<dynamic> route) => false,
          );
        });
        success = true; // Set success to true if the address is valid
      } else {
        Alert(
          context: context,
          type: AlertType.error,
          title: "Address not valid",
          desc: "Insert or scan a valid contract", // Updated to use 'desc' for description text
          style: AlertStyle(
            animationType: AnimationType.grow,
            isCloseButton: false,
            isOverlayTapDismiss: false,
            overlayColor: Colors.black54,
            alertBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: BorderSide(
                color: Colors.white, // Red accent to match the error theme
                width: 2,
              ),
            ),
            titleStyle: TextStyle(
              color: Colors.black, // Red accent for error titles
              fontWeight: FontWeight.bold,
            ),
            descStyle: TextStyle(
              fontSize: 16,
              color: Colors.black, // Keeping description text readable
            ),
          ),
        ).show().then((value) {
          controller!.resumeCamera();
          canMove = true;
          // Add any additional logic that needs to be executed after the alert is dismissed
        });

        success = false; // Keep success as false if the address is not valid
      }
    });
    return success;
  }

  void _onQRViewCreated(QRViewController controller){
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (canMove == false)
        return;
      try {
        controller.pauseCamera();
      } catch(error) {
        canMove = false;
      }
      process(scanData.code);
    });
  }

  void _manualInput(){
    TextEditingController text_addr = TextEditingController();

    Alert(
      context: context,
      title: "Enter SmartContract Address",
      style: AlertStyle(
        animationType: AnimationType.fromTop,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        descStyle: TextStyle(fontWeight: FontWeight.bold),
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
      content: Column(
        children: [
          TextField(
            controller: text_addr,
            decoration: InputDecoration(
              labelText: 'Address',
              labelStyle: TextStyle(color: Colors.black), // Enhanced label style
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(color: Colors.blue, width: 2), // Enhanced border style
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
        ],
      ),
      buttons: [
        DialogButton(
          onPressed: () {
           canMove==false;  // Adjusted for proper Dart syntax
              Navigator.pop(context);
              process(text_addr.text);

          },
          child: Text(
              "Connect",
              style: TextStyle(color: Colors.white, fontSize: 20)
          ),
          color: Colors.blue, // Enhanced button color to match your theme
          radius: BorderRadius.circular(20.0),
        )
      ],
    ).show();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(  // Added SingleChildScrollView
        child: Container(
          height: MediaQuery.of(context).size.height,  // Ensure it fills the screen
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.white, Colors.blue],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,  // Allows the column to size itself to its children
            children: <Widget>[
              Expanded(
                flex: 5,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),

              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text('         Scan QR Code',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).colorScheme.onBackground,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,),
                            ),
                          ),
                          Lottie.asset('assets/QR_Code.json', width: 80),
                        ],
                      ),
                      GradientButton(
                        text: "Enter Manually",
                        onPressed: _manualInput,  // The function to execute when the button is pressed
                        width: 200,  // Adjust the width based on your UI design needs, or use MediaQuery for full width
                        height: 50,  // Standard touch target height
                        // Assuming your GradientButton's default gradient and other styles are set within the button class
                      )
                      ,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
