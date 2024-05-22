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
    const double betweenElementsPadding = 25.0;

    return Scaffold(
      extendBodyBehindAppBar: true, // Extend the body behind the app bar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: Colors.transparent, // Make the app bar transparent
          title: Text(
            'ElectDZ',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0, // Remove the app bar shadow
          centerTitle: true,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.3, // Adjust the opacity for fading effect
              child: Image.asset(
                'assets/background.png', // Your background image asset
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: edgePadding).copyWith(top:20.0), // Add top padding to avoid content being obscured by the app bar
            child: ListView(
              children: [
                SizedBox(height:10),
                Lottie.asset(
                  'assets/NFC.json',
                  width: 400,
                  height: 300,
                  fit: BoxFit.fill,
                ),
                SizedBox(height: 50),
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
        ],
      ),
    );
  }
}
