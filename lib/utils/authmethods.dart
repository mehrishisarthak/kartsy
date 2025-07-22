import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign up a new user and send a verification email.
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String userId,
    required String image,
  }) async {
    String res = "Some error occurred";

    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty) {
        // Create user with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // ⭐️ NEW: Send email verification
        await cred.user!.sendEmailVerification();

        // Store additional user info in Firestore
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'Name': username.trim(),
          'Email': email.trim(),
          'Id': userId,
          'Image': image,
        });

        // ⭐️ UPDATED: Success message now informs the user to verify
        res = "Account created successfully. Please check your email to verify your account.";
      } else {
        res = "Please fill in all the fields.";
      }
    } on FirebaseAuthException catch (err) {
      switch (err.code) {
        case 'weak-password':
          res = "The password provided is too weak.";
          break;
        case 'email-already-in-use':
          res = "An account with this email already exists.";
          break;
        case 'invalid-email':
          res = "The email address is invalid.";
          break;
        default:
          res = err.message ?? "An unexpected authentication error occurred.";
      }
    } catch (e) {
      res = "Something went wrong. Please try again.";
    }

    return res;
  }

  /// Sign in an existing user and check for email verification.
  Future<String> signInUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";

    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Attempt to sign in the user
        UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        // ⭐️ NEW: Check if the user's email is verified
        if (cred.user!.emailVerified) {
          res = "Login successful.";
        } else {
          // If not verified, inform the user and sign them out
          await _auth.signOut(); // Prevent unverified access
          res = "Please verify your email before logging in. Check your inbox for a verification link.";
        }
      } else {
        res = "Please fill in all the fields.";
      }
    } on FirebaseAuthException catch (err) {
      switch (err.code) {
        case 'user-not-found':
          res = "No account found for that email.";
          break;
        case 'wrong-password':
          res = "Incorrect password.";
          break;
        case 'invalid-email':
          res = "The email address is invalid.";
          break;
        case 'user-disabled':
          res = "This user account has been disabled.";
          break;
        case 'too-many-requests':
          res = "Too many failed attempts. Try again later.";
          break;
        default:
          res = err.message ?? "An unexpected authentication error occurred.";
      }
    } catch (e) {
      res = "Something went wrong. Please try again.";
    }

    return res;
  }

  /// Sign in an admin (uses Firestore only, no changes needed here)
  Future<String> signInAdmin({
    required String username,
    required String password,
  }) async {
    String res = "Some error occurred";

    try {
      final trimmedUsername = username.trim().toLowerCase();
      final trimmedPassword = password.trim();

      if (trimmedUsername.isEmpty || trimmedPassword.isEmpty) {
        return "Please fill in all the fields.";
      }

      final snapshot = await _firestore
          .collection('Admin')
          .where("username", isEqualTo: trimmedUsername)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        res = "No admin found with this username.";
      } else {
        final data = snapshot.docs.first.data();
        final storedPassword = data['password']?.toString().trim();

        if (storedPassword == trimmedPassword) {
          res = "Login successful.";
        } else {
          res = "Incorrect password.";
        }
      }
    } catch (e) {
      print("⛔ Error during admin login: $e");
      res = "Something went wrong. Please try again.";
    }

    return res;
  }
}
