import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Constructor
  FirestoreService({required this.firestore});

  // Projects collection reference
  CollectionReference get projectsRef => firestore.collection('projects');

  // Tasks collection reference
  CollectionReference get tasksRef => firestore.collection('tasks');

  // Users collection reference
  CollectionReference get usersRef => firestore.collection('users');

  // Get all projects for a user
  Stream<QuerySnapshot> getUserProjects(String userId) {
    return projectsRef
        .where('members', arrayContains: userId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }


  // Create a new project
  Future<DocumentReference> createProject(Map<String, dynamic> projectData) {
    return projectsRef.add({
      ...projectData,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Update a project
  Future<void> updateProject(String projectId, Map<String, dynamic> data) {
    return projectsRef.doc(projectId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Delete a project
  Future<void> deleteProject(String projectId) {
    return projectsRef.doc(projectId).delete();
  }

  // Get all tasks for a user
  Stream<QuerySnapshot> getUserTasks(String userId) {
    return tasksRef
        .where('assigned_to', isEqualTo: userId)
        .orderBy('due_date')
        .snapshots();
  }

  // Get all tasks for a project
  Stream<QuerySnapshot> getProjectTasks(String projectId) {
    return tasksRef
        .where('project_id', isEqualTo: projectId)
        .orderBy('due_date')
        .snapshots();
  }

  // Create a new task
  Future<DocumentReference> createTask(Map<String, dynamic> taskData) {
    return tasksRef.add({
      ...taskData,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Update a task
  Future<void> updateTask(String taskId, Map<String, dynamic> data) {
    return tasksRef.doc(taskId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Delete a task
  Future<void> deleteTask(String taskId) {
    return tasksRef.doc(taskId).delete();
  }

  // Get users by role
  Future<QuerySnapshot> getUsersByRole(String role) {
    return usersRef.where('role', isEqualTo: role).get();
  }

  // Get user by id
  Future<DocumentSnapshot> getUserById(String userId) {
    return usersRef.doc(userId).get();
  }

  Future<bool> checkUserExistsByEmail(String email) async {
    try {
      final methods = await auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty; // If methods list is not empty, user exists
    } catch (e) {
      print('Error checking if user exists: $e');
      return false; // Assume user doesn't exist if we can't verify
    }
  }

  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    try {
      // Normalize email to lowercase for consistency
      final normalizedEmail = email.toLowerCase().trim();

      // Try Firestore search first
      var snapshot = await usersRef
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      // If user found in Firestore, return the data
      if (snapshot.docs.isNotEmpty) {
        final userDoc = snapshot.docs.first;
        final userData = userDoc.data() as Map<String, dynamic>;

        // Create a result with the expected 'id' field
        Map<String, dynamic> result = {
          'id': userData['uid'] ?? userDoc.id,
          ...userData,
        };

        return result;
      }

      // If not found in Firestore, check Auth as fallback
      final userExists = await checkUserExistsByEmail(normalizedEmail);
      if (userExists) {
        // User exists in Auth but not in Firestore - unusual but possible
        // Return a minimal record or handle specially
        print('User exists in Auth but not in Firestore: $normalizedEmail');
        return null; // Could return a limited record instead if needed
      }

      // Not found in either system
      return null;
    } catch (e) {
      print('Error searching user by email: $e');
      return null;
    }
  }

  Future<void> cleanupDeletedUser(String userId, String email) async {
    try {
      final batch = firestore.batch();
      // Delete user document
      batch.delete(usersRef.doc(userId));
      // Get projects with this user
      final projectsSnapshot = await projectsRef
          .where('members', arrayContains: userId)
          .get();
      // Update each project to remove user - FIXED
      for (final doc in projectsSnapshot.docs) {
        // Properly access the document data
        final data = doc.data() as Map<String, dynamic>;

        // Check if 'members' field exists and is an array
        if (data.containsKey('members') && data['members'] is List) {
          List<dynamic> members = List.from(data['members']);
          members.remove(userId);
          batch.update(doc.reference, {'members': members});
        }
      }
      // Delete invitations
      final invitationsSnapshot = await firestore.collection('invitations')
          .where('email', isEqualTo: email.toLowerCase())
          .get();
      for (final doc in invitationsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      // Commit all changes in one batch
      await batch.commit();
    } catch (e) {
      print('Error cleaning up deleted user: $e');
      throw e; // Re-throw to handle in the UI
    }
  }

  // Add member to project
  Future<void> addMemberToProject(String projectId, String userId) async {
    try {
      await projectsRef.doc(projectId).update({
        'members': FieldValue.arrayUnion([userId]),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding member to project: $e');
      throw e; // Re-throw to handle in the UI
    }
  }

  // Remove member from project
  Future<void> removeMemberFromProject(String projectId, String userId) async {
    try {
      await projectsRef.doc(projectId).update({
        'members': FieldValue.arrayRemove([userId]),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing member from project: $e');
      throw e; // Re-throw to handle in the UI
    }
  }

  // Cancel an invitation
  Future<void> cancelInvitation(String invitationId) async {
    try {
      await firestore.collection('invitations').doc(invitationId).delete();
    } catch (e) {
      print('Error cancelling invitation: $e');
      throw e; // Re-throw to handle in the UI
    }
  }

  // Create invitation record
  Future<DocumentReference> createInvitation(Map<String, dynamic> invitationData) async {
    try {
      return await firestore.collection('invitations').add({
        ...invitationData,
        'status': 'pending',
        'invitedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      });
    } catch (e) {
      print('Error creating invitation: $e');
      throw e; // Re-throw to handle in the UI
    }
  }

  // Get pending invitations for a project
  Stream<QuerySnapshot> getPendingInvitations(String projectId) {
    return firestore.collection('invitations')
        .where('projectId', isEqualTo: projectId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
  Future<void> createOrUpdateUserDocument(User user) async {
    try {
      // Check if user document already exists
      DocumentSnapshot userDoc = await usersRef.doc(user.uid).get();

      if (!userDoc.exists) {
        // Create new user document
        await usersRef.doc(user.uid).set({
          'id': user.uid,
          'email': user.email?.toLowerCase(),
          'name': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('Created new user document for: ${user.email}');
      } else {
        // Update existing user's last login
        await usersRef.doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          // Update email or name if they changed
          'email': user.email?.toLowerCase(),
          'name': user.displayName ?? '',
        });
        print('Updated existing user document for: ${user.email}');
      }
    } catch (e) {
      print('Error creating/updating user document: $e');
      throw e;
    }
  }

}