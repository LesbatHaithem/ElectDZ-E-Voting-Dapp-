import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:mrtdeg/Back%20End/splash.dart';
import 'package:mrtdeg/Back%20End/utils.dart';

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

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!canMove) return;
      try {
        controller.pauseCamera();
      } catch (error) {
        canMove = false;
      }
      process(scanData.code);
    });
  }

  void _manualInput() {
    TextEditingController textAddr = TextEditingController();

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
            controller: textAddr,
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
            Navigator.pop(context);
            process(textAddr.text);
          },
          child: Text(
            "Connect",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          color: Colors.blue, // Enhanced button color to match your theme
          radius: BorderRadius.circular(20.0),
        ),
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
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
          Positioned(
            top: 30,
            left: 30,
            child: IconButton(
              icon: Icon(Icons.input, size: 30, color: Colors.white),
              onPressed: _manualInput,
            ),
          ),
          Center(
            child: Opacity(
              opacity: 0.2, // Adjusted opacity
              child: Lottie.asset(
                'assets/QR_Code.json',
                width: 400, // Increased size
                height: 400, // Increased size
                fit: BoxFit.cover,
                animate: true,
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Scan QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
