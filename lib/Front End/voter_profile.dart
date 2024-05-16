import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'home_page.dart';
import 'package:mrtdeg/Front End//Container.dart';
import 'data_save.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrtdeg/Back End/splash.dart';

class VoterProfilePage extends StatefulWidget {
  final MrtdData mrtdData;
  final Uint8List? rawHandSignatureData;
  final bool isVotingStarted; // Add this line


  VoterProfilePage({required this.mrtdData, this.rawHandSignatureData,
  this.isVotingStarted = false, // Add this line
  });

  @override
  _VoterProfilePageState createState() => _VoterProfilePageState();
}

class _VoterProfilePageState extends State<VoterProfilePage> {
  bool _isVisible = true; // State to manage visibility of profile details

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            _isVisible ? _profileDetails() : Container(),
            _isVisible ? _signatureSection() : Container(),
            SizedBox(height: 40),
            _startVotingButton(),
            SizedBox(height: 20),
          ],
        ),
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
            child: _detailsChip('Document Number', widget.mrtdData.dg1!.mrz.documentNumber),
            height: 50,
          ),
          glassmorphicContainer(
            context: context,
            child: _detailsChip('Date of Birth', DateFormat.yMd().format(widget.mrtdData.dg1!.mrz.dateOfBirth)),
            height: 50,
          ),
          glassmorphicContainer(
            context: context,
            child: _detailsChip('Nationality', widget.mrtdData.dg1!.mrz.nationality),
            height: 50,
          ),
          glassmorphicContainer(
            context: context,
            child: _detailsChip('Expires', DateFormat.yMd().format(widget.mrtdData.dg1!.mrz.dateOfExpiry)),
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
              child: Image.memory(
                widget.rawHandSignatureData!,
                fit: BoxFit.contain,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
        onPressed: () async {
          if (!widget.isVotingStarted) {
            await _saveProfile();
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SplashScreen(),
            ),
          );
        },
        child: Text(
          widget.isVotingStarted ? 'Start Voting' : 'Save & Start Voting',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
  Future<void> _saveProfile() async {
    var profileData = {
      'documentNumber': widget.mrtdData.dg1!.mrz.documentNumber,
      'firstName': widget.mrtdData.dg1!.mrz.firstName,
      'lastName': widget.mrtdData.dg1!.mrz.lastName,
      'dateOfBirth': DateFormat.yMd().format(widget.mrtdData.dg1!.mrz.dateOfBirth),
      'nationality': widget.mrtdData.dg1!.mrz.nationality,
      'dateOfExpiry': DateFormat.yMd().format(widget.mrtdData.dg1!.mrz.dateOfExpiry),
      'imageData': widget.mrtdData.dg2!.imageData,
      'signatureData': widget.rawHandSignatureData
    };

    final dbHelper = DatabaseHelper.instance;
    int id = await dbHelper.insertProfile(profileData);
    // Update shared preferences after saving the profile
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profileSaved', true);

    //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile saved with ID: $id')));
  }
}
