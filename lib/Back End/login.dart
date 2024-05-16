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

  Future<void> _login() async{
    String key = keyController.text;
    if (key.length  != 64){
      Alert(
          context: context,
          type: AlertType.error,
          title:"Error in the Private key format",
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
      ).show();
      return;
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString("key", key);
    //move to home
    setState(() {
      Navigator.pushAndRemoveUntil(
        context,
        SlideRightRoute(
            page: SplashScreen()
        ),
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
        border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32.0)

          )
      ),
    );
    final loginButton = Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: Colors.blue,
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        onPressed: _login,
        child: Text("Login",
            textAlign: TextAlign.center,
            style: style),
      ),
    );

    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                   Colors.blue,
                   Colors.white,
                ],
              )
          ),
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 155.0,
                  child: Image.asset(
                    'assets/wallet1.png'
                  ),
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
    );
  }
}