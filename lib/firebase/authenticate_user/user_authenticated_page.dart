import 'package:flutter/material.dart';
import 'package:mrtdeg/Back%20End/splash.dart';

import '../constants/colors.dart';

class UserAuthenticatedPage extends StatefulWidget {
  final String Firstname;
  final String lastname;

  const UserAuthenticatedPage({
    required this.Firstname,
    required this.lastname,
    super.key,
  });

  @override
  _UserAuthenticatedPageState createState() => _UserAuthenticatedPageState();
}

class _UserAuthenticatedPageState extends State<UserAuthenticatedPage> {
  bool _isPressed = false;

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
          builder: (context) => SplashScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: ClipRRect(
          child: AppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            title: Text(
              'ElectDz',
              style: TextStyle(
                color:Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 0,
            centerTitle: true,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Successfully authenticated',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: primaryWhite,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check,
                  color: primaryWhite,
                  size: 48,
                ),
              ),
            ),
            Text(
              'Hey ${widget.Firstname} ${widget.lastname}!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 30,
              ),
            ),
            Text(
              'You have been successfully Authenticated!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
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
                    ),
                  ]
                      : [],
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Continue',
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
    );
  }
}
