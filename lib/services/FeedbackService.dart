// lib/services/FeedbackService.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class FeedbackService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<void> submitFeedback({
    required String projectId,
    required String projectName,
    required String sprintId,
    required String sprintName,
    required int rating,
    required String comment,
  }) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get user profile to get name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'Client';

      print('DEBUG: Submitting feedback as: $userName (${user.uid})');
      print('DEBUG: For project: $projectName, sprint: $sprintName');

      // CRITICAL: Use the exact same field names as in the getClientFeedback methods
      final docRef = await _firestore.collection('projects').doc(projectId).collection('feedback').add({
        'projectId': projectId,         // Add this explicitly for consistency
        'projectName': projectName,     // Add this explicitly for consistency
        'sprintId': sprintId,
        'sprintName': sprintName,
        'clientId': user.uid,           // This matches the getClientFeedback query
        'clientName': userName,
        'rating': rating,
        'comment': comment,
        'response': '',                 // Initialize with empty response
        'dateSubmitted': FieldValue.serverTimestamp(),  // Use server timestamp
      });

      print('DEBUG: Feedback submitted with ID: ${docRef.id}');
      notifyListeners();
    } catch (e) {
      print('ERROR submitting feedback: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getAllProjectsFeedback() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('ERROR in getAllProjectsFeedback: No authenticated user found');
        return [];
      }

      print('DEBUG: Getting all feedback as user: ${user.uid}');

      final List<Map<String, dynamic>> allFeedback = [];

      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('members', arrayContains: user.uid)
          .get();
      print('DEBUG: Found ${projectsSnapshot.docs.length} projects total');

      // For each project, get its feedback
      int projectsChecked = 0;
      int projectsWithFeedback = 0;
      int totalFeedbackItems = 0;

      for (var project in projectsSnapshot.docs) {
        try {
          final projectId = project.id;
          final projectData = project.data();
          final projectName = projectData['name'] ?? 'Unknown Project';

          // Check if user has permission for this project (optional check)
          bool hasPermission = false;
          if (projectData.containsKey('roles')) {
            final roles = projectData['roles'];
            if (roles != null) {
              if (roles['productOwner'] == user.uid) {
                hasPermission = true;
              } else if (roles.containsKey('scrumMasters') &&
                  roles['scrumMasters'] is List &&
                  roles['scrumMasters'].contains(user.uid)) {
                hasPermission = true;
              }
            }
          }

          // Also check legacy members array
          if (!hasPermission && projectData.containsKey('members')) {
            final members = projectData['members'];
            if (members != null && members is List && members.contains(user.uid)) {
              hasPermission = true;
            }
          }

          print('DEBUG: Checking project: $projectName ($projectId) - Has permission: $hasPermission');
          projectsChecked++;

          // Get feedback for this project
          final feedbackSnapshot = await _firestore
              .collection('projects')
              .doc(projectId)
              .collection('feedback')
              .orderBy('dateSubmitted', descending: true)
              .get();

          print('DEBUG: Found ${feedbackSnapshot.docs.length} feedback items in project $projectName');

          if (feedbackSnapshot.docs.isNotEmpty) {
            projectsWithFeedback++;
            totalFeedbackItems += feedbackSnapshot.docs.length;
          }

          // Add each feedback item to our list with project information
          for (var feedbackDoc in feedbackSnapshot.docs) {
            try {
              final feedbackData = feedbackDoc.data();
              feedbackData['id'] = feedbackDoc.id;
              feedbackData['projectId'] = projectId;
              feedbackData['projectName'] = projectName;

              // Handle different date formats safely
              if (feedbackData['dateSubmitted'] != null) {
                if (feedbackData['dateSubmitted'] is Timestamp) {
                  final Timestamp timestamp = feedbackData['dateSubmitted'];
                  final DateTime dateTime = timestamp.toDate();
                  feedbackData['dateSubmitted'] = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
                } else if (feedbackData['dateSubmitted'] is String) {
                  // Already a string, leave as is
                } else {
                  // Unknown format, set to today
                  final now = DateTime.now();
                  feedbackData['dateSubmitted'] = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                }
              } else {
                // No date, set to today
                final now = DateTime.now();
                feedbackData['dateSubmitted'] = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              }

              allFeedback.add(Map<String, dynamic>.from(feedbackData));
            } catch (e) {
              print('ERROR processing feedback document ${feedbackDoc.id}: $e');
            }
          }
        } catch (e) {
          print('ERROR getting feedback for project ${project.id}: $e');
        }
      }

      // Print summary
      print('DEBUG: Checked $projectsChecked projects, found $projectsWithFeedback with feedback');
      print('DEBUG: Total feedback items found across all projects: ${allFeedback.length}');

      if (allFeedback.isEmpty) {
        print('WARNING: No feedback found in any project. Check security rules and data.');
      }

      // Safe sort with fallback for missing dates
      try {
        allFeedback.sort((a, b) => (b['dateSubmitted'] ?? '').compareTo(a['dateSubmitted'] ?? ''));
      } catch (e) {
        print('ERROR sorting feedback: $e');
      }

      return allFeedback;
    } catch (e) {
      print('ERROR in getAllProjectsFeedback: $e');
      return [];
    }
  }

  // Update feedback response (for Product Owner)
  Future<void> updateFeedbackResponse(String projectId, String feedbackId, String response) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('feedback')
          .doc(feedbackId)
          .update({
        'response': response,
      });

      // Notify listeners that data has changed
      notifyListeners();
    } catch (e) {
      print('Error updating feedback response: $e');
      throw e;
    }
  }

  // Check if user has already provided feedback for a sprint
  Future<bool> hasProvidedFeedback(String projectId, String sprintId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final feedbackSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('feedback')
          .where('sprintId', isEqualTo: sprintId)
          .where('clientId', isEqualTo: user.uid)
          .limit(1)
          .get();

      return feedbackSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if feedback exists: $e');
      return false;
    }
  }

