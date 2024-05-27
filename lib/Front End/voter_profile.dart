import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'home_page.dart';
import 'package:mrtdeg/UI/Container.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:mrtdeg/firebase/authenticate_user/authenticate_user_page.dart';

class VoterProfilePage extends StatefulWidget {
  final MrtdData mrtdData;
  final Uint8List? rawHandSignatureData;
  final bool isVotingStarted;

  VoterProfilePage({required this.mrtdData, this.rawHandSignatureData, this.isVotingStarted = false});

  @override
  _VoterProfilePageState createState() => _VoterProfilePageState();
}

class _VoterProfilePageState extends State<VoterProfilePage> {
  bool _isVisible = true;
  bool _isSavePressed = false;
  bool _isStartPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '${widget.mrtdData.dg1?.mrz.firstName} ${widget.mrtdData.dg1?.mrz.lastName}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () => _showFullSizeImage(context, widget.mrtdData.dg2!.imageData!),
          child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: CircleAvatar(
              backgroundImage: MemoryImage(widget.mrtdData.dg2!.imageData!),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/voterpage.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 110),
                _profileDetails(),
                _signatureSection(),
                SizedBox(height: 80),
                _startVotingButton(),
                SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullSizeImage(BuildContext context, Uint8List imageData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: MemoryImage(imageData),
              fit: BoxFit.contain,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _profileDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Column(
        children: [
          glassmorphicContainer(
            context: context,
            child: _detailsChip('Document Number', _isVisible ? widget.mrtdData.dg1!.mrz.documentNumber : '******'),
            height: 50,
          ),
          glassmorphicContainer(
            context: context,
            child: _detailsChip('Date of Birth', _isVisible ? DateFormat.yMd().format(widget.mrtdData.dg1!.mrz.dateOfBirth) : '******'),
            height: 50,
          ),
          glassmorphicContainer(
            context: context,
            child: _detailsChip('Nationality', _isVisible ? widget.mrtdData.dg1!.mrz.nationality : '******'),
            height: 50,
          ),
          glassmorphicContainer(
            context: context,
            child: _detailsChip('Expires', _isVisible ? DateFormat.yMd().format(widget.mrtdData.dg1!.mrz.dateOfExpiry) : '******'),
            height: 50,
          ),
        ],
      ),
    );
  }

  Widget _signatureSection() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('Signature', style: Theme.of(context).textTheme.titleLarge),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 20.0),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: _isVisible
                  ? Image.memory(
                widget.rawHandSignatureData!,
                fit: BoxFit.contain,
              )
                  : ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Image.memory(
                  widget.rawHandSignatureData!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsChip(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _startVotingButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            widget.isVotingStarted ? _isStartPressed = true : _isSavePressed = true;
          });

          Future.delayed(Duration(milliseconds: 300), () async {
            setState(() {
              widget.isVotingStarted ? _isStartPressed = false : _isSavePressed = false;
            });

            if (!widget.isVotingStarted) {
              await _saveProfile();
            }

            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => SplashScreen(),
            //   ),
            // );
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: 60,
          width: 240,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(50),
            boxShadow: (widget.isVotingStarted ? _isStartPressed : _isSavePressed)
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
              widget.isVotingStarted ? 'Start Voting' : 'Save & Start Voting',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    var profileData = {
      'firstName': widget.mrtdData.dg1!.mrz.firstName,
      'lastName': widget.mrtdData.dg1!.mrz.lastName,
      'image': base64Encode(widget.mrtdData.dg2!.imageData!), // Encoding image to base64 string
    };

    // Save to Firestore
    FirebaseFirestore.instance.collection('users').add(profileData).then((docRef) {
      print("User data saved to Firestore with ID: ${docRef.id}");
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AuthenticateUserPage(),
        ),
      );
    }).catchError((error) {
      print("Failed to save user data: $error");
    });
  }
}
