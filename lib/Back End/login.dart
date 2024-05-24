import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrtdeg/Back End/splash.dart';
import 'package:mrtdeg/Back End/utils.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextStyle style = TextStyle(fontSize: 20.0, color: Colors.white);
  final keyController = TextEditingController();
  bool _isPressed = false;

  Future<void> _login() async {
    String key = keyController.text;
    if (key.length != 64) {
      Alert(
        context: context,
        type: AlertType.error,
        title: "Error in the Private key format",
        style: AlertStyle(
          animationType: AnimationType.fromTop,
          isCloseButton: false,
          isOverlayTapDismiss: false,
          descStyle: TextStyle(fontWeight: FontWeight.bold),
          animationDuration: Duration(milliseconds: 400),
          alertBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(
              color: Colors.white,
              width: 2,
            ),
          ),
          titleStyle: TextStyle(
            color: Colors.black,
          ),
        ),
      ).show();
      return;
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString("key", key);
    setState(() {
      Navigator.pushAndRemoveUntil(
        context,
        SlideRightRoute(page: SplashScreen()),
            (Route<dynamic> route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final passwordField = TextField(
      controller: keyController,
      obscureText: true,
      style: style,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        hintText: "Wallet Private Key",
        hintStyle: style,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
    );

    final loginButton = Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isPressed = true;
          });

          Future.delayed(Duration(milliseconds: 300), () {
            setState(() {
              _isPressed = false;
            });
            _login();
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: 60,
          width: MediaQuery.of(context).size.width * 0.8,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(50),
            boxShadow: _isPressed
                ? [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.5),
                spreadRadius: 20,
                blurRadius: 30,
              )
            ]
                : [],
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              'Login',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background4.png', // Replace with your background image asset
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.blue.withOpacity(0.5),
                    Colors.white.withOpacity(0.5),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(36.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 155.0,
                      child: Image.asset('assets/wallet.png'),
                    ),
                    SizedBox(height: 25.0),
                    passwordField,
                    SizedBox(height: 35.0),
                    loginButton,
                    SizedBox(height: 15.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
