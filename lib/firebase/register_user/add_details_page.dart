import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../common/custom_button.dart';
import '../common/custom_text_form_field.dart';
import '../common/snack_bars.dart';
import '../models/user.dart';

class AddDetailsPage extends StatefulWidget {
  final String image;
  const AddDetailsPage({
    required this.image,
    super.key,
  });

  @override
  State<AddDetailsPage> createState() => _AddDetailsPageState();
}

class _AddDetailsPageState extends State<AddDetailsPage> {
  final nameController = TextEditingController();
  final formFieldKey = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Details"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextFormField(
                formFieldKey: formFieldKey,
                controller: nameController,
                hintText: 'Name',
                validate: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Enter a name';
                  }

                  return null;
                },
              ),
              SizedBox(height: 20),
              CustomButton(
                label: 'Register Now',
                onTap: () {
                  if (formFieldKey.currentState!.validate()) {
                    FocusScope.of(context).unfocus();

                    final name = nameController.text;

                    final userId = Uuid().v4();

                    final newUser = User(
                      id: userId,
                      Firstname: name,
                      image: widget.image,
                    );

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .set(
                          newUser.toJson(),
                        )
                        .then((value) {
                      Navigator.of(context).pop();

                      successSnackBar(context, 'Registration success!');

                      Future.delayed(Duration(seconds: 1), () {
                        Navigator.of(context)
                          ..pop()
                          ..pop()
                          ..pop();
                      });
                    }).catchError((e) {
                      Navigator.of(context).pop();

                      errorSnackBar(context, 'Registration Failed!');
                    });
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
