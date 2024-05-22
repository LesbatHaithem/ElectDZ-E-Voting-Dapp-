import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'home_page.dart';

class NfcApp extends StatefulWidget {
  const NfcApp({super.key});

  @override
  _NfcAppState createState() => _NfcAppState();
}

class _NfcAppState extends State<NfcApp> {
  final LocalAuthentication auth = LocalAuthentication();
  GlobalKey _scanButtonKey = GlobalKey();
  bool _isPressed = false;
  bool _isAuthenticating = false;
  String _authorized = 'Please authenticate';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeShowShowcase());
  }

  void maybeShowShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    final showShowcase = prefs.getBool('showScanShowcase') ?? true;

    if (showShowcase) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ShowCaseWidget.of(context).startShowCase([_scanButtonKey]);
        await prefs.setBool('showScanShowcase', false);
      }
    }
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
            builder: (context) => MrtdHomePage(),
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

  void _handlePress() {
    _authenticate();
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
            Lottie.asset(
              'assets/NFC.json',
              width: 300,
              height: 300,
              fit: BoxFit.fill,
            ),
            SizedBox(height: 70),
            Text(
              'Scan your ID Card First',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            SizedBox(height: betweenElementsPadding),
            Text(
              'Click on Scan Document below to start scanning',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            SizedBox(height: edgePadding),
            Showcase(
              key: _scanButtonKey,
              description: 'Tap here to scan your document',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _isAuthenticating ? null : _handlePress,
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
                          'Scan Document',
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
            SizedBox(height: edgePadding),
            Center(
              child: Text(
                _authorized,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
