import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn => _googleSignInInstance ??= GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        await _createFirestoreProfile(result.user!, email);
        result.user!.sendEmailVerification().catchError((e) => debugPrint("Verification error: $e"));
      }
      return result;
    } catch (e) {
      debugPrint("Registration Error: $e");
      rethrow;
    }
  }

  Future<void> _createFirestoreProfile(User user, String email, {String? username, String? photoUrl}) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'username': username ?? user.displayName ?? email.split('@')[0],
        'email': email,
        'profilePictureUrl': photoUrl ?? user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore Profile Creation Error: $e");
    }
  }

  Future<void> updateProfile({String? username, String? profilePictureUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      if (username != null) await user.updateDisplayName(username);
      if (profilePictureUrl != null) await user.updatePhotoURL(profilePictureUrl);

      // Sync to Firestore
      await _firestore.collection('users').doc(user.uid).update({
        if (username != null) 'username': username,
        if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      });
      
      await user.reload();
    } catch (e) {
      debugPrint("Profile Update Error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        await _createFirestoreProfile(result.user!, email);
      }
      return result;
    } catch (e) {
      debugPrint("Email Sign-In Error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        await _createFirestoreProfile(
          result.user!, 
          result.user!.email!, 
          username: result.user!.displayName, 
          photoUrl: result.user!.photoURL
        );
      }
      return result;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    try {
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }
}
