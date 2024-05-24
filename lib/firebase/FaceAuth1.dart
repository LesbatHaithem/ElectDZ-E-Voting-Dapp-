import 'package:mrtdeg/firebase/authenticate_user/authenticate_user_page.dart';
import 'package:mrtdeg/firebase/common/custom_button.dart';
import 'package:mrtdeg/firebase/constants/colors.dart';
import 'package:mrtdeg/firebase/register_user/enter_password_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


class FaceAuth extends StatelessWidget {
  const FaceAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: scaffoldClr,
        appBarTheme: AppBarTheme(
          backgroundColor: appBarColor,
          foregroundColor: primaryWhite,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 24,
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldClr,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Face Authentication',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  color: textColor,
                ),
              ),
              SizedBox(height: 40),
              CustomButton(
                label: 'Register User',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EnterPasswordPage(),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              CustomButton(
                label: 'Authenticate User',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AuthenticateUserPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}