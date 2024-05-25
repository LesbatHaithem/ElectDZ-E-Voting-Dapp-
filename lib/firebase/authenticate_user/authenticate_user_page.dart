import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_api/face_api.dart' as regula;
import '../common/capture_face_view.dart';
import '../common/snack_bars.dart';
import '../models/user.dart';
import 'scanning_animation/animated_view.dart';
import 'user_authenticated_page.dart';

class AuthenticateUserPage extends StatefulWidget {
  const AuthenticateUserPage({super.key});

  @override
  State<AuthenticateUserPage> createState() => _AuthenticateUserPageState();
}

class _AuthenticateUserPageState extends State<AuthenticateUserPage> {
  final image1 = regula.MatchFacesImage();
  final image2 = regula.MatchFacesImage();

  bool canAuthenticate = false;
  bool faceMatched = false;
  bool isMatching = false;

  String similarity = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: ClipRRect(
          child: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              'ElectDz',
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
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 60), // Add some space below the AppBar

            SizedBox(height: 30),
            Stack(
              children: [
                CaptureFaceView(
                  onImageCaptured: (imageBytes) {
                    setState(() {
                      image1.bitmap = base64Encode(imageBytes);
                      image1.imageType = regula.ImageType.PRINTED;
                      canAuthenticate = true;
                    });
                  },
                ),
                if (isMatching)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 110),
                      child: AnimatedView(),
                    ),
                  ),
              ],
            ),
            if (canAuthenticate)
              Padding(
                padding: const EdgeInsets.only(top: 20), // Added top padding
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isMatching = true;
                    });

                    FirebaseFirestore.instance
                        .collection('users')
                        .get()
                        .then((snap) async {
                      if (snap.docs.isNotEmpty) {
                        for (var doc in snap.docs) {
                          try {
                            final user = User.fromJson(doc.data() ?? {});

                            if (user.image == null || user.image.isEmpty) {
                              print('User image is null or empty');
                              continue;
                            }

                            image2.bitmap = user.image;
                            image2.imageType = regula.ImageType.PRINTED;

                            var request = regula.MatchFacesRequest();
                            request.images = [image1, image2];

                            var value = await regula.FaceSDK.matchFaces(jsonEncode(request));
                            var response = regula.MatchFacesResponse.fromJson(json.decode(value));

                            if (response != null && response.results != null) {
                              var str = await regula.FaceSDK.matchFacesSimilarityThresholdSplit(jsonEncode(response.results), 0.75);
                              var split = regula.MatchFacesSimilarityThresholdSplit.fromJson(json.decode(str));

                              if (split != null && split.matchedFaces.isNotEmpty) {
                                final matchedFace = split.matchedFaces[0];
                                if (matchedFace != null && matchedFace.similarity != null) {
                                  similarity = (matchedFace.similarity! * 100).toStringAsFixed(2);
                                  print('Similarity: $similarity'); // Debug line

                                  if (double.parse(similarity) > 90.00) {
                                    faceMatched = true;
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => UserAuthenticatedPage(
                                          Firstname: user.firstName,
                                          lastname: user.lastName,
                                        ),
                                      ),
                                    );
                                    break;
                                  }
                                }
                              }
                            }
                          } catch (e) {
                            print('Error processing user: $e'); // Debug line
                          }
                        }

                        setState(() {
                          isMatching = false;
                        });

                        if (!faceMatched) {
                          errorSnackBar(context, 'You are Not the Owner Of this ID card \n If you insist take another Picture and Try again ! ');
                        }
                      } else {
                        errorSnackBar(context, 'Sorry retry');
                      }
                    }).catchError((error) {
                      setState(() {
                        isMatching = false;
                      });
                      print('Error during authentication: $error'); // Debug line
                      errorSnackBar(context, 'Error during authentication. Please try again.');
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: 70,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: isMatching
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
                        child: Text(
                          'Authenticate',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox()
          ],
        ),
      ),
    );
  }
}
