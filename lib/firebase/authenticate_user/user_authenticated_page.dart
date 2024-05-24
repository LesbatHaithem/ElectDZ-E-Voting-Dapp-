import 'package:flutter/material.dart';
import 'package:mrtdeg/Back%20End/splash.dart';

import '../constants/colors.dart';


class UserAuthenticatedPage extends StatelessWidget {
  final String Firstname;

  const UserAuthenticatedPage({
    required this.Firstname,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: ClipRRect(
          child: AppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            title: Text('ElectDz', style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
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
                color: Theme.of(context).colorScheme.onBackground,
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
                  'hey ${Firstname} !',
              textAlign: TextAlign.center,
              style:  TextStyle(

                color: Theme.of(context).colorScheme.primary,
                fontSize: 30,
              ),
            ),
            Text(
              'You have been successfully Authenticated !',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 300,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return SplashScreen();
                        },
                      ),
                    );
                  },
                  child: Text('continue'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2.0,
                      ), // Border color and width
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
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
