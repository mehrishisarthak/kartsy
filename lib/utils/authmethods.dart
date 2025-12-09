import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔒 Secure password hashing (SHA256 + salt)
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password + 'kartsy_admin_salt_2025_secure')).toString();
  }

  bool _verifyPasswordHash(String password, String storedHash) {
    return _hashPassword(password) == storedHash;
  }

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

        await cred.user?.sendEmailVerification();

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
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// 🔒 SECURE ADMIN LOGIN with hashing + rate limiting
  Future<String> signInAdmin({
    required String username,
    required String password,
  }) async {
    String res = "Some error occurred";
    final trimmedUsername = username.trim().toLowerCase();
    final now = DateTime.now();
    
    try {
      if (trimmedUsername.isEmpty || password.isEmpty) {
        return "Please fill in all the fields.";
      }

      // 🔥 RATE LIMITING (3 attempts/hour per device)
      final deviceId = _auth.currentUser?.uid ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
      final attemptsDoc = await _firestore
          .collection('admin_attempts')
          .doc(trimmedUsername)
          .get();
      
      final attempts = attemptsDoc.data()?['count'] ?? 0;
      final lastAttempt = attemptsDoc.data()?['last_attempt']?.toDate() ?? 
                         now.subtract(const Duration(hours: 1));
      
      if (now.difference(lastAttempt).inHours < 1 && attempts >= 3) {
        return "Too many failed attempts. Try again in 1 hour.";
      }

      // 🔥 SECURE ADMIN LOOKUP
      final snapshot = await _firestore
          .collection('Admin')
          .where("username", isEqualTo: trimmedUsername)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        await _incrementFailedAttempt(trimmedUsername);
        res = "No admin found with this username.";
      } else {
        final adminData = snapshot.docs.first.data();
        final storedHash = adminData['password_hash'] as String?;

        if (storedHash != null && _verifyPasswordHash(password, storedHash)) {
          // ✅ SUCCESS - Reset attempts + log login
          await _resetAttempts(trimmedUsername);
          await _logAdminLogin(snapshot.docs.first.id, trimmedUsername);
          res = "Login successful.";
        } else {
          await _incrementFailedAttempt(trimmedUsername);
          res = "Incorrect password.";
        }
      }
    } catch (e) {
      print("⛔ Admin login error: $e");
      res = "Something went wrong. Please try again.";
    }
    return res;
  }

  // 🔥 Rate limiting helpers
  Future<void> _incrementFailedAttempt(String username) async {
    final docRef = _firestore.collection('admin_attempts').doc(username);
    await docRef.set({
      'count': FieldValue.increment(1),
      'last_attempt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _resetAttempts(String username) async {
    await _firestore.collection('admin_attempts').doc(username).delete();
  }

  Future<void> _logAdminLogin(String adminId, String username) async {
    await _firestore.collection('admin_logs').add({
      'admin_id': adminId,
      'username': username,
      'timestamp': FieldValue.serverTimestamp(),
      'ip_address': 'mobile_device', // Add real IP from backend later
    });
  }
}
