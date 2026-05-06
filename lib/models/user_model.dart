import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String dob;
  final String role;
  final String profilePic; // Added field
  final DateTime joinedDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.dob,
    required this.role,
    required this.profilePic,
    required this.joinedDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      dob: map['dob'] ?? '',
      role: map['role'] ?? 'customer',
      profilePic: map['profilePic'] ?? 'https://ui-avatars.com/api/?name=${map['firstName']}+${map['lastName']}&background=00E676&color=fff',
      joinedDate: (map['joinedDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'dob': dob,
      'role': role,
      'profilePic': profilePic,
      'joinedDate': joinedDate,
    };
  }
}