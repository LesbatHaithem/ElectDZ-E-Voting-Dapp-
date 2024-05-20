import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:logging/logging.dart';
import 'package:mrtdeg/Front End//finger_print.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrtdeg/Front End//data_save.dart';
import 'package:mrtdeg/Front End//MrtdDataStorage.dart';
import 'package:mrtdeg/Front End//voter_profile.dart';
import 'package:mrtdeg/Back End/splash.dart';
import 'package:mrtdeg/Back End/Gradientbutton.dart';


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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,

      body: Padding(
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
              width: 400,
              height: 400,
              fit: BoxFit.fill,
            ),
            SizedBox(height: 50),
            Showcase(
              key: _one,
              description: 'Tap here to start',
              child: Container(
                width: 250,
                child: GradientButton(
                  text: "Get Started",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SplashScreen()),
                    );
                  },
                  width: 200,  // You can adjust this width to fit your UI design
                  height: 50,  // Standard touch target height
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  // If your GradientButton supports custom padding, add here. Otherwise, you'll need to adjust inside the class
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),  // Add padding directly if supported
                  borderRadius: 30.0,  // Approximation of a StadiumBorder
                )

              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
