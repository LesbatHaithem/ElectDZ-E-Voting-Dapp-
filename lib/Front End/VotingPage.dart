import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrtdeg/main.dart';
import 'package:mrtdeg/Front End//voter_profile.dart';
import 'package:mrtdeg/Front End//home_page.dart';

class VotingPage extends StatefulWidget {
  final MrtdData mrtdData;
  final Uint8List? rawHandSignatureData;

  VotingPage({required this.mrtdData ,this.rawHandSignatureData});

  @override
  _VotingPageState createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  @override
  void initState() {
    super.initState();
    authenticate();
  }

  Future<void> authenticate() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to authenticate',
      );
      if (!authenticated) {
        Navigator.of(context).pop(); // Go back if not authenticated
      }
    } on PlatformException catch (e) {
      print('Error using local authentication: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            print("Navigating to VoterProfilePage from title...");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VoterProfilePage(mrtdData: widget.mrtdData
                ,rawHandSignatureData: widget.rawHandSignatureData,
                isVotingStarted: true
              )),            );
          },
          child: Text(
            '${widget.mrtdData.dg1?.mrz.firstName ?? ''} ${widget.mrtdData.dg1?.mrz.lastName ?? ''}',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            print("Navigating to VoterProfilePage from leading icon...");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VoterProfilePage(mrtdData: widget.mrtdData
                  ,rawHandSignatureData: widget.rawHandSignatureData,
                isVotingStarted: true,
              )),
            );
          },
          child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: MemoryImage(widget.mrtdData.dg2!.imageData!),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, context),
            itemBuilder: (BuildContext context) => {
              'Notifications': Icons.notifications,
              'About': Icons.info,
              'Sign Out': Icons.exit_to_app,
            }.entries.map((entry) {
              return PopupMenuItem<String>(
                value: entry.key,
                child: ListTile(
                  leading: Icon(entry.value),
                  title: Text(entry.key),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Center(
        child: Text('Voting Page Content Here'),
      ),
    );
  }

  void _handleMenuAction(String choice, BuildContext context) {
    switch (choice) {
      case 'Notifications':
        print('Notifications Clicked');
        break;
      case 'About':
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("About"),
            content: Text("This is the voting app to handle your electoral needs.?"),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
        break;
      case 'Sign Out':
        _signOut(context);
        break;
    }
  }

  void _signOut(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSignedIn', false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => WelcomePage()),
          (Route<dynamic> route) => false,
    );
  }
}
