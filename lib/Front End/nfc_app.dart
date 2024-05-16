import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class NfcApp extends StatefulWidget {
  const NfcApp({super.key});

  @override
  _NfcAppState createState() => _NfcAppState();
}

class _NfcAppState extends State<NfcApp> {
  GlobalKey _scanButtonKey = GlobalKey();

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

  @override
  Widget build(BuildContext context) {
    const double edgePadding = 32.0;
    const double betweenElementsPadding = 24.0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          //automaticallyImplyLeading: false,  // This prevents the AppBar from showing a back button

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
            SizedBox(height: 40),
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
              child: SizedBox(
                width: 300,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MrtdHomePage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                  child: Text(
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
            SizedBox(height: edgePadding),
          ],
        ),
      ),
    );
  }
}