// Update the getClientFeedback method
  Future<List<Map<String, dynamic>>> getClientFeedback() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('DEBUG: User is null in getClientFeedback');
        return [];
      }

      print('DEBUG: Fetching feedback for user ID: ${user.uid}');

      final List<Map<String, dynamic>> clientFeedback = [];

      // Get all projects
      final projectsSnapshot = await _firestore.collection('projects').get();
      print('DEBUG: Found ${projectsSnapshot.docs.length} projects');

      // For each project, get feedback by this client
      for (var project in projectsSnapshot.docs) {
        final projectId = project.id;
        final projectData = project.data();
        final projectName = projectData['name'] ?? 'Unknown Project';

        print('DEBUG: Checking project: $projectName (ID: $projectId)');

        try {
          // Get feedback for this project by this client USING EXACT FIELD NAME
          final feedbackSnapshot = await _firestore
              .collection('projects')
              .doc(projectId)
              .collection('feedback')
              .where('clientId', isEqualTo: user.uid)  // This must match the field name in submitFeedback
              .get();

          print('DEBUG: Found ${feedbackSnapshot.docs.length} feedback entries for project: $projectName');

          // Add each feedback item to our list with project information
          for (var feedbackDoc in feedbackSnapshot.docs) {
            final feedbackData = feedbackDoc.data();
            // Ensure consistent field names
            feedbackData['id'] = feedbackDoc.id;
            if (!feedbackData.containsKey('projectId')) feedbackData['projectId'] = projectId;
            if (!feedbackData.containsKey('projectName')) feedbackData['projectName'] = projectName;

            // Format the date
            if (feedbackData['dateSubmitted'] != null) {
              if (feedbackData['dateSubmitted'] is Timestamp) {
                final Timestamp timestamp = feedbackData['dateSubmitted'];
                final DateTime dateTime = timestamp.toDate();
                feedbackData['dateSubmitted'] = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
              }
            }

            print('DEBUG: Adding feedback with ID: ${feedbackDoc.id}');
            clientFeedback.add(Map<String, dynamic>.from(feedbackData));
          }
        } catch (e) {
          print('ERROR getting feedback for project $projectId: $e');
          // Continue with next project
          continue;
        }
      }

      // Sort all feedback by date, newest first
      clientFeedback.sort((a, b) => (b['dateSubmitted'] ?? '').compareTo(a['dateSubmitted'] ?? ''));

      print('DEBUG: Total client feedback items found: ${clientFeedback.length}');
      return clientFeedback;
    } catch (e) {
      print('ERROR getting client feedback: $e');
      return [];
    }
  }

