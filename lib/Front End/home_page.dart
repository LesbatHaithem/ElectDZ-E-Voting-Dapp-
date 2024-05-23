import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '/screen/jpeg2000_converter.dart';
import '/dmrtd_lib/src/lds/df1/efdg2.dart';
import '/dmrtd_lib/src/com/nfc_provider.dart';
import '/dmrtd_lib/src/crypto/aa_pubkey.dart';
import '/dmrtd_lib/src/lds/df1/dg.dart';
import '/dmrtd_lib/src/lds/df1/efcom.dart';
import '/dmrtd_lib/extensions.dart';
import '/dmrtd_lib/src/lds/df1/efdg1.dart';
import '/dmrtd_lib/src/lds/df1/efdg10.dart';
import '/dmrtd_lib/src/lds/df1/efdg11.dart';
import '/dmrtd_lib/src/lds/df1/efdg12.dart';
import '/dmrtd_lib/src/lds/df1/efdg13.dart';
import '/dmrtd_lib/src/lds/df1/efdg14.dart';
import '/dmrtd_lib/src/lds/df1/efdg15.dart';
import '/dmrtd_lib/src/lds/df1/efdg16.dart';
import '/dmrtd_lib/src/lds/df1/efdg3.dart';
import '/dmrtd_lib/src/lds/df1/efdg4.dart';
import '/dmrtd_lib/src/lds/df1/efdg5.dart';
import '/dmrtd_lib/src/lds/df1/efdg6.dart';
import '/dmrtd_lib/src/lds/df1/efdg7.dart';
import '/dmrtd_lib/src/lds/df1/efdg8.dart';
import '/dmrtd_lib/src/lds/df1/efdg9.dart';
import '/dmrtd_lib/src/lds/df1/efsod.dart';
import '/dmrtd_lib/src/lds/efcard_access.dart';
import '/dmrtd_lib/src/lds/efcard_security.dart';
import '/dmrtd_lib/src/lds/mrz.dart';
import '/dmrtd_lib/src/lds/tlv.dart';
import '/dmrtd_lib/src/passport.dart';
import '/dmrtd_lib/src/proto/dba_keys.dart';
import'voter_profile.dart';
import'package:showcaseview/showcaseview.dart';
import'package:shared_preferences/shared_preferences.dart';


class MrtdData {
  EfCardAccess? cardAccess;
  EfCardSecurity? cardSecurity;
  EfCOM? com;
  EfSOD? sod;
  EfDG1? dg1;
  EfDG2? dg2;
  EfDG3? dg3;
  EfDG4? dg4;
  EfDG5? dg5;
  EfDG6? dg6;
  EfDG7? dg7;
  EfDG8? dg8;
  EfDG9? dg9;
  EfDG10? dg10;
  EfDG11? dg11;
  EfDG12? dg12;
  EfDG13? dg13;
  EfDG14? dg14;
  EfDG15? dg15;
  EfDG16? dg16;
  Uint8List? aaSig;

}





final Map<DgTag, String> dgTagToString = {
  EfDG1.TAG: 'EF.DG1',
  EfDG2.TAG: 'EF.DG2',
  EfDG3.TAG: 'EF.DG3',
  EfDG4.TAG: 'EF.DG4',
  EfDG5.TAG: 'EF.DG5',
  EfDG6.TAG: 'EF.DG6',
  EfDG7.TAG: 'EF.DG7',
  EfDG8.TAG: 'EF.DG8',
  EfDG9.TAG: 'EF.DG9',
  EfDG10.TAG: 'EF.DG10',
  EfDG11.TAG: 'EF.DG11',
  EfDG12.TAG: 'EF.DG12',
  EfDG13.TAG: 'EF.DG13',
  EfDG14.TAG: 'EF.DG14',
  EfDG15.TAG: 'EF.DG15',
  EfDG16.TAG: 'EF.DG16'

};




