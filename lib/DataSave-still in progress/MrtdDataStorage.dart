import 'dart:typed_data';

class MrtdData {
  final String documentNumber;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String nationality;
  final String dateOfExpiry;
  final Uint8List imageData;
  final Uint8List rawHandSignatureData;

  MrtdData({
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.nationality,
    required this.dateOfExpiry,
    required this.imageData,
    required this.rawHandSignatureData,
  });

  factory MrtdData.fromStorage(Map<String, dynamic> map) {
    return MrtdData(
      documentNumber: map['documentNumber'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      dateOfBirth: map['dateOfBirth'],
      nationality: map['nationality'],
      dateOfExpiry: map['dateOfExpiry'],
      imageData: map['imageData'],
      rawHandSignatureData: map['signatureData'],
    );
  }
}

