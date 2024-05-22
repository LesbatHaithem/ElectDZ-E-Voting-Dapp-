import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mrtdeg/Front End/nfc_app.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FingerPrintPage extends StatefulWidget {
  const FingerPrintPage({Key? key}) : super(key: key);

  @override
  State<FingerPrintPage> createState() => _FingerPrintPageState();
}

class _FingerPrintPageState extends State<FingerPrintPage> {
  final LocalAuthentication auth = LocalAuthentication();
  String _authorized = 'Please authenticate';
  bool _isAuthenticating = false;
  final GlobalKey _buttonKey = GlobalKey();

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _showCaseIfFirstTime();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating...';
        _isPressed = true;
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Please place your thumb on the fingerprint sensor',
      );
      setState(() {
        _authorized = authenticated ? 'Success' : 'Try again';
      });
      if (authenticated) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NfcApp(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _authorized = 'Authentication Error: $e';
      });
    } finally {
      setState(() {
        _isAuthenticating = false;
        _isPressed = false;
      });
    }
  }

  Future<void> _showCaseIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      ShowCaseWidget.of(context).startShowCase([_buttonKey]);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double edgePadding = 32.0;
    const double betweenElementsPadding = 24.0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          title: Text(
            'ElectDZ',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: edgePadding),
        child: ListView(
          children: [
            SizedBox(height: 40),
            Text(
              'Fingerprint Authentication',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            SizedBox(height: 40),
            Text(
              'You\'re almost there.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            SizedBox(height: betweenElementsPadding),
            Text(
              'Press the button to finalize authentication and access the account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            SizedBox(height: edgePadding),
            Center(
              child: Image.asset(
                'assets/fingerprint.png',
                color: Colors.black,
                height: 100,
                width: 100,
              ),
            ),
            SizedBox(height: edgePadding * 2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(_authorized),
                  SizedBox(height: edgePadding * 2),
                  Showcase(
                    key: _buttonKey,
                    title: 'Authenticate Button',
                    description: 'Tap here to authenticate your fingerprint.',
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: _isAuthenticating ? null : _authenticate,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            height: 60,
                            width: 300,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: _isPressed
                                  ? [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.5),
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
                              child: _isAuthenticating
                                  ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                                  : Text(
                                'Authenticate',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
            SizedBox(height: edgePadding * 2),
          ],
        ),
      ),
    );
  }
}
