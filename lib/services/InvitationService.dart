import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvitationService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all invitations sent by current user
  Future<List<Map<String, dynamic>>> getSentInvitations() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('invitations')
        .where('invitedBy', isEqualTo: user.uid)
        .orderBy('invitedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  // Get all pending invitations for a project
  Future<List<Map<String, dynamic>>> getProjectInvitations(String projectId) async {
    final snapshot = await _firestore
        .collection('invitations')
        .where('projectId', isEqualTo: projectId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  // Send invitation
  Future<void> sendInvitation({
    required String email,
    required String projectId,
    required String projectName,
    required String role,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('You must be logged in to send invitations');

    // Check if user already exists
    final userSnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      // User exists - add directly to project members
      final userId = userSnapshot.docs.first.id;
      await _firestore.collection('projects').doc(projectId).update({
        'members': FieldValue.arrayUnion([userId]),
      });

      // Also create a notification for the user
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'project_added',
        'projectId': projectId,
        'projectName': projectName,
        'message': 'You were added to project: $projectName',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      return;
    }

    // User doesn't exist - create invitation
    await _firestore.collection('invitations').add({
      'email': email.toLowerCase(),
      'projectId': projectId,
      'projectName': projectName,
      'role': role,
      'status': 'pending',
      'invitedBy': user.uid,
      'inviterName': user.displayName ?? 'A team member',
      'invitedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(Duration(days: 7)),
      ),
      'message': message,
    });

    // Here you could also trigger an email (Firebase Functions or other service)
    // But that would require additional setup
  }

  // Cancel invitation
  Future<void> cancelInvitation(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).delete();
    notifyListeners();
  }

  // Check for pending invitations when user signs up or logs in
  Future<void> processInvitationsForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    // Find all pending invitations for this email
    final snapshot = await _firestore
        .collection('invitations')
        .where('email', isEqualTo: user.email!.toLowerCase())
        .where('status', isEqualTo: 'pending')
        .get();

    // Add user to all projects they were invited to
    final batch = _firestore.batch();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final projectId = data['projectId'];

      // Add user to project members
      final projectRef = _firestore.collection('projects').doc(projectId);
      batch.update(projectRef, {
        'members': FieldValue.arrayUnion([user.uid]),
      });

      // Mark invitation as accepted
      batch.update(doc.reference, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for the user
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': user.uid,
        'type': 'invitation_accepted',
        'projectId': projectId,
        'projectName': data['projectName'] ?? 'A project',
        'message': 'You were added to project: ${data['projectName'] ?? 'A project'}',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    await batch.commit();
    notifyListeners();
  }
}