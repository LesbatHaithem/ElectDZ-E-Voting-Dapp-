import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../common/custom_button.dart';
import '../common/custom_text_form_field.dart';
import '../common/snack_bars.dart';
import 'register_user_page.dart';

class EnterPasswordPage extends StatelessWidget {
  EnterPasswordPage({super.key});

  final TextEditingController passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Password"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextFormField(
                controller: passwordCtrl,
                hintText: 'Password',
              ),
              SizedBox(height: 20),
              CustomButton(
                label: 'Continue',
                onTap: () async {
                  if (passwordCtrl.text.isEmpty) {
                    errorSnackBar(context, 'Password cannot be empty');
                    return;
                  }

                  try {
                    DocumentSnapshot snap = await FirebaseFirestore.instance
                        .collection('password')
                        .doc('8EHgfb3vj4TSjQTauXJV')
                        .get();

                    if (snap.exists) {
                      var data = snap.data() as Map<String, dynamic>?;

                      if (data != null && data.containsKey('password')) {
                        final password = data['password'];

                        if (passwordCtrl.text == password) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RegisterUserPage(),
                            ),
                          );
                        } else {
                          errorSnackBar(context, 'Wrong Password');
                        }
                      } else {
                        errorSnackBar(context, 'Password data is missing');
                      }
                    } else {
                      errorSnackBar(context, 'Document does not exist');
                    }
                  } catch (e) {
                    errorSnackBar(context, 'An error occurred: $e');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