String formatEfCom(final EfCOM efCom) {
  var str = "version: ${efCom.version}\n"
      "unicode version: ${efCom.unicodeVersion}\n"
      "DG tags:";

  for (final t in efCom.dgTags) {
    try {
      str += " ${dgTagToString[t]!}";
    } catch (e) {
      str += " 0x${t.value.toRadixString(16)}";
    }
  }
  return str;
}

String formatMRZ(final MRZ mrz) {
  return "MRZ\n"
      "Version: ${mrz.version}\n" +
      "Document Type: ${mrz.documentCode}\n" +
      "Document Number: ${mrz.documentNumber}\n" +
      "Country: ${mrz.country}\n" +
      "Nationality: ${mrz.nationality}\n" +
      "Name: ${mrz.firstName}\n" +
      "Surname: ${mrz.lastName}\n" +
      "Gender: ${mrz.gender}\n" +
      "Date of Birth: ${DateFormat.yMd().format(mrz.dateOfBirth)}\n" +
      "Date of Expiry: ${DateFormat.yMd().format(mrz.dateOfExpiry)}\n" ;
}

String formatDG2(final EfDG2 dg2) {
  return "DG2\n"
      "faceImageType ${dg2.faceImageType}\n" +
      "facialRecordDataLength ${dg2.facialRecordDataLength}\n" +
      "imageHeight ${dg2.imageHeight}\n" +
      "imageType: ${dg2.imageType}\n" +
      "lengthOfRecord ${dg2.lengthOfRecord}\n" +
      "numberOfFacialImages ${dg2.numberOfFacialImages}\n" +
      "poseAngle ${dg2.poseAngle}";
}

String convertToReadableFormat(String input) {
  if (input.isEmpty) {
    return input;
  }

  String readableText = input.replaceAll('_', ' ');

  return readableText;
}

String formatDG15(final EfDG15 dg15) {
  var str = "EF.DG15:\n"
      "AAPublicKey\n"
      "type: ";

  final rawSubPubKey = dg15.aaPublicKey.rawSubjectPublicKey();
  if (dg15.aaPublicKey.type == AAPublicKeyType.RSA) {
    final tvSubPubKey = TLV.fromBytes(rawSubPubKey);
    var rawSeq = tvSubPubKey.value;
    if (rawSeq[0] == 0x00) {
      rawSeq = rawSeq.sublist(1);
    }

    final tvKeySeq = TLV.fromBytes(rawSeq);
    final tvModule = TLV.decode(tvKeySeq.value);
    final tvExp = TLV.decode(tvKeySeq.value.sublist(tvModule.encodedLen));

    str += "RSA\n"
        "exponent: ${tvExp.value.hex()}\n"
        "modulus: ${tvModule.value.hex()}";
  } else {
    str += "EC\n    SubjectPublicKey: ${rawSubPubKey.hex()}";
  }
  return str;
}

String formatProgressMsg(String message, int percentProgress) {
  final p = (percentProgress / 20).round();
  final full = "🟢 " * p;
  final empty = "⚪️ " * (5 - p);
  return message + "\n\n" + full + empty;
}



class MrtdHomePage extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _MrtdHomePageState createState() => _MrtdHomePageState();
}

class _MrtdHomePageState extends State<MrtdHomePage> {
  var   _alertMessage   = "";
  final _log            = Logger("mrtdeg.app");
  var   _isNfcAvailable = false;
  var   _isReading      = false;
  final _mrzData   = GlobalKey<FormState>();

  // mrz data
  final _docNumber = TextEditingController();
  final _dob = TextEditingController(); // date of birth
  final _doe = TextEditingController(); // date of doc expiry

  MrtdData? _mrtdData;

  final NfcProvider _nfc = NfcProvider();
  // ignore: unused_field
  late Timer _timerStateUpdater;
  final _scrollController = ScrollController();
  static const MethodChannel platform = MethodChannel('image_channel');
  bool _showUserInstructions = true; // Initialize to false
  GlobalKey _showcaseKey = GlobalKey();
  Timer? _showcaseTimer;
  bool _showFAB = false;  // State to control visibility of the FAB
  bool _isPressed = false;
  bool _isFABPressed = false;




