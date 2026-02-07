import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart'; // Import the model we just created

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Sign Up User (With all details)
  Future<String?> signUpUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String mobileNumber,
    required String dob,
  }) async {
    try {
      // A. Create User in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // B. Create the User Model
      UserModel newUser = UserModel(
        uid: result.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        mobileNumber: mobileNumber,
        dob: dob,
        role: 'customer', // Default role is always customer
        joinedDate: DateTime.now(),
      );

      // C. Save User Data to Firestore
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toMap());

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return specific Firebase error
    } catch (e) {
      return e.toString();
    }
  }

  // 2. Sign In User & Get Role
  // Returns the UserModel if successful, null if failed
  Future<UserModel?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      // A. Sign In
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // B. Fetch Data from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (doc.exists) {
        // Convert the raw data to our UserModel
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // 3. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
