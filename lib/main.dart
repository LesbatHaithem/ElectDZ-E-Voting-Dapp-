import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:logging/logging.dart';
import 'package:mrtdeg/Front End/finger_print.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrtdeg/Front End/data_save.dart';
import 'package:mrtdeg/Front End/MrtdDataStorage.dart';
import 'package:mrtdeg/Front End/voter_profile.dart';
import 'package:mrtdeg/Back End/splash.dart';
import 'package:mrtdeg/Front End/nfc_app.dart';

void main() {
  if (kDebugMode) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.loggerName} ${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  runApp(ShowCaseWidget(
    builder: Builder(builder: (context) => const MainApp()),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elect-DZ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 21,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontStyle: FontStyle.italic,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 2.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 2.0,
                color: Color.fromARGB(125, 0, 0, 255),
              ),
            ],
          ),
        ),
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _opacityAnimation;
  Animation<Offset>? _positionAnimation;
  GlobalKey _one = GlobalKey();

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeShowShowcase());
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller!);
    _positionAnimation = Tween<Offset>(begin: Offset(-1.0, 0.0), end: Offset(0.0, 0.0)).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeOut,
      ),
    );

    _controller!.forward();
  }

  void maybeShowShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    final showShowcase = prefs.getBool('showWelcomeShowcase') ?? true;

    if (showShowcase) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ShowCaseWidget.of(context).startShowCase([_one]);
        await prefs.setBool('showWelcomeShowcase', false);
      }
    }
  }

  void _handlePress() {
    setState(() {
      _isPressed = true;
    });

    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _isPressed = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NfcApp(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                FadeTransition(
                  opacity: _opacityAnimation!,
                  child: SlideTransition(
                    position: _positionAnimation!,
                    child: Text(
                      "Welcome to Elect-DZ E-Voting dApp",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Lottie.asset(
                  'assets/GetStarted.json',
                  width: 430,
                  height: 400,
                  fit: BoxFit.fill,
                ),
                SizedBox(height: 50),
                Showcase(
                  key: _one,
                  description: 'Tap here to start',
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: _handlePress,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          height: 70,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(50),
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
                              width:1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Get Started',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
