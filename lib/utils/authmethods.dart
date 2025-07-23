import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign up a new user with email/password and send a verification email.
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
        // Create the user in Firebase Auth
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Send the verification email
        await cred.user?.sendEmailVerification();

        // Store additional user details in Firestore
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'Name': username.trim(),
          'Email': email.trim(),
          'Id': userId, // Your custom ID
          'Image': image,
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

  /// Sign in an existing user with email/password and check for email verification.
  Future<String> signInUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Sign in the user
        UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        // Check if the user's email is verified
        if (cred.user != null && cred.user!.emailVerified) {
          res = "Login successful.";
        } else {
          // If not verified, sign them out for security and inform them
          await _auth.signOut();
          res = "Please verify your email before logging in. Check your inbox for a verification link.";
        }
      } else {
        res = "Please fill in all the fields.";
      }
    } on FirebaseAuthException catch (err) {
      switch (err.code) {
        case 'user-not-found':
        case 'invalid-credential': // More common error code now
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
      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return "Google Sign-In cancelled.";
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if this is a new user by looking for their document in Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        // If the user is signing in for the first time, create their profile in Firestore
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'Name': user.displayName ?? 'No Name Provided',
            'Email': user.email ?? 'No Email Provided',
            'Id': user.uid, // Use the Firebase UID as the primary ID
            'Image': user.photoURL ?? "https://i.ibb.co/k2kmqpV/profilepic.png",
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
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Sign in an admin (uses a separate Firestore collection).
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
