import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String dob;
  final String role; // 'customer', 'pumper', 'manager', 'admin'
  final DateTime joinedDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.dob,
    required this.role,
    required this.joinedDate,
  });

  // 1. Convert Firestore Document -> UserModel Object
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      dob: map['dob'] ?? '',
      role: map['role'] ?? 'customer',
      // Firestore stores Dates as Timestamps, so we convert it:
      joinedDate: (map['joinedDate'] as Timestamp).toDate(),
    );
  }

  // 2. Convert UserModel Object -> Map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'dob': dob,
      'role': role,
      'joinedDate': joinedDate, // Firestore handles DateTime auto-conversion
    };
  }
}