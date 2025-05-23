// lib/services/RetrosrectiveService.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RetrospectiveService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  List<Map<String, dynamic>> _activeRetrospectives = [];
  List<Map<String, dynamic>> _draftRetrospectives = [];
  List<Map<String, dynamic>> _closedRetrospectives = [];
  List<Map<String, dynamic>> _projects = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get activeRetrospectives => _activeRetrospectives;
  List<Map<String, dynamic>> get draftRetrospectives => _draftRetrospectives;
  List<Map<String, dynamic>> get closedRetrospectives => _closedRetrospectives;
  List<Map<String, dynamic>> get projects => _projects;

  // Load retrospectives for specific project or all projects
  Future<void> loadRetrospectives({String? projectId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Clear existing lists
      _activeRetrospectives = [];
      _draftRetrospectives = [];
      _closedRetrospectives = [];

      // Load user's projects if not loaded already
      if (_projects.isEmpty) {
        await _loadProjects();
      }

      List<Map<String, dynamic>> projectsToQuery = [];

      if (projectId != null) {
        // Query specific project
        final projectDoc = await _firestore.collection('projects').doc(projectId).get();
        if (projectDoc.exists) {
          projectsToQuery.add({
            'id': projectDoc.id,
            'name': projectDoc.data()?['name'] ?? 'Unknown Project'
          });
        }
      } else {
        // Use all loaded projects
        projectsToQuery = _projects;
      }

      // For each project, load its retrospectives
      for (var project in projectsToQuery) {
        final projectId = project['id'];
        final projectName = project['name'];

        final retrospectivesSnapshot = await _firestore
            .collection('projects')
            .doc(projectId)
            .collection('retrospectives')
            .get();

        for (var doc in retrospectivesSnapshot.docs) {
          final data = doc.data();
          final retrospective = {
            'id': doc.id,
            'projectId': projectId,
            'projectName': projectName,
            'formTitle': data['title'] ?? 'Unnamed Form',
            'description': data['description'] ?? '',
            'sprintName': data['sprintName'] ?? '',
            'sprintId': data['sprintId'] ?? '',
            'status': data['status'] ?? 'Draft',
            'completionRate': data['completionRate'] ?? 0,
            'dueDate': data['dueDate'] ?? '',
            'questions': data['questions'] ?? [],
            'responses': data['responses'] ?? [],
            'createdAt': data['createdAt'],
          };

          // Add to appropriate list based on status
          if (data['status'] == 'Open') {
            _activeRetrospectives.add(retrospective);
          } else if (data['status'] == 'Draft') {
            _draftRetrospectives.add(retrospective);
          } else if (data['status'] == 'Closed') {
            _closedRetrospectives.add(retrospective);
          }
        }
      }

      _isLoading = false;
      notifyListeners();

    } catch (e) {
      print('Error loading retrospectives: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load projects that the user is a member of
  Future<void> _loadProjects() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print('Loading projects for user: ${user.uid}');

      // Clear existing projects
      _projects = [];

      // Query 1: Projects where user is Product Owner
      final productOwnerQuery = await _firestore
          .collection('projects')
          .where('roles.productOwner', isEqualTo: user.uid)
          .get();

      // Query 2: Projects where user is Scrum Master
      final scrumMasterQuery = await _firestore
          .collection('projects')
          .where('roles.scrumMasters', arrayContains: user.uid)
          .get();

      // Query 3: Projects where user is Team Member
      final teamMemberQuery = await _firestore
          .collection('projects')
          .where('roles.teamMembers', arrayContains: user.uid)
          .get();

      // Query 4: Projects where user is Client
      final clientQuery = await _firestore
          .collection('projects')
          .where('roles.clients', arrayContains: user.uid)
          .get();

      // Combine all results using Set to avoid duplicates
      final Set<String> projectIds = {};
      final List<QueryDocumentSnapshot> allDocs = [];

      // Add all documents and track IDs to avoid duplicates
      for (var doc in [...productOwnerQuery.docs, ...scrumMasterQuery.docs, ...teamMemberQuery.docs, ...clientQuery.docs]) {
        if (!projectIds.contains(doc.id)) {
          projectIds.add(doc.id);
          allDocs.add(doc);
        }
      }

      // Convert to project list
      _projects = allDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Found project: ${data['name']} (${doc.id}) for user role');
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Project'
        };
      }).toList();

      print('Total projects loaded: ${_projects.length}');

    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  // Create or update a retrospective form
  Future<Map<String, dynamic>> saveRetrospective({
    required String projectId,
    String? retrospectiveId,
    required String title,
    required String description,
    required String sprintId,
    required String sprintName,
    required String status,
    required String dueDate,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare the form data
      final formData = {
        'title': title,
        'description': description,
        'sprintId': sprintId,
        'sprintName': sprintName,
        'status': status,
        'dueDate': dueDate,
        'questions': questions,
        'completionRate': 0,
      };

      // Add creation data for new forms
      if (retrospectiveId == null) {
        formData['createdBy'] = user.uid;
        formData['createdAt'] = FieldValue.serverTimestamp();
        formData['responses'] = [];
      }

      DocumentReference docRef;
      String docId;

      if (retrospectiveId != null) {
        // Update existing form
        docRef = _firestore
            .collection('projects')
            .doc(projectId)
            .collection('retrospectives')
            .doc(retrospectiveId);

        // For existing forms, preserve the responses
        DocumentSnapshot existingDoc = await docRef.get();
        if (existingDoc.exists) {
          Map<String, dynamic> existingData = existingDoc.data() as Map<String, dynamic>;
          if (existingData.containsKey('responses')) {
            formData['responses'] = existingData['responses'];
          }
          if (existingData.containsKey('completionRate')) {
            formData['completionRate'] = existingData['completionRate'];
          }
        }

        await docRef.update(formData);
        docId = retrospectiveId;
      } else {
        // Create new form
        docRef = await _firestore
            .collection('projects')
            .doc(projectId)
            .collection('retrospectives')
            .add(formData);
        docId = docRef.id;
      }

      // Get project name for return data
      String projectName = 'Unknown Project';
      for (var project in _projects) {
        if (project['id'] == projectId) {
          projectName = project['name'];
          break;
        }
      }

      // Create return data
      final returnData = {
        'id': docId,
        'projectId': projectId,
        'projectName': projectName,
        'formTitle': title,
        'sprintName': sprintName,
        'description': description,
        'dueDate': dueDate,
        'questions': questions,
        'status': status,
        'completionRate': formData['completionRate'],
      };

      // Refresh the lists
      await loadRetrospectives(projectId: projectId);

      return returnData;
    } catch (e) {
      print('Error saving retrospective: $e');
      throw e;
    }
  }

  Future<void> submitResponse({
    required String projectId,
    required String retrospectiveId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      // Get the current user
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Create the response object
      final response = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'timestamp': Timestamp.now(),
        'answers': answers,
      };

      // Update the document in Firestore
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('retrospectives')
          .doc(retrospectiveId)
          .update({
        'responses': FieldValue.arrayUnion([response]),
      });

      // Find the retrospective in the active list (since only active ones can be responded to)
      final index = _activeRetrospectives.indexWhere((r) =>
      r['id'] == retrospectiveId && r['projectId'] == projectId);

      if (index != -1) {
        // Add response to local data
        if (_activeRetrospectives[index]['responses'] == null) {
          _activeRetrospectives[index]['responses'] = [];
        }

        _activeRetrospectives[index]['responses'].add(response);

        // Update completion rate after submitting response
        await updateCompletionRate(projectId, retrospectiveId);

        notifyListeners();
      }
    } catch (e) {
      print('Error submitting response: $e');
      throw e;
    }
  }

  // Calculate and update completion rate
  Future<void> updateCompletionRate(String projectId, String retrospectiveId) async {
    try {
      // Get retrospective document
      final retrospectiveDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('retrospectives')
          .doc(retrospectiveId)
          .get();

      if (!retrospectiveDoc.exists) {
        return;
      }

      final retroData = retrospectiveDoc.data()!;

      // Get project members
      final projectDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .get();

      if (!projectDoc.exists) {
        return;
      }

      final projectData = projectDoc.data()!;
      final List<dynamic> members = projectData['members'] ?? [];

      // Get responses
      final List<dynamic> responses = retroData['responses'] ?? [];

      // Count unique responders
      Set<String> responders = {};
      for (var response in responses) {
        if (response is Map && response['userId'] != null) {
          responders.add(response['userId'] as String);
        }
      }

      // Calculate percentage
      int completionRate = members.isEmpty
          ? 0
          : (responders.length / members.length * 100).round();

      // Update completion rate
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('retrospectives')
          .doc(retrospectiveId)
          .update({
        'completionRate': completionRate
      });

      // Refresh the lists
      await loadRetrospectives(projectId: projectId);

    } catch (e) {
      print('Error updating completion rate: $e');
    }
  }

  // Change retrospective status (e.g., close it)
  Future<void> changeStatus({
    required String projectId,
    required String retrospectiveId,
    required String newStatus,
  }) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('retrospectives')
          .doc(retrospectiveId)
          .update({
        'status': newStatus
      });

      // FIXED: Refresh ALL retrospectives, not just for this project
      await loadRetrospectives(); // Remove projectId parameter

    } catch (e) {
      print('Error changing retrospective status: $e');
      throw e;
    }
  }

  // Delete a retrospective
  Future<void> deleteRetrospective({
    required String projectId,
    required String retrospectiveId,
  }) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('retrospectives')
          .doc(retrospectiveId)
          .delete();

      // Refresh the lists
      await loadRetrospectives(projectId: projectId);

    } catch (e) {
      print('Error deleting retrospective: $e');
      throw e;
    }
  }

  // Get a specific retrospective
  Future<Map<String, dynamic>?> getRetrospective({
    required String projectId,
    required String retrospectiveId,
  }) async {
    try {
      final doc = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('retrospectives')
          .doc(retrospectiveId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      // Get project name
      String projectName = 'Unknown Project';
      for (var project in _projects) {
        if (project['id'] == projectId) {
          projectName = project['name'];
          break;
        }
      }

      return {
        'id': doc.id,
        'projectId': projectId,
        'projectName': projectName,
        'formTitle': data['title'] ?? 'Unnamed Form',
        'description': data['description'] ?? '',
        'sprintName': data['sprintName'] ?? '',
        'sprintId': data['sprintId'] ?? '',
        'status': data['status'] ?? 'Draft',
        'completionRate': data['completionRate'] ?? 0,
        'dueDate': data['dueDate'] ?? '',
        'questions': data['questions'] ?? [],
        'responses': data['responses'] ?? [],
        'createdAt': data['createdAt'],
      };

    } catch (e) {
      print('Error getting retrospective: $e');
      return null;
    }
  }
  // Add this method to RetrospectiveService class
  Future<void> updateResponse({
    required String projectId,
    required String retrospectiveId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      // Get the current user
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get the current document to find the existing response
      final docSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('retrospectives')
          .doc(retrospectiveId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Retrospective not found');
      }

      final data = docSnapshot.data()!;
      List<dynamic> responses = List.from(data['responses'] ?? []);

      // Find the user's existing response index
      int existingResponseIndex = -1;
      for (int i = 0; i < responses.length; i++) {
        if (responses[i]['userId'] == user.uid) {
          existingResponseIndex = i;
          break;
        }
      }

      // Create the updated response
      final updatedResponse = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'timestamp': Timestamp.now(),
        'answers': answers,
      };

      // Update the responses list
      if (existingResponseIndex >= 0) {
        // Replace existing response
        responses[existingResponseIndex] = updatedResponse;
      } else {
        // Add as new response if not found (shouldn't happen in this flow)
        responses.add(updatedResponse);
      }

      // Update the document
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('retrospectives')
          .doc(retrospectiveId)
          .update({
        'responses': responses,
      });

      // Update local data
      final retroIndex = _activeRetrospectives.indexWhere((r) =>
      r['id'] == retrospectiveId && r['projectId'] == projectId);

      if (retroIndex != -1) {
        if (_activeRetrospectives[retroIndex]['responses'] == null) {
          _activeRetrospectives[retroIndex]['responses'] = [];
        }

        List<dynamic> localResponses = List.from(_activeRetrospectives[retroIndex]['responses']);
        int localExistingIndex = -1;
        for (int i = 0; i < localResponses.length; i++) {
          if (localResponses[i]['userId'] == user.uid) {
            localExistingIndex = i;
            break;
          }
        }

        if (localExistingIndex >= 0) {
          localResponses[localExistingIndex] = updatedResponse;
        } else {
          localResponses.add(updatedResponse);
        }

        _activeRetrospectives[retroIndex]['responses'] = localResponses;

        // Update completion rate after updating response
        await updateCompletionRate(projectId, retrospectiveId);

        notifyListeners();
      }
    } catch (e) {
      print('Error updating response: $e');
      throw e;
    }
  }
  Future<void> updateRetrospective({
    required String projectId,
    required String retrospectiveId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Update Firestore document
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('retrospectives')
          .doc(retrospectiveId)
          .update(data);

      // Update local data
      final index = _draftRetrospectives.indexWhere(
              (retro) => retro['id'] == retrospectiveId && retro['projectId'] == projectId);

      if (index != -1) {
        _draftRetrospectives[index] = data;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating retrospective: $e');
      throw e;
    }
  }
}