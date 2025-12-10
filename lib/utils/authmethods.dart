import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Removed: dart:convert and crypto/crypto as they were only used for admin password hashing

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Removed: _hashPassword and _verifyPasswordHash as they were only for admin login.

  /// Sign up a new user with email/password and send a verification email.
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String image,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty) {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        // Send email verification
        await cred.user?.sendEmailVerification();

        // Save user data to Firestore
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'Name': username.trim(),
          'Email': email.trim(),
          'Image': image,
          'createdAt': FieldValue.serverTimestamp(),
        });

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

  /// Send password reset email
  Future<String> forgotPassword({required String email}) async {
    String res = "Some error occurred";
    try {
      if (email.isEmpty) {
        return "Please enter your email address.";
      }
      
      await _auth.sendPasswordResetEmail(email: email.trim());
      res = "Password reset link sent! Check your inbox.";
    } on FirebaseAuthException catch (err) {
      switch (err.code) {
        case 'invalid-email':
          res = "Invalid email address.";
          break;
        case 'user-not-found':
          res = "No account found with this email.";
          break;
        default:
          res = err.message ?? "Failed to send reset email.";
      }
    } catch (e) {
      res = "Something went wrong. Please try again.";
    }
    return res;
  }

  /// Sign in an existing user with email/password and check for email verification.
  Future<String> signInUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        if (cred.user != null && cred.user!.emailVerified) {
          res = "Login successful.";
        } else {
          // If login is successful but email is not verified, sign out and inform the user
          await _auth.signOut();
          res = "Please verify your email before logging in. Check your inbox for a verification link.";
        }
      } else {
        res = "Please fill in all the fields.";
      }
    } on FirebaseAuthException catch (err) {
      switch (err.code) {
        case 'user-not-found':
        case 'invalid-credential':
          res = "Incorrect email or password.";
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

  /// Sign in or sign up a user with their Google account.
  Future<String> signInWithGoogle() async {
    String res = "Some error occurred";
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return "Google Sign-In cancelled.";
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        // Create a user document in Firestore if it doesn't exist (i.e., this is a first-time sign-in)
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'Name': user.displayName ?? 'No Name Provided',
            'Email': user.email ?? 'No Email Provided',
            'Id': user.uid,
            'Image': user.photoURL ??
                "https://firebasestorage.googleapis.com/v0/b/kartsyapp-87532.firebasestorage.app/o/default_profile.png?alt=media&token=d328f93c-400f-4deb-a0e8-014eb2e2b795",
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        res = "Login successful.";
      }
    } on FirebaseAuthException catch (e) {
      res = e.message ?? "An unexpected authentication error occurred.";
    } catch (e) {
      res = "Something went wrong. Please try again.";
    }
    return res;
  }

  /// Sign out the current user from Firebase and Google.
  Future<void> signOut() async {
    // Attempt to sign out from Google first
    if (await GoogleSignIn().isSignedIn()) {
      await GoogleSignIn().signOut();
    }
    // Sign out from Firebase
    await _auth.signOut();
  }

  // Removed: signInAdmin method and its helper functions (_incrementFailedAttempt, _resetAttempts, _logAdminLogin).
}