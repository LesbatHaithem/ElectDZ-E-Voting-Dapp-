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
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 60), // Add some space below the AppBar

            SizedBox(height: 20),
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
                child: SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
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
                                          builder: (context) => UserAuthenticatedPage(Firstname: user.firstName),
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
                    child: Text('Authenticate'),
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
            SizedBox()
          ],
        ),
      ),
    );
  }
}