  @override
  void initState() {
    //docNumber = widget.mrzResult.documentNumber;

    //dob = convertDateTimeToDateString(widget.mrzResult.birthDate);

    //doe = convertDateTimeToDateString(widget.mrzResult.expiryDate);

    super.initState();

    @override
    void dispose() {
      super.dispose();
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    checkNfcAvailability();
    _timerStateUpdater = Timer.periodic(Duration(seconds: 3), (Timer t) => _initPlatformState());

    // Update platform state every 3 sec
    // _timerStateUpdater = Timer.periodic(const Duration(seconds: 3), (Timer t) {
    //   _initPlatformState();
    // });
  }

  /*Future<void> saveMrtdData(MrtdData mrtdData) async {
    final prefs = await SharedPreferences.getInstance();
    final String mrtdJson = jsonEncode(mrtdData.toJson());
    await prefs.setString('mrtdData', mrtdJson);*/


  Future<void> checkNfcAvailability() async {
    try {
      final bool isAvailable = await platform.invokeMethod('checkNfcAvailability');
      if (!isAvailable) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("NFC Disabled"),
            content: Text("NFC is disabled on your device. Please enable it in settings."),
            actions: <Widget>[
              TextButton(
                child: Text("Open Settings"),
                onPressed: () {
                  Navigator.of(context).pop();
                  platform.invokeMethod('openNFCSettings');
                },
              ),
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _log.warning("Failed to check NFC availability: ${e.toString()}");
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initPlatformState() async {
    bool isNfcAvailable;
    try {
      NfcStatus status = await NfcProvider.nfcStatus;
      isNfcAvailable = status == NfcStatus.enabled;
    } on PlatformException {
      isNfcAvailable = false;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    _isNfcAvailable = isNfcAvailable;
    setState(() {});
    if (_isNfcAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Couldn't access device NFC, please try again")));
    }
  }

  DateTime? _getDOBDate() {
    if(_dob.text.isEmpty) {
      return null;
    }
    return DateFormat.yMd().parse(_dob.text);
  }

  DateTime? _getDOEDate() {
    if(_doe.text.isEmpty) {
      return null;
    }
    return DateFormat.yMd().parse(_doe.text);
  }

  Uint8List? rawImageData;
  Uint8List? rawHandSignatureData;

  Future<String?> _pickDate(BuildContext context, DateTime firstDate, DateTime initDate, DateTime lastDate) async {
    final locale = Localizations.localeOf(context);
    final DateTime? picked = await showDatePicker(
        context: context,
        firstDate: firstDate,
        initialDate: initDate,
        lastDate: lastDate,
        locale: locale
    );

    if(picked != null) {
      return DateFormat.yMd().format(picked);
    }
    return null;
  }

  void _readMRTD() async {
    try {
      setState(() {
        _mrtdData = null;
        _alertMessage = "Waiting for Document tag ...";
        _isReading = true;
      });

      await _nfc.connect(
          iosAlertMessage: "Hold your phone near Biometric Document");
      final passport = Passport(_nfc);

      setState(() {
        _alertMessage = "Reading Document ...";
      });

      _nfc.setIosAlertMessage("Trying to read EF.CardAccess ...");
      final mrtdData = MrtdData();

      try {
        mrtdData.cardAccess = await passport.readEfCardAccess();
      } on PassportError {
        //if (e.code != StatusWord.fileNotFound) rethrow;
      }

      _nfc.setIosAlertMessage("Trying to read EF.CardSecurity ...");

      try {
        mrtdData.cardSecurity = await passport.readEfCardSecurity();
      } on PassportError {
        //if (e.code != StatusWord.fileNotFound) rethrow;
      }

      _nfc.setIosAlertMessage("Initiating session ...");
      final bacKeySeed = DBAKeys(_docNumber.text, _getDOBDate()!, _getDOEDate()!);
      await passport.startSession(bacKeySeed);

      _nfc.setIosAlertMessage(formatProgressMsg("Reading EF.COM ...", 0));
      mrtdData.com = await passport.readEfCOM();

      _nfc.setIosAlertMessage(formatProgressMsg("Reading Data Groups ...", 20));

      if (mrtdData.com!.dgTags.contains(EfDG1.TAG)) {
        mrtdData.dg1 = await passport.readEfDG1();
      }

      if (mrtdData.com!.dgTags.contains(EfDG2.TAG)) {
        mrtdData.dg2 = await passport.readEfDG2();
      }

      // To read DG3 and DG4 session has to be established with CVCA certificate (not supported).
      // if(mrtdData.com!.dgTags.contains(EfDG3.TAG)) {
      // mrtdData.dg3 = await passport.readEfDG3();
      // }

      // if(mrtdData.com!.dgTags.contains(EfDG4.TAG)) {
      // mrtdData.dg4 = await passport.readEfDG4();
      // }

      if (mrtdData.com!.dgTags.contains(EfDG5.TAG)) {
        mrtdData.dg5 = await passport.readEfDG5();
      }

      if (mrtdData.com!.dgTags.contains(EfDG6.TAG)) {
        mrtdData.dg6 = await passport.readEfDG6();
      }

      if (mrtdData.com!.dgTags.contains(EfDG7.TAG)) {
        mrtdData.dg7 = await passport.readEfDG7();

        String? imageHex = extractImageData(mrtdData.dg7!.toBytes().hex());

        Uint8List? decodeImageHex =
        Uint8List.fromList(List<int>.from(hex.decode(imageHex)));
        rawHandSignatureData = decodeImageHex;
      }

      // String? imageHex = extractImageData(handSign);

      // Uint8List? decodeImageHex =
      //     Uint8List.fromList(List<int>.from(hex.decode(imageHex)));
      // rawHandSignatureData = decodeImageHex;

      if (mrtdData.com!.dgTags.contains(EfDG8.TAG)) {
        mrtdData.dg8 = await passport.readEfDG8();
      }

      if (mrtdData.com!.dgTags.contains(EfDG9.TAG)) {
        mrtdData.dg9 = await passport.readEfDG9();
      }

      if (mrtdData.com!.dgTags.contains(EfDG10.TAG)) {
        mrtdData.dg10 = await passport.readEfDG10();
      }

      if (mrtdData.com!.dgTags.contains(EfDG11.TAG)) {
        mrtdData.dg11 = await passport.readEfDG11();
      }

      if (mrtdData.com!.dgTags.contains(EfDG12.TAG)) {
        mrtdData.dg12 = await passport.readEfDG12();
      }

      if (mrtdData.com!.dgTags.contains(EfDG13.TAG)) {
        mrtdData.dg13 = await passport.readEfDG13();
      }

      if (mrtdData.com!.dgTags.contains(EfDG14.TAG)) {
        mrtdData.dg14 = await passport.readEfDG14();
      }

      if (mrtdData.com!.dgTags.contains(EfDG15.TAG)) {
        mrtdData.dg15 = await passport.readEfDG15();
        _nfc.setIosAlertMessage(formatProgressMsg("Doing AA ...", 60));
        mrtdData.aaSig = await passport.activeAuthenticate(Uint8List(8));
      }

      if (mrtdData.com!.dgTags.contains(EfDG16.TAG)) {
        mrtdData.dg16 = await passport.readEfDG16();
      }

      _nfc.setIosAlertMessage(formatProgressMsg("Reading EF.SOD ...", 80));
      mrtdData.sod = await passport.readEfSOD();

      _mrtdData = mrtdData;

      _alertMessage = "";

      if (mrtdData.dg2?.imageData != null) {
        rawImageData = mrtdData.dg2?.imageData;
        tryDisplayingJpg();
        //await tryDisplayingJp2();
      }
      _scrollController.animateTo(300.0,
          duration: const Duration(milliseconds: 500), curve: Curves.ease);
      setState(() {});
    } on Exception catch (e) {
      final se = e.toString().toLowerCase();
      String alertMsg = "An error has occurred while reading Document!";
      if (e is PassportError) {
        if (se.contains("security status not satisfied")) {
          alertMsg =
          "Failed to initiate session with passport.\nCheck input data!";
        }
        _log.error("PassportError: ${e.message}");
      } else {
        _log.error(
            "An exception was encountered while trying to read Document: $e");
      }

      if (se.contains('timeout')) {
        alertMsg = "Timeout while waiting for Document tag";
      } else if (se.contains("tag was lost")) {
        alertMsg = "Tag was lost. Please try again!";
      } else if (se.contains("invalidated by user")) {
        alertMsg = "";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(se)));

      setState(() {
        _alertMessage = alertMsg;
      });
    } finally {
      if (_alertMessage.isNotEmpty) {
        await _nfc.disconnect(iosErrorMessage: _alertMessage);
      } else {
        await _nfc.disconnect(
            iosAlertMessage: formatProgressMsg("Finished", 100));
      }
      //startShowcaseTimer();  // Start the timer to show the showcase

      setState(() {
        _isReading = false;
      });
      startShowcaseTimer();  // Start the timer to show the showcase

    }

  }
  void startShowcaseTimer() {
    _showcaseTimer?.cancel();  // Cancel any existing timers
    _showcaseTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showFAB = true;  // Control the visibility of the FAB
        });

        // Introduce a slight delay to ensure the FAB is rendered
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            ShowCaseWidget.of(context).startShowCase([_showcaseKey]);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }
  bool _disabledInput() {
    return _isReading || !_isNfcAvailable;
  }
  String extractImageData(String inputHex) {
    // Find the index of the first occurrence of 'FFD8'
    int startIndex = inputHex.indexOf('ffd8');
    // Find the index of the first occurrence of 'FFD9'
    int endIndex = inputHex.indexOf('ffd9');

    // If both 'FFD8' and 'FFD9' are found, extract the substring between them
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      String extractedImageData = inputHex.substring(
          startIndex, endIndex + 4); // Include 'FFD9' in the substring

      // Return the extracted image data
      return extractedImageData;
    } else {
      // 'FFD8' or 'FFD9' not found, handle accordingly (e.g., return an error or the original input)
      print("FFD8 and/or FFD9 markers not found in the input hex string.");
      return inputHex;
    }
  }

  Widget _makeMrtdDataWidget(
      {required String? header,
        required String collapsedText,
        required String? dataText}) {
    return ListTile(
      contentPadding: EdgeInsets.all(0),
      title: Text(header ?? ""),
      onLongPress: () =>
          Clipboard.setData(ClipboardData(text: dataText ?? "Null")),
      subtitle: SelectableText(dataText ?? "Null", textAlign: TextAlign.left),
      trailing: IconButton(
        icon: const Icon(
          Icons.copy,
        ),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: dataText ?? "Null"));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Copied")));
        },
      ),
    );
  }

  List<Widget> _mrtdDataWidgets() {
    List<Widget> list = [];
    if (_mrtdData == null) return list;

    if (_mrtdData!.com != null) {
      list.add(_makeMrtdDataWidget(header: 'EF.COM',
          collapsedText: '',
          dataText: formatEfCom(_mrtdData!.com!)));
    }

    if (_mrtdData?.dg1 != null) {
      list.add(_makeMrtdDataWidget(
          header: null,
          collapsedText: '',
          dataText: formatMRZ(_mrtdData!.dg1!.mrz)));
    }

     // if (_mrtdData!.dg7 != null) {
     // list.add(_makeMrtdDataWidget(header: 'EF.DG7', collapsedText: '', dataText: _mrtdData!.dg7!.toBytes().hex()));
     //   }

    //  if (_mrtdData!.dg11 != null) {
    //   list.add(_makeMrtdDataWidget(header: 'EF.DG11', collapsedText: '', dataText: _mrtdData!.dg11!.toBytes().hex()));
    //   }
    //
    //   if (_mrtdData!.dg12 != null) {
    //   list.add(_makeMrtdDataWidget(header: 'EF.DG12', collapsedText: '', dataText: _mrtdData!.dg12!.toBytes().hex()));
    // }

    //  if (_mrtdData!.dg15 != null) {
    //   list.add(_makeMrtdDataWidget(header: 'EF.DG15', collapsedText: '', dataText: _mrtdData!.dg15!.toBytes().hex()));
    // }



    return list;
  }

  Scaffold _buildPage(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true, // Extend the body behind the app bar
    appBar: AppBar(
      backgroundColor: Colors.transparent, // Make the app bar transparent
      elevation: 0, // Remove the app bar shadow
      centerTitle: true,
      title: Text(
        'NFC-SCAN',
        style: TextStyle(
          color: Colors.black,
          fontSize: 21,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontStyle: FontStyle.italic,
          shadows: [
            Shadow(
              offset: Offset(1.0, 1.0),
              blurRadius: 2.0,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            Shadow(
              offset: Offset(1.0, 1.0),
              blurRadius: 2.0,
              color: Color.fromARGB(125, 0, 0, 255),
            ),
          ],
        ),
      ),
    ),
    body: Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Opacity(
            opacity: 0.3, // Adjust the opacity for fading effect
            child: Image.asset(
              'assets/voterpage.png', // Your background image asset
              fit: BoxFit.cover,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:17),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 10),
                  const SizedBox(height: 20),
                  _buildForm(context),
                  const SizedBox(height: 40),
                  if (_isNfcAvailable && _isReading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: CupertinoActivityIndicator(
                        color: Colors.black,
                        radius: 18,
                      ),
                    ),
                  if (_isNfcAvailable && !_isReading)
                    Column(
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPressed = true;
                              });
                              Future.delayed(Duration(milliseconds: 300), () {
                                setState(() {
                                  _isPressed = false;
                                });
                                _initPlatformState();
                                _readMRTD();
                                _showUserInstructions = false; // Hide user instructions
                              });
                            },
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
                                  'Next',
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
                        if (_showUserInstructions)
                          const SizedBox(height: 20),
                        if (_showUserInstructions)
                          const Text(
                            'Enter the Informations shown and Click Next , Please Make sure that the card is Well placed Usually on the top back of your device as shown in the animation ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,                            ),
                          ),
                      ],
                    ),
                  if (!_isNfcAvailable && !_isReading)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPressed = true;
                          });
                          Future.delayed(Duration(milliseconds: 300), () {
                            setState(() {
                              _isPressed = false;
                            });
                            setState(() {
                              _isNfcAvailable = false; // Start checking NFC
                            });
                            _initPlatformState().then((_) {
                              setState(() {
                                _isNfcAvailable = true; // NFC is available after checking
                                _showUserInstructions = true; // Show user instructions if needed
                              });
                            }).catchError((error) {
                              setState(() {
                                _isNfcAvailable = true; // Reset on error, assuming NFC is not being checked
                              });
                            });
                          });
                        },
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
                              )
                            ]
                                : [],
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: !_isNfcAvailable
                                ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Text(
                              'Checking NFC State',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(100.0),
                    child: const SizedBox(height:110),
                  ),
                  Text(
                    _alertMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (jpegImage != null || jp2000Image != null)
                    Center(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Image",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  if (jpegImage != null)
                    Column(
                      children: [
                        SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            jpegImage!,
                            errorBuilder: (context, error, stackTrace) => SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  if (jp2000Image != null)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            jp2000Image!,
                            errorBuilder: (context, error, stackTrace) => SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  if (rawHandSignatureData != null)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Text(
                          "Signature",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            rawHandSignatureData!,
                            errorBuilder: (context, error, stackTrace) => SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _mrtdData != null ? "NFC Scan Data:" : "",
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _mrtdDataWidgets(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    floatingActionButton: _showFAB
        ? Showcase(
      key: _showcaseKey,
      description: 'Tap here to create profile',
      textColor: Colors.black,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isFABPressed = true;
          });
          Future.delayed(Duration(milliseconds: 300), () async {
            setState(() {
              _isFABPressed = false;
            });
            if (_mrtdData != null) {
              // Save the sign-in status when the button is pressed
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isSignedIn', true);

              // Navigate to the VoterProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VoterProfilePage(
                    mrtdData: _mrtdData!,
                    rawHandSignatureData: rawHandSignatureData, // Ensure this is not null
                  ),
                ),
              );
            }
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: 60,
          width: 130,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(50),
            boxShadow: _isFABPressed
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, color: Colors.black),
                SizedBox(width: 1),
                Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        : null,
  );

  void _openNFCSettings() async {
    // Assuming _channel is the MethodChannel instance set up for NFC operations
    try {
      await platform.invokeMethod('openNFCSettings');
    } catch (e) {
      // Handle error if unable to open NFC settings
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Failed to open NFC settings: ${e.toString()}"),
          );
        },
      );
    }
  }


  Uint8List? jpegImage;
  Uint8List? jp2000Image;

  void tryDisplayingJpg() {
    try {
      jpegImage = rawImageData;

      setState(() {});
    } catch (e) {
      jpegImage = null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Image is not in jpg format, trying jpeg2000")));
    }
  }

  void tryDisplayingJp2() async {
    try {
      jp2000Image = await decodeImage(rawImageData!, context);
      setState(() {});
    } catch (e) {
      jpegImage = null;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Image is not in jpeg2000")));
    }
  }

  Padding _buildForm(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 30.0),
        child: Form(
          key: _mrzData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                enabled: !_disabledInput(),
                controller: _docNumber,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Document number',
                    fillColor: Colors.black
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]+')),
                  LengthLimitingTextInputFormatter(14)
                ],
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
                validator: (value) {
                  if (value?.isEmpty ?? false) {
                    return 'Please enter ID number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                  enabled: !_disabledInput(),
                  controller: _dob,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Date of Birth',
                      fillColor: Colors.white
                  ),
                  autofocus: false,
                  validator: (value) {
                    if (value?.isEmpty ?? false) {
                      return 'Please select Date of Birth';
                    }
                    return null;
                  },
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    // Can pick date which dates 15 years back or more
                    final now = DateTime.now();
                    final firstDate = DateTime(now.year - 90, now.month, now.day);
                    final lastDate  = DateTime(now.year - 15, now.month, now.day);
                    final initDate  = _getDOBDate();
                    final date = await _pickDate(context,
                        firstDate, initDate ?? lastDate, lastDate
                    );

                    FocusScope.of(context).requestFocus(FocusNode());
                    if(date != null) {
                      _dob.text = date;
                    }
                  }
              ),
              SizedBox(height: 12),
              TextFormField(
                  enabled: !_disabledInput(),
                  controller: _doe,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Date of Expiry',
                      fillColor: Colors.black
                  ),
                  autofocus: false,
                  validator: (value) {
                    if (value?.isEmpty ?? false) {
                      return 'Please select Date of Expiry';
                    }
                    return null;
                  },
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    // Can pick date from tomorrow and up to 10 years
                    final now = DateTime.now();
                    final firstDate = DateTime(now.year, now.month, now.day + 1);
                    final lastDate  = DateTime(now.year + 10, now.month + 6, now.day);
                    final initDate  = _getDOEDate();
                    final date = await _pickDate(context, firstDate,
                        initDate ?? firstDate, lastDate
                    );

                    FocusScope.of(context).requestFocus(FocusNode());
                    if(date != null) {
                      _doe.text = date;
                    }
                  }
              )
            ],
          ),
        )
    );
  }
}



