import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  // Constructor
  AuthService({
    required this.firebaseAuth,
    required this.firestore,
  });

  // Get current user
  User? get currentUser => firebaseAuth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Sign in with email and password - no verification check
      final credential = await firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // Process pending invitations after sign in
      await _processInvitations();

      notifyListeners();
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email,
      String password,
      String name,
      String role,
      ) async {
    try {
      // Create user in Firebase Auth
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      // Create user profile in Firestore
      if (credential.user != null) {
        await firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'name': name,
          'role': role,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Update display name
        await credential.user!.updateDisplayName(name);

        // Process pending invitations after account creation
        await _processInvitations();
      }

      notifyListeners();
      return credential;
    } catch (e) {
      rethrow;
    }

  }

  Future<bool> checkUserExistsByEmail(String email) async {
    try {
      // Use Firebase Admin SDK method or alternative approach
      // Note: This direct approach has limitations due to Firebase security rules
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false; // Assume user doesn't exist if we can't verify
    }
  }
  // Process pending invitations for current user
  Future<void> _processInvitations() async {
    if (currentUser == null || currentUser!.email == null) return;

    // Find all pending invitations for this email
    final snapshot = await firestore
        .collection('invitations')
        .where('email', isEqualTo: currentUser!.email!.toLowerCase())
        .where('status', isEqualTo: 'pending')
        .get();

    if (snapshot.docs.isEmpty) return;

    // Add user to all projects they were invited to
    final batch = firestore.batch();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final projectId = data['projectId'];

      // Add user to project members
      final projectRef = firestore.collection('projects').doc(projectId);
      batch.update(projectRef, {
        'members': FieldValue.arrayUnion([currentUser!.uid]),
      });

      // Mark invitation as accepted
      batch.update(doc.reference, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for the user
      final notificationRef = firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': currentUser!.uid,
        'type': 'invitation_accepted',
        'projectId': projectId,
        'projectName': data['projectName'] ?? 'A project',
        'message': 'You were added to project: ${data['projectName'] ?? 'A project'}',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    await batch.commit();
  }

  // Process invitations manually
  Future<List<Map<String, dynamic>>> processInvitationsForCurrentUser() async {
    if (currentUser == null || currentUser!.email == null) return [];

    // Find all pending invitations for this email
    final snapshot = await firestore
        .collection('invitations')
        .where('email', isEqualTo: currentUser!.email!.toLowerCase())
        .where('status', isEqualTo: 'pending')
        .get();

    if (snapshot.docs.isEmpty) return [];

    // Process invitations
    await _processInvitations();

    // Return the projects the user was added to
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'projectId': data['projectId'],
        'projectName': data['projectName'] ?? 'Unknown project',
      };
    }).toList();
  }

  // Sign out
  Future<void> signOut() async {
    await firebaseAuth.signOut();
    notifyListeners();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    final docSnapshot = await firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    return docSnapshot.data();
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;

    await firestore
        .collection('users')
        .doc(currentUser!.uid)
        .update(data);

    // Update display name if it's changed
    if (data.containsKey('name')) {
      await currentUser!.updateDisplayName(data['name']);
    }

    notifyListeners();
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      // Get current user
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated');
      }

      // Re-authenticate the user with current password to verify identity
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update the password
      await user.updatePassword(newPassword);

      notifyListeners();
    } catch (e) {
      print('Error changing password: $e');
      rethrow;
    }
  }

  Future<String> getUserRole() async {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      try {
        final doc = await firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && doc.data()!.containsKey('role')) {
          return doc.data()!['role'];
        }
      } catch (e) {
        print('Error getting user role: $e');
      }
    }
    // Default to Product Owner if role can't be determined
    return 'Product Owner';
  }

// Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('Error resending verification email: $e');
      throw e;
    }
  }

// Send email verification to current user
  Future<void> sendEmailVerification() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('Error sending verification email: $e');
      throw e;
    }
  }

// Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      // Reload user to get current status
      await firebaseAuth.currentUser?.reload();
      final user = firebaseAuth.currentUser;
      return user != null && user.emailVerified;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

// Delete unverified user account
  Future<void> deleteUnverifiedAccount() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      print('Error deleting unverified account: $e');
      throw e;
    }
  }

  void startEmailVerificationListener() {
    // If there's already a user logged in
    if (currentUser != null) {
      // Set up a timer to periodically check verification status
      Timer.periodic(Duration(seconds: 5), (timer) async {
        try {
          // Reload user to get current verification status
          await currentUser!.reload();
          final user = firebaseAuth.currentUser;

          // If user has verified their email
          if (user != null && user.emailVerified) {
            timer.cancel(); // Stop checking

            // Process any pending invitations
            await _processInvitations();
            notifyListeners();
          }
        } catch (e) {
          print('Error in email verification listener: $e');
        }
      });
    }
  }
}