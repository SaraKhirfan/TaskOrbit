// lib/services/sprint_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SprintService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for sprints data
  Map<String, List<Map<String, dynamic>>> _projectSprints = {};

  // Get all sprints for a project
  Future<List<Map<String, dynamic>>> getSprints(String projectId) async {
    try {
      final sprintsSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('sprints')
          .get();

      final sprints = sprintsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Update cache
      _projectSprints[projectId] = sprints;

      return sprints;
    } catch (e) {
      print('Error getting sprints: $e');
      return [];
    }
  }

  // Get a specific sprint
  Future<Map<String, dynamic>?> getSprint(String projectId, String sprintId) async {
    try {
      final sprintDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('sprints')
          .doc(sprintId)
          .get();

      if (!sprintDoc.exists) {
        return null;
      }

      return {
        'id': sprintDoc.id,
        ...sprintDoc.data()!,
      };
    } catch (e) {
      print('Error getting sprint: $e');
      return null;
    }
  }

  // Create a new sprint
  Future<String> createSprint(String projectId, Map<String, dynamic> sprintData) async {
    try {
      // Add default values
      final data = {
        ...sprintData,
        'progress': 0, // Start with 0% progress
        'backlogItems': [], // Empty array of backlog items
        'createdBy': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('sprints')
          .add(data);

      // Update cache if needed
      if (_projectSprints.containsKey(projectId)) {
        _projectSprints[projectId]!.add({
          'id': docRef.id,
          ...data,
        });
        notifyListeners();
      }

      return docRef.id;
    } catch (e) {
      print('Error creating sprint: $e');
      throw e;
    }
  }

  // Update a sprint
  Future<void> updateSprint(String projectId, String sprintId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('sprints')
          .doc(sprintId)
          .update(data);

      // Update cache if needed
      if (_projectSprints.containsKey(projectId)) {
        final index = _projectSprints[projectId]!.indexWhere((s) => s['id'] == sprintId);
        if (index != -1) {
          _projectSprints[projectId]![index] = {
            ..._projectSprints[projectId]![index],
            ...data,
          };
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating sprint: $e');
      throw e;
    }
  }

  // In SprintService.dart
  Future<void> moveBacklogItemToSprint(String projectId, String backlogId, String sprintId) async {
    try {
      // Start a batch operation for atomic updates
      final batch = _firestore.batch();

      // 1. Update backlog item status and sprintId
      final backlogRef = _firestore
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')  // Changed from 'backlogItems' to 'backlogs'
          .doc(backlogId);

      batch.update(backlogRef, {
        'status': 'In Sprint',
        'sprintId': sprintId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Add backlog item to sprint's backlogItems array
      final sprintRef = _firestore
          .collection('projects')
          .doc(projectId)
          .collection('sprints')
          .doc(sprintId);

      batch.update(sprintRef, {
        'backlogItems': FieldValue.arrayUnion([backlogId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      // Update cache if needed
      notifyListeners();
    } catch (e) {
      print('Error moving backlog item to sprint: $e');
      throw e;
    }
  }

  // Remove a backlog item from a sprint
  Future<void> removeBacklogItemFromSprint(String projectId, String backlogId, String sprintId) async {
    try {
      // Start a batch operation
      final batch = _firestore.batch();
      // 1. Update backlog item status and remove sprintId - FIXED COLLECTION NAME
      final backlogRef = _firestore
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')
          .doc(backlogId);
      batch.update(backlogRef, {
        'status': 'Ready',
        'sprintId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Remove backlog item from sprint's backlogItems array
      final sprintRef = _firestore
          .collection('projects')
          .doc(projectId)
          .collection('sprints')
          .doc(sprintId);

      batch.update(sprintRef, {
        'backlogItems': FieldValue.arrayRemove([backlogId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      // Update cache if needed
      notifyListeners();
    } catch (e) {
      print('Error removing backlog item from sprint: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getSprintBacklogItems(String projectId, String sprintId) async {
    try {
      final backlogItemsQuery = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')  // Changed from 'backlogItems' to 'backlogs'
          .where('sprintId', isEqualTo: sprintId);

      final backlogItemsSnapshot = await backlogItemsQuery.get();

      List<Map<String, dynamic>> items = [];

      for (var doc in backlogItemsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['projectId'] = projectId;

        // Fetch tasks for this backlog item
        final tasksQuery = FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('backlogs')  // Changed from 'backlogItems' to 'backlogs'
            .doc(doc.id)
            .collection('backlogTasks');

        final tasksSnapshot = await tasksQuery.get();

        // Add tasks to the backlog item data
        final tasks = tasksSnapshot.docs.map((taskDoc) {
          final taskData = taskDoc.data();
          taskData['id'] = taskDoc.id;
          taskData['backlogId'] = doc.id;
          return taskData as Map<String, dynamic>;
        }).toList();

        data['tasks'] = tasks;
        items.add(data);
      }

      return items;
    } catch (e) {
      print('Error getting sprint backlog items: $e');
      return [];
    }
  }

  Future<double> calculateSprintProgress(String projectId, String sprintId) async {
    try {
      // Get all backlog items in this sprint
      final backlogItems = await getSprintBacklogItems(projectId, sprintId);

      if (backlogItems.isEmpty) {
        return 0.0;
      }

      int totalTasks = 0;
      int completedTasks = 0;

      // For each backlog item, count its tasks
      for (final backlog in backlogItems) {
        // Use the tasks that were already fetched in getSprintBacklogItems
        if (backlog.containsKey('tasks') && backlog['tasks'] is List) {
          List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(backlog['tasks']);
          totalTasks += tasks.length;

          // Count completed tasks using flexible status matching
          for (final task in tasks) {
            String status = (task['status'] ?? '').toString().toLowerCase();
            // Match against known "done" statuses
            if (status == 'done' ||
                status == 'completed' ||
                status == 'finished' ||
                status == 'closed') {
              completedTasks++;
            }
          }
        }
      }

      // Calculate progress percentage
      if (totalTasks == 0) return 0.0;

      // This gives the exact percentage based on completed tasks
      return (completedTasks / totalTasks) * 100;
    } catch (e) {
      print('Error calculating sprint progress: $e');
      return 0.0;
    }
  }

  // Update sprint progress
  Future<void> updateSprintProgress(String projectId, String sprintId) async {
    try {
      final progress = await calculateSprintProgress(projectId, sprintId);

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('sprints')
          .doc(sprintId)
          .update({
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      print('Error updating sprint progress: $e');
    }
  }

  // Setup a real-time listener for tasks in a sprint
  void listenToSprintTasks(String projectId, String sprintId) {
    // First get all backlog items in this sprint
    getSprintBacklogItems(projectId, sprintId).then((backlogItems) {
      for (final backlog in backlogItems) {
        final tasksPath = _firestore
            .collection('projects')
            .doc(projectId)
            .collection('backlogs')
            .doc(backlog['id'])
            .collection('backlogTasks');

        // Listen for changes in tasks
        tasksPath.snapshots().listen((snapshot) {
          // When tasks change, update sprint progress
          updateSprintProgress(projectId, sprintId);
        });
      }
    });
  }
  // Add this method to your SprintService class

  // In SprintService.dart
  Future<Map<String, dynamic>?> getBacklogItemDetails(String projectId, String backlogItemId) async {
    try {
      // Reference to the project's backlog items - FIXED COLLECTION NAME
      final backlogItemRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')  // Changed from 'backlogItems' to 'backlogs'
          .doc(backlogItemId);

      // Get the document
      final backlogItemDoc = await backlogItemRef.get();

      if (!backlogItemDoc.exists) {
        print('Backlog item not found');
        return null;
      }

      // Get the backlog item data
      final backlogItemData = backlogItemDoc.data()!;

      // Add the ID to the data
      backlogItemData['id'] = backlogItemDoc.id;
      backlogItemData['projectId'] = projectId;

      // Get tasks for this backlog item - FIXED COLLECTION NAME FOR TASKS
      final tasksSnapshot = await backlogItemRef.collection('backlogTasks').get();  // Make sure this matches your task collection name

      // Process tasks
      final tasks = tasksSnapshot.docs.map((taskDoc) {
        final taskData = taskDoc.data();
        taskData['id'] = taskDoc.id;
        taskData['backlogId'] = backlogItemId;
        return taskData;
      }).toList();

      // Add tasks to the backlog item
      backlogItemData['tasks'] = tasks;

      return backlogItemData;
    } catch (e) {
      print('Error getting backlog item details: $e');
      throw e;
    }
  }
  // Add this method to SprintService class
  Future<void> markSprintAsActive(String projectId, String sprintId) async {
    // First, mark all sprints as non-active (Planning or Completed)
    final sprintsRef = FirebaseFirestore.instance.collection('projects/$projectId/sprints');
    final activeSprints = await sprintsRef.where('status', isEqualTo: 'Active').get();

    // Create a batch to update multiple documents atomically
    final batch = FirebaseFirestore.instance.batch();

    // Set all currently active sprints to Planning
    for (var doc in activeSprints.docs) {
      batch.update(doc.reference, {'status': 'Planning'});
    }

    // Set the selected sprint to Active
    batch.update(sprintsRef.doc(sprintId), {'status': 'Active'});

    // Commit the batch
    return batch.commit();
  }

  void setupRealTimeSprintProgress(String projectId, String sprintId) {
    // Listen to all backlog items in the sprint
    FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('backlogs')
        .where('sprintId', isEqualTo: sprintId)
        .snapshots()
        .listen((backlogSnapshot) async {

      // For each backlog item, listen to its tasks
      for (var backlogDoc in backlogSnapshot.docs) {
        FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('backlogs')
            .doc(backlogDoc.id)
            .collection('backlogTasks')
            .snapshots()
            .listen((taskSnapshot) {
          // When any task changes, update sprint progress
          updateSprintProgress(projectId, sprintId);
        });
      }
    });
  }
}