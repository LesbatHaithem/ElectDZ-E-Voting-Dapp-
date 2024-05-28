import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrtdeg/Back%20End/qr.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'blockchain.dart';
import 'login.dart';
import 'flow.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class NoBlockChainScreen extends StatefulWidget {
  @override
  _NoBlockChainScreenState createState() => _NoBlockChainScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkKey(context));
  }

  void _checkKey(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? key = prefs.getString('key');
    String? contract = prefs.getString('contract');
    print([key, contract]);
    Future.delayed(Duration(seconds: 2), () async {
      if (contract == null) {
        setState(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QRScreen()),
          );
        });
      } else if (key == null) {
        setState(() {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
          );
        });
      } else if (await Blockchain().check() == false) {
        setState(() {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => NoBlockChainScreen()),
                (Route<dynamic> route) => false,
          );
        });
      } else {
        setState(() {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => FlowScreen()),
                (Route<dynamic> route) => false,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend the body behind the app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make the app bar transparent
        elevation: 0, // Remove the app bar shadow
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.5, // Adjust the opacity for fading effect
              child: Image.asset(
                'assets/voterpage.png', // Your background image asset
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Container(
              // decoration: BoxDecoration(
              //   gradient: LinearGradient(
              //     begin: Alignment.bottomCenter,
              //     end: Alignment.topCenter,
              //     colors: [Colors.blue.shade800, Colors.blue.shade200],
              //   ),
              // ),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 400.0,
                      child: SvgPicture.asset(
                        'assets/Splash-logo.svg', // Replace with your logo image path
                        width: 400,
                        height: 400,
                      ),
                    ),
                    SizedBox(height: 5.0),
                    SizedBox(
                      height: 50.0,
                      child: Lottie.asset('assets/splash.json', width: 300),
                    ),
                    SizedBox(height: 1.0),
                    Container(
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.cyanAccent],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.lightBlueAccent.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 30,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 40,
                              fontFamily: 'Times New Roman',
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  color: Colors.lightBlueAccent,
                                  blurRadius: 10,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                WavyAnimatedText(
                                  "Electdz",
                                  speed: Duration(milliseconds: 300),
                                ),
                              ],
                              isRepeatingAnimation: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 7.0),
                    Text(
                      "Welcome to the future of voting",
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
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

class _NoBlockChainScreenState extends State<NoBlockChainScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Blockchain blockchain = Blockchain();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkConnection() async {
    _controller.forward();
    Future.delayed(Duration(seconds: 3), () async {
      if (await blockchain.check() == true) {
        setState(() {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => FlowScreen()),
                (Route<dynamic> route) => false,
          );
        });
      } else {
        print("No Connection");
        _controller.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.white,
                Colors.blue,
              ],
            ),
          ),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 250.0,
                  child: Image.asset('assets/no-signal.png'),
                ),
                SizedBox(height: 5.0),
                Text(
                  "No Blockchain connection",
                  style: TextStyle(fontSize: 40, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40.0),
                Container(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_controller.isAnimating || _controller.isCompleted) {
                        _controller.reset();
                      }
                      _checkConnection();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Background color
                      foregroundColor: Colors.white, // Text color
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      "Retry",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
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