// Check if the feedback collection exists for a project
  Future<bool> checkFeedbackCollectionExists(String projectId) async {
    try {
      final collection = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('feedback')
          .limit(1)
          .get();

      print('DEBUG: Feedback collection exists for project $projectId: ${collection.docs.isNotEmpty}');
      return collection.docs.isNotEmpty;
    } catch (e) {
      print('ERROR checking feedback collection for project $projectId: $e');
      return false;
    }
  }

// Get client feedback directly without composite index
  Future<List<Map<String, dynamic>>> getClientFeedbackDirect() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final List<Map<String, dynamic>> results = [];

      // Get all projects first
      final projects = await _firestore.collection('projects').get();

      for (var project in projects.docs) {
        final projectId = project.id;
        final projectName = project.data()['name'] ?? 'Unknown Project';

        try {
          // Check each project's feedback collection manually
          final feedbackCollection = await _firestore
              .collection('projects')
              .doc(projectId)
              .collection('feedback')
              .get();

          print('DEBUG: Found ${feedbackCollection.docs.length} feedback docs in project $projectId');

          // Filter client feedback manually
          for (var doc in feedbackCollection.docs) {
            final data = doc.data();
            if (data['clientId'] == user.uid) {
              data['id'] = doc.id;
              data['projectId'] = projectId;
              data['projectName'] = projectName;

              // Format date
              if (data['dateSubmitted'] != null) {
                final Timestamp timestamp = data['dateSubmitted'];
                final DateTime dateTime = timestamp.toDate();
                data['dateSubmitted'] = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
              }

              results.add(Map<String, dynamic>.from(data));
              print('DEBUG: Found feedback from client ${user.uid} in project $projectId');
            }
          }
        } catch (e) {
          print('ERROR checking project $projectId: $e');
        }
      }

      // Sort results by date
      results.sort((a, b) => (b['dateSubmitted'] ?? '').compareTo(a['dateSubmitted'] ?? ''));
      return results;
    } catch (e) {
      print('ERROR in getClientFeedbackDirect: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> getProjectFeedback(String projectId) async {
    try {
      // Add null check for projectId
      if (projectId.isEmpty) {
        print('ERROR: Project ID is empty');
        return [];
      }

      print('DEBUG: Getting feedback for project: $projectId');

      final feedbackSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('feedback')
          .orderBy('dateSubmitted', descending: true)
          .get();

      print('DEBUG: Found ${feedbackSnapshot.docs.length} feedback items for project $projectId');

      final List<Map<String, dynamic>> feedbackList = [];

      for (var doc in feedbackSnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          data['projectId'] = projectId;

          // Format date if needed with null safety
          if (data['dateSubmitted'] != null && data['dateSubmitted'] is Timestamp) {
            final timestamp = data['dateSubmitted'] as Timestamp;
            final date = timestamp.toDate();
            data['dateSubmitted'] = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } else if (data['dateSubmitted'] == null) {
            final now = DateTime.now();
            data['dateSubmitted'] = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          }

          // Ensure required fields exist with null safety
          data['rating'] = data['rating'] ?? 0;
          data['comment'] = data['comment'] ?? '';
          data['clientName'] = data['clientName'] ?? 'Anonymous Client';
          data['sprintName'] = data['sprintName'] ?? '';

          feedbackList.add(Map<String, dynamic>.from(data));
        } catch (e) {
          print('ERROR processing feedback document: $e');
        }
      }

      return feedbackList;
    } catch (e) {
      print('ERROR getting project feedback: $e');
      return [];
    }
  }
}