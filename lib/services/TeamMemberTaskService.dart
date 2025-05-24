// lib/services/TeamMemberTaskService.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sprint_service.dart';

class TeamMemberTaskService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _allTasks = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get tasks => _tasks;
  bool get isLoading => _isLoading;

  TeamMemberTaskService() {
    // Initialize by loading tasks
    loadTasks();
  }

  List<Map<String, dynamic>> getAllProjectTasks() {
    return List.from(_allTasks);
  }

  bool isStatusInProgress(String status) {
    final inProgressStatuses = [
      'in progress', 'in-progress', 'progress', 'active', 'working',
      'doing', 'started'
    ];
    return inProgressStatuses.contains(status.toLowerCase().trim());
  }

  bool isStatusDone(String status) {
    final doneStatuses = [
      'done', 'completed', 'finished', 'closed', 'complete'
    ];
    return doneStatuses.contains(status.toLowerCase().trim());
  }

  bool isStatusNotStarted(String status) {
    final notStartedStatuses = [
      'not started', 'to do', 'todo', 'to-do', 'backlog', 'open',
      'new', 'pending'
    ];
    return notStartedStatuses.contains(status.toLowerCase().trim());
  }

  List<Map<String, dynamic>> getTasksByStatus(String status) {
    return _tasks.where((task) {
      final taskStatus = task['status']?.toString() ?? '';

      // Use the standardized status checking methods
      switch (status.toLowerCase()) {
        case 'not started':
          return isStatusNotStarted(taskStatus);
        case 'in progress':
          return isStatusInProgress(taskStatus);
        case 'done':
          return isStatusDone(taskStatus);
        default:
        // Exact match fallback
          return taskStatus.toLowerCase().trim() == status.toLowerCase().trim();
      }
    }).toList();
  }

  // Standard method for categorizing a task status
  String categorizeStatus(String rawStatus) {
    final status = rawStatus.toLowerCase().trim();
    if (isStatusDone(status)) return 'done';
    if (isStatusInProgress(status)) return 'in progress';
    return 'not started';
  }

  // Standard method for calculating workload percentage
  int calculateWorkloadPercentage(int totalTasks, int inProgress, int notStarted) {
    if (totalTasks <= 0) return 0;

    // Weight in-progress tasks more heavily than not-started tasks
    int percentage = ((inProgress * 1.5 + notStarted * 0.5) / totalTasks * 100).round();

    // Cap at 100%
    return percentage > 100 ? 100 : percentage;
  }

  Future<void> loadTasks() async {
    try {
      _isLoading = true;
      notifyListeners();
      _tasks.clear();

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('TeamMemberTaskService: No current user');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final currentUserId = currentUser.uid;
      print('TeamMemberTaskService: Loading tasks for user: $currentUserId');

      // Query projects where user is a member (respects Firestore rules)
      final projectsQuery = await _firestore
          .collection('projects')
          .where('members', arrayContains: currentUserId)
          .get();

      // Also query role-based projects
      final roleProjectsQuery = await _firestore
          .collection('projects')
          .where('roles.teamMembers', arrayContains: currentUserId)
          .get();

      // Combine both query results
      final allProjectDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      allProjectDocs.addAll(projectsQuery.docs);
      allProjectDocs.addAll(roleProjectsQuery.docs);

      // Remove duplicates
      final uniqueProjectDocs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in allProjectDocs) {
        uniqueProjectDocs[doc.id] = doc;
      }

      for (final projectDoc in uniqueProjectDocs.values) {
        final projectData = projectDoc.data();
        final projectId = projectDoc.id;

        try {
          // Get tasks from all backlogs in this project
          final backlogsQuery = await _firestore
              .collection('projects')
              .doc(projectId)
              .collection('backlogs')
              .get();

          for (final backlogDoc in backlogsQuery.docs) {
            final backlogId = backlogDoc.id;
            final backlogData = backlogDoc.data();
            final backlogTitle = backlogData['title'] ?? 'User Story';

            final tasksQuery = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('backlogs')
                .doc(backlogId)
                .collection('backlogTasks')
                .get();

            for (final taskDoc in tasksQuery.docs) {
              final taskData = taskDoc.data();
              final taskId = taskDoc.id;

              // Check if current user is assigned to this task
              bool isAssignedToTask = false;

              // Method 1: Check legacy assignedMembers array
              if (taskData['assignedMembers'] is List) {
                final assignedMembers = taskData['assignedMembers'] as List;
                for (var member in assignedMembers) {
                  if (member.toString() == currentUserId) {
                    isAssignedToTask = true;
                    print('TeamMemberTaskService: Found task via assignedMembers: ${taskData['title']}');
                    break;
                  }
                }
              }

              // Method 2: Check assignedMembersData for sub-teams
              if (!isAssignedToTask && taskData['assignedMembersData'] is List) {
                final assignedMembersData = taskData['assignedMembersData'] as List;

                for (var memberItem in assignedMembersData) {
                  if (memberItem is Map) {
                    final memberData = Map<String, dynamic>.from(memberItem);

                    // Check if this is a sub-team with members array
                    if (memberData['members'] is List) {
                      final members = memberData['members'] as List;

                      // Check if current user is in this sub-team
                      for (var subMemberItem in members) {
                        if (subMemberItem is Map) {
                          final subMember = Map<String, dynamic>.from(subMemberItem);
                          if (subMember['id'] == currentUserId) {
                            isAssignedToTask = true;
                            print('TeamMemberTaskService: Found task via sub-team: ${taskData['title']} in sub-team: ${memberData['name']}');
                            break;
                          }
                        }
                      }

                      if (isAssignedToTask) break;
                    } else {
                      // Check if this is an individual assignment
                      if (memberData['id'] == currentUserId) {
                        isAssignedToTask = true;
                        print('TeamMemberTaskService: Found task via individual assignment: ${taskData['title']}');
                        break;
                      }
                    }
                  }
                }
              }

              if (isAssignedToTask) {
                final task = {
                  'id': taskId,
                  'projectId': projectId,
                  'backlogId': backlogId,
                  'project': projectData['name'] ?? 'Unknown Project',
                  'backlogTitle': backlogTitle,  // Add parent story title
                  'storyTitle': backlogTitle,    // Add for compatibility
                  ...taskData,
                };

                _tasks.add(task);
                print('TeamMemberTaskService: Added task: ${task['title']} from story: $backlogTitle');
              }
            }
          }
        } catch (e) {
          print('Error processing project $projectId: $e');
        }
      }

      print('TeamMemberTaskService: Loaded ${_tasks.length} total tasks');
      _isLoading = false;
      notifyListeners();

    } catch (e) {
      print('TeamMemberTaskService: Error loading tasks: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get all tasks
  List<Map<String, dynamic>> getAllTasks() {
    return List.from(_tasks);
  }

  // Get tasks for display in home view
  List<Map<String, dynamic>> getTasksForHomeView() {
    // If we have less than 5 tasks, return all of them
    if (_tasks.length <= 5) {
      return List.from(_tasks);
    }

    // Otherwise, sort by due date and return the first 5
    final sortedTasks = List.from(_tasks);
    sortedTasks.sort((a, b) {
      final aDate = a['dueDate'] != 'No date' ? a['dueDate'] : '9999-99-99';
      final bDate = b['dueDate'] != 'No date' ? b['dueDate'] : '9999-99-99';
      return aDate.compareTo(bDate); // Earlier dates first
    });

    // Create a new list with just the first 5 items
    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < 5 && i < sortedTasks.length; i++) {
      result.add(sortedTasks[i]);
    }

    return result;
  }

  // Get a task by ID
  Map<String, dynamic>? getTaskById(String id) {
    final taskIndex = _tasks.indexWhere((task) => task['id'] == id);
    if (taskIndex != -1) {
      return _tasks[taskIndex];
    }
    return null;
  }

  // Update an existing task
  Future<void> updateTask(String taskId, Map<String, dynamic> updatedData) async {
    try {
      final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        final projectId = task['projectId'];
        final backlogId = task['backlogId'];

        if (projectId != null && backlogId != null) {
          // Prepare update data (remove fields that shouldn't be updated directly)
          final updateData = Map<String, dynamic>.from(updatedData);
          updateData.remove('id');
          updateData.remove('projectId');
          updateData.remove('backlogId');
          updateData.remove('project');
          updateData.remove('backlogTitle');
          updateData['updatedAt'] = FieldValue.serverTimestamp();

          // Update in Firestore
          await _firestore
              .collection('projects')
              .doc(projectId)
              .collection('backlogs')
              .doc(backlogId)
              .collection('backlogTasks')
              .doc(taskId)
              .update(updateData);

          // Update local state
          _tasks[taskIndex] = {
            ..._tasks[taskIndex],
            ...updatedData,
          };

          notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  Future<void> updateTaskAssignedMembers(
      String projectId,
      String backlogId,
      String taskId,
      List<Map<String, dynamic>> assignedMembers
      ) async {
    try {
      print('TeamMemberTaskService: Updating assigned members');
      print('- projectId: "$projectId"');
      print('- backlogId: "$backlogId"');
      print('- taskId: "$taskId"');
      print('- members count: ${assignedMembers.length}');

      // Check for empty IDs
      if (projectId.isEmpty || backlogId.isEmpty || taskId.isEmpty) {
        print('TeamMemberTaskService ERROR: Missing required IDs');
        throw Exception('Missing required IDs to save');
      }

      // Format members data for storage
      final List<String> memberIds = assignedMembers
          .where((member) => member.containsKey('id') && member['id'] != null)
          .map((member) => member['id'] as String)
          .toList();

      // Update the task
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')
          .doc(backlogId)
          .collection('backlogTasks')
          .doc(taskId)
          .update({
        'assignedMembers': memberIds,
        'assignedMembersData': assignedMembers,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('TeamMemberTaskService: Successfully updated assigned members');

      // Update local state if this task exists in our cache
      final taskIndex = _tasks.indexWhere((task) =>
      task['id'] == taskId &&
          task['projectId'] == projectId &&
          task['backlogId'] == backlogId);

      if (taskIndex != -1) {
        _tasks[taskIndex] = {
          ..._tasks[taskIndex],
          'assignedMembers': memberIds,
          'assignedMembersData': assignedMembers,
        };
        notifyListeners();
      }

    } catch (e) {
      print('TeamMemberTaskService ERROR updating assigned members: $e');
      throw e; // Re-throw to let the UI handle it
    }
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await updateMemberTaskStatus(taskId, newStatus);
    try {
      print("TeamMemberTaskService: Attempting to update task $taskId to status '$newStatus'");

      // Find the task
      final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);

      if (taskIndex == -1) {
        print("TeamMemberTaskService: Task not found with ID $taskId");
        throw Exception("Task not found");
      }

      final task = _tasks[taskIndex];
      print("TeamMemberTaskService: Found task: ${task['title']}");

      final projectId = task['projectId'];
      final backlogId = task['backlogId'];

      // Update in Firestore
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')
          .doc(backlogId)
          .collection('backlogTasks')
          .doc(taskId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update in local state
      _tasks[taskIndex] = {
        ..._tasks[taskIndex],
        'status': newStatus,
        'isCompleted': isStatusDone(newStatus.toLowerCase().trim()),
      };

      notifyListeners();
      print("TeamMemberTaskService: Successfully updated task status to '$newStatus'");
    } catch (e) {
      print("TeamMemberTaskService ERROR: Failed to update task status: $e");
      throw e; // Re-throw to let the UI handle it
    }
  }

  // New method for getting team members with tasks for Scrum Master view
  Future<List<Map<String, dynamic>>> getTeamMembersWithTasks(String? projectId) async {
    try {
      if (projectId == null || projectId.isEmpty) {
        return [];
      }

      // Get project members first
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) {
        return [];
      }

      final projectData = projectDoc.data() as Map<String, dynamic>;
      final List<dynamic> memberIds = projectData['members'] ?? [];

      if (memberIds.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> teamMembers = [];

      // Fetch each user and check if they have "Team Member" role
      for (String memberId in List<String>.from(memberIds)) {
        final userDoc = await _firestore.collection('users').doc(memberId).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final String userRole = userData['role'] ?? '';

          // Only process users with "Team Member" role
          if (userRole == 'Team Member') {
            // Get all tasks for this project
            final backlogsSnapshot = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('backlogs')
                .get();

            int totalTasks = 0;
            int notStarted = 0;
            int inProgress = 0;
            int done = 0;
            List<int> dailyWorkload = [0, 0, 0, 0, 0, 0, 0]; // Sun to Sat
            List<Map<String, dynamic>> currentTasks = [];

            // Process each backlog to find tasks
            for (var backlogDoc in backlogsSnapshot.docs) {
              final backlogId = backlogDoc.id;
              final backlogData = backlogDoc.data() as Map<String, dynamic>;
              final backlogTitle = backlogData['title'] ?? 'Unknown Backlog';

              final tasksSnapshot = await _firestore
                  .collection('projects')
                  .doc(projectId)
                  .collection('backlogs')
                  .doc(backlogId)
                  .collection('backlogTasks')
                  .get();

              // Process each task
              for (var taskDoc in tasksSnapshot.docs) {
                final taskData = taskDoc.data() as Map<String, dynamic>;

                // Check if task is assigned to this team member
                final assignedTo = taskData['assignedTo'];
                final assignedMembers = taskData['assignedMembers'] ?? [];

                bool isAssigned = false;

                // Check assignedTo field
                if (assignedTo == memberId) {
                  isAssigned = true;
                }

                // Check assignedMembers array
                if (assignedMembers is List && assignedMembers.contains(memberId)) {
                  isAssigned = true;
                }

                if (isAssigned) {
                  totalTasks++;

                  // Count tasks by status using standardized helpers
                  final String status = (taskData['status'] ?? '').toString().toLowerCase();

                  if (isStatusDone(status)) {
                    done++;
                  } else if (isStatusInProgress(status)) {
                    inProgress++;
                  } else {
                    // Default to not started
                    notStarted++;
                  }

                  // Process due date for workload heatmap
                  if (taskData['dueDate'] != null) {
                    try {
                      final dueDate = taskData['dueDate'] is Timestamp
                          ? (taskData['dueDate'] as Timestamp).toDate()
                          : DateTime.parse(taskData['dueDate'].toString());

                      // Get day of week (0 = Sunday, 6 = Saturday)
                      final dayOfWeek = dueDate.weekday % 7;
                      dailyWorkload[dayOfWeek]++;
                    } catch (e) {
                      print("Error processing due date: $e");
                    }
                  }

                  // Add to current tasks list
                  currentTasks.add({
                    'id': taskDoc.id,
                    'title': taskData['title'] ?? 'Untitled Task',
                    'description': taskData['description'] ?? '',
                    'status': taskData['status'] ?? 'To Do',
                    'priority': taskData['priority'] ?? 'Medium',
                    'dueDate': taskData['dueDate'],
                    'projectId': projectId,
                    'backlogId': backlogId,
                    'backlogTitle': backlogTitle,
                  });
                }
              }
            }

            // Calculate workload percentage using standard formula
            int workloadPercentage = calculateWorkloadPercentage(totalTasks, inProgress, notStarted);

            // Create team member data structure
            String userName = userData['name'] ?? 'Unknown User';
            String userAvatar = userName.isNotEmpty
                ? userName.substring(0, min(2, userName.length)).toUpperCase()
                : 'UN';

            teamMembers.add({
              'id': memberId,
              'name': userName,
              'role': 'Team Member',
              'avatar': userAvatar,
              'totalTasks': totalTasks,
              'notStarted': notStarted,
              'inProgress': inProgress,
              'done': done,
              'workloadPercentage': workloadPercentage,
              'dailyWorkload': dailyWorkload,
              'currentTasks': currentTasks,
            });
          }
        }
      }

      return teamMembers;

    } catch (e) {
      print('Error getting team members with tasks: $e');
      return [];
    }
  }

  // New method for Team Member screen
  Future<Map<String, dynamic>> getCurrentUserWorkload(String? projectId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return _getEmptyWorkloadData();
      }

      int totalTasks = 0;
      int notStarted = 0;
      int inProgress = 0;
      int done = 0;
      List<int> dailyWorkload = [0, 0, 0, 0, 0, 0, 0]; // Sun to Sat
      List<Map<String, dynamic>> currentTasks = [];

      // Get projects query
      Query projectsQuery = _firestore.collection('projects').where('members', arrayContains: user.uid);
      if (projectId != null && projectId.isNotEmpty) {
        // For filtering by specific project
        projectsQuery = _firestore.collection('projects').where(FieldPath.documentId, isEqualTo: projectId);
      }

      final projectsSnapshot = await projectsQuery.get();

      // Process each project
      for (var projectDoc in projectsSnapshot.docs) {
        final currentProjectId = projectDoc.id;
        final projectData = projectDoc.data() as Map<String, dynamic>;
        final projectName = projectData['name'] ?? 'Unknown Project';

        // Check if this project has the user as member
        final List<dynamic> members = projectData['members'] ?? [];
        if (!members.contains(user.uid)) {
          continue; // Skip if user is not a member
        }

        // Get all backlogs in this project
        final backlogsSnapshot = await _firestore
            .collection('projects')
            .doc(currentProjectId)
            .collection('backlogs')
            .get();

        // Process each backlog
        for (var backlogDoc in backlogsSnapshot.docs) {
          final backlogId = backlogDoc.id;
          final backlogData = backlogDoc.data() as Map<String, dynamic>;
          final backlogTitle = backlogData['title'] ?? 'Unknown Backlog';

          // Get tasks for this backlog
          final tasksSnapshot = await _firestore
              .collection('projects')
              .doc(currentProjectId)
              .collection('backlogs')
              .doc(backlogId)
              .collection('backlogTasks')
              .get();

          // Process each task
          for (var taskDoc in tasksSnapshot.docs) {
            final taskData = taskDoc.data() as Map<String, dynamic>;

            // Check if this task is assigned to the current user
            final assignedTo = taskData['assignedTo'];
            final assignedMembers = taskData['assignedMembers'] ?? [];

            bool isAssigned = false;

            // Check assignedTo field
            if (assignedTo == user.uid) {
              isAssigned = true;
            }

            // Check assignedMembers array
            if (assignedMembers is List && assignedMembers.contains(user.uid)) {
              isAssigned = true;
            }

            if (isAssigned) {
              totalTasks++;

              // Categorize task status using standard helper methods
              final String status = (taskData['status'] ?? '').toString().toLowerCase();

              if (isStatusDone(status)) {
                done++;
              } else if (isStatusInProgress(status)) {
                inProgress++;
              } else {
                notStarted++;
              }

              // Add to daily workload if due date exists
              if (taskData['dueDate'] != null) {
                try {
                  final dueDate = taskData['dueDate'] is Timestamp
                      ? (taskData['dueDate'] as Timestamp).toDate()
                      : DateTime.parse(taskData['dueDate'].toString());

                  // Get day of week (0 = Sunday, 6 = Saturday)
                  final dayOfWeek = dueDate.weekday % 7;
                  dailyWorkload[dayOfWeek]++;
                } catch (e) {
                  print("Error processing due date: $e");
                }
              }

              // Add to current tasks
              currentTasks.add({
                'id': taskDoc.id,
                'title': taskData['title'] ?? 'Untitled Task',
                'description': taskData['description'] ?? '',
                'status': taskData['status'] ?? 'To Do',
                'priority': taskData['priority'] ?? 'Medium',
                'dueDate': taskData['dueDate'],
                'projectId': currentProjectId,
                'projectName': projectName,
                'backlogId': backlogId,
                'backlogTitle': backlogTitle,
              });
            }
          }
        }
      }

      // Calculate workload percentage
      int workloadPercentage = calculateWorkloadPercentage(totalTasks, inProgress, notStarted);

      // Get user data for avatar
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.exists ? (userDoc.data() as Map<String, dynamic>) : <String, dynamic>{};
      final userName = userData['name'] ?? 'User';
      final userAvatar = userName.isNotEmpty
          ? userName.substring(0, min(2, userName.length)).toUpperCase()
          : 'UN';

      // Return workload data
      return {
        'id': user.uid,
        'name': userName,
        'avatar': userAvatar,
        'totalTasks': totalTasks,
        'notStarted': notStarted,
        'inProgress': inProgress,
        'done': done,
        'workloadPercentage': workloadPercentage,
        'dailyWorkload': dailyWorkload,
        'currentTasks': currentTasks,
      };
    } catch (e) {
      print('Error getting current user workload: $e');
      return _getEmptyWorkloadData();
    }
  }

  // Helper method to get empty workload data
  Map<String, dynamic> _getEmptyWorkloadData() {
    return {
      'id': '',
      'name': 'Unknown User',
      'avatar': 'UN',
      'totalTasks': 0,
      'notStarted': 0,
      'inProgress': 0,
      'done': 0,
      'workloadPercentage': 0,
      'dailyWorkload': [0, 0, 0, 0, 0, 0, 0],
      'currentTasks': [],
    };
  }

  Future<List<Map<String, dynamic>>> getTeamIssues(String? projectId) async {
    try {
      if (projectId == null) {
        return [];
      }

      final QuerySnapshot issuesSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('workloadFlags') // Changed from top-level collection
          .orderBy('timestamp', descending: true)
          .get();

      print('Found ${issuesSnapshot.docs.length} workload flags for project $projectId');

      return issuesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Convert Firestore Timestamp to DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestampDate'] = (data['timestamp'] as Timestamp).toDate();
        } else {
          data['timestampDate'] = DateTime.now(); // Fallback
        }

        // Add the document ID
        data['id'] = doc.id;

        return data;
      }).toList();
    } catch (e) {
      print('Error getting team issues: $e');
      return [];
    }
  }

  Future<void> loadAllProjectTasks() async {
    try {
      _isLoading = true;
      notifyListeners();
      _allTasks.clear(); // Clear the ALL tasks list, not _tasks

      final user = _auth.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      print("TeamMemberTaskService: Loading ALL tasks for Scrum Master projects");

      // Query projects where user is Scrum Master or Product Owner
      final smProjectsQuery = await _firestore
          .collection('projects')
          .where('roles.scrumMasters', arrayContains: user.uid)
          .get();

      final poProjectsQuery = await _firestore
          .collection('projects')
          .where('roles.productOwner', isEqualTo: user.uid)
          .get();

      // Also include legacy member projects
      final memberProjectsQuery = await _firestore
          .collection('projects')
          .where('members', arrayContains: user.uid)
          .get();

      // Combine all projects
      final allProjectDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      allProjectDocs.addAll(smProjectsQuery.docs);
      allProjectDocs.addAll(poProjectsQuery.docs);
      allProjectDocs.addAll(memberProjectsQuery.docs);

      // Remove duplicates
      final uniqueProjectDocs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in allProjectDocs) {
        uniqueProjectDocs[doc.id] = doc;
      }

      print("TeamMemberTaskService: Found ${uniqueProjectDocs.length} managed projects");

      // For each project, get all backlog items
      for (var projectDoc in uniqueProjectDocs.values) {
        final projectId = projectDoc.id;
        final projectData = projectDoc.data();
        final projectName = projectData['name'] ?? 'Unknown Project';

        // Get all backlog items in this project
        final backlogsSnapshot = await _firestore
            .collection('projects')
            .doc(projectId)
            .collection('backlogs')
            .get();

        print("TeamMemberTaskService: Found ${backlogsSnapshot.docs.length} backlogs in project $projectName");

        // For each backlog item, get all tasks
        for (var backlogDoc in backlogsSnapshot.docs) {
          final backlogId = backlogDoc.id;
          final backlogData = backlogDoc.data();
          final backlogTitle = backlogData['title'] ?? 'Unknown Backlog';

          // Get tasks for this backlog item
          final tasksSnapshot = await _firestore
              .collection('projects')
              .doc(projectId)
              .collection('backlogs')
              .doc(backlogId)
              .collection('backlogTasks')
              .get();

          print("TeamMemberTaskService: Found ${tasksSnapshot.docs.length} tasks in backlog $backlogTitle");

          // Process each task - include ALL tasks, not just assigned ones
          for (var taskDoc in tasksSnapshot.docs) {
            final taskData = taskDoc.data();

            // Format due date if present
            String formattedDueDate = 'No date';
            if (taskData['dueDate'] != null) {
              try {
                final dueDate = taskData['dueDate'] is Timestamp
                    ? (taskData['dueDate'] as Timestamp).toDate()
                    : DateTime.parse(taskData['dueDate'].toString());

                formattedDueDate = DateFormat('dd-MM-yyyy').format(dueDate);
              } catch (e) {
                print("Error formatting date: ${taskData['dueDate']} - $e");
              }
            }

            // Add this task to _allTasks list (not _tasks)
            _allTasks.add({
              'id': taskDoc.id,
              'title': taskData['title'] ?? 'Untitled Task',
              'description': taskData['description'] ?? '',
              'status': taskData['status'] ?? 'To Do',
              'priority': taskData['priority'] ?? 'Medium',
              'dueDate': formattedDueDate,
              'projectId': projectId,
              'project': projectName,
              'backlogId': backlogId,
              'backlogTitle': backlogTitle,
              'assignedTo': taskData['assignedTo'],
              'isCompleted': isStatusDone((taskData['status'] ?? '').toString().toLowerCase()),
              'what': taskData['what'] ?? '',
              'why': taskData['why'] ?? '',
              'how': taskData['how'] ?? '',
              'acceptanceCriteria': taskData['acceptanceCriteria'] ?? '',
              'storyTitle': backlogTitle,
              'assignedMembersData': taskData['assignedMembersData'] ?? [],
              'attachments': taskData['attachments'] ?? [],
            });

            print("TeamMemberTaskService: Added task to _allTasks: ${taskDoc.id}");
          }
        }
      }

      print("TeamMemberTaskService: Loaded ${_allTasks.length} total tasks for SM view");
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('TeamMemberTaskService: Error loading all tasks: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reportWorkloadIssue(String projectId, String explanation, String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userName = userDoc.data()?['name'] ?? 'Unknown User';


      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('workloadFlags')
          .add({
        'userId': currentUser.uid,
        'userName': userName,
        'explanation': explanation,
        'timestamp': DateTime.now(),
        'status': 'pending', // pending, reviewed, resolved
      });

      print('Workload issue reported successfully');
    } catch (e) {
      print('Error reporting workload issue: $e');
      throw e;
    }
  }
  // This should be in TeamMemberTaskService.dart
  Future<void> updateWorkloadIssueStatus(String projectId, String issueId, String newStatus) async {
    try {
      // Debug logs
      print('Updating workload flag: projectId=$projectId, issueId=$issueId, newStatus=$newStatus');

      // Update the document
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('workloadFlags')
          .doc(issueId)
          .update({
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('Successfully updated workload flag status to $newStatus');
    } catch (e) {
      print('Error updating workload flag status: $e');
      throw e;
    }
  }
  Future<List<Map<String, dynamic>>> getResolvedIssues(String? projectId) async {
    try {
      if (projectId == null) {
        print('Project ID is null, cannot load resolved issues');
        return [];
      }

      print('Fetching resolved issues for project: $projectId');

      // Query only resolved issues
      final QuerySnapshot issuesSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('workloadFlags')
          .where('status', isEqualTo: 'resolved')
          .get();

      print('Found ${issuesSnapshot.docs.length} issues with status="resolved"');

      // Let's also check how many total issues exist
      final QuerySnapshot allIssuesSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('workloadFlags')
          .get();

      print('Total issues in collection: ${allIssuesSnapshot.docs.length}');

      // If we have issues but none are resolved, log their statuses
      if (allIssuesSnapshot.docs.isNotEmpty && issuesSnapshot.docs.isEmpty) {
        print('Found issues with other statuses:');
        for (var doc in allIssuesSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print('- Issue ${doc.id} has status: ${data['status']}');
        }
      }

      List<Map<String, dynamic>> result = issuesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Convert Firestore Timestamp to DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestampDate'] = (data['timestamp'] as Timestamp).toDate();
        } else {
          data['timestampDate'] = DateTime.now();
        }

        if (data['statusUpdatedAt'] is Timestamp) {
          data['statusUpdatedAt'] = (data['statusUpdatedAt'] as Timestamp).toDate();
        }

        // Add the document ID
        data['id'] = doc.id;

        return data;
      }).toList();

      return result;
    } catch (e) {
      print('Error getting resolved issues: $e');
      return [];
    }
  }

/// Add to TeamMemberTaskService.dart
  String getWorkloadStatus(int percentage) {
    if (percentage <= 30) {
      return 'Low';
    } else if (percentage <= 70) {
      return 'Moderate';
    } else {
      return 'High';
    }
  }

// Calculate the current workload percentage based on tasks
  int getCurrentWorkloadPercentage() {
    if (_tasks.isEmpty) return 0;

    int totalTasks = _tasks.length;
    int inProgressCount = 0;
    int notStartedCount = 0;

    for (var task in _tasks) {
      String status = (task['status'] ?? '').toString().toLowerCase();

      if (isStatusInProgress(status)) {
        inProgressCount++;
      } else if (isStatusNotStarted(status)) {
        notStartedCount++;
      }
    }

    return calculateWorkloadPercentage(totalTasks, inProgressCount, notStartedCount);
  }

  Color getWorkloadColor(int percentage) {
    if (percentage < 50) {
      return Color(0xFF4CAF50); // Green
    } else if (percentage < 80) {
      return Color(0xFFFF9800); // Orange
    } else {
      return Color(0xFFF44336); // Red
    }
  }

  Future<List<Map<String, dynamic>>> getTaskAssignedMembers(
      String projectId,
      String backlogId,
      String taskId,
      ) async {
    try {
      print('TeamMemberTaskService: Getting assigned members for task $taskId');

      final taskDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')
          .doc(backlogId)
          .collection('backlogTasks')
          .doc(taskId)
          .get();

      if (!taskDoc.exists || taskDoc.data() == null) {
        print('Task document not found');
        return [];
      }

      final taskData = taskDoc.data()!;

      if (!taskData.containsKey('assignedMembersData') || taskData['assignedMembersData'] == null) {
        print('No assigned members data found in task');
        return [];
      }

      final assignedMembersData = taskData['assignedMembersData'] as List<dynamic>;
      final List<Map<String, dynamic>> assignedMembers = assignedMembersData
          .map((member) => Map<String, dynamic>.from(member))
          .toList();

      print('Retrieved ${assignedMembers.length} assigned members');
      return assignedMembers;
    } catch (e) {
      print('Error getting assigned members: $e');
      return [];
    }
  }
  // Add these methods to your TeamMemberTaskService class

  /// Calculate overall task status based on member statuses
  String calculateTaskStatus(Map<String, String> memberStatuses) {
    if (memberStatuses.isEmpty) return 'Not Started';

    final statusCounts = <String, int>{};
    final totalMembers = memberStatuses.length;

    // Count status votes
    for (var status in memberStatuses.values) {
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    // If all members agree on a status, use that
    for (var entry in statusCounts.entries) {
      if (entry.value == totalMembers) {
        return entry.key; // Full consensus
      }
    }

    // Priority-based consensus rules:
    // 1. If any member is "In Progress", task is "In Progress"
    // 2. If any member is "Not Started", task stays "Not Started"
    // 3. Otherwise, use majority

    if (statusCounts.containsKey('In Progress')) {
      return 'In Progress';
    }

    if (statusCounts.containsKey('Not Started')) {
      return 'Not Started';
    }

    // Return majority status
    var maxCount = 0;
    var majorityStatus = 'Not Started';
    for (var entry in statusCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        majorityStatus = entry.key;
      }
    }

    return majorityStatus;
  }

  // ADD OR REPLACE this method in your TeamMemberTaskService.dart
  Future<void> updateMemberTaskStatus(String taskId, String newStatus) async {
    try {
      print('TeamMemberTaskService: Updating task $taskId to status: $newStatus');

      // Find the task in our local cache first
      final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
      if (taskIndex == -1) {
        print('TeamMemberTaskService: Task $taskId not found in local cache');
        throw Exception('Task not found');
      }

      final task = _tasks[taskIndex];
      final projectId = task['projectId'];
      final backlogId = task['backlogId'];

      if (projectId == null || backlogId == null) {
        throw Exception('Missing project or backlog ID');
      }

      print('TeamMemberTaskService: Updating task in Firestore...');
      print('- Project ID: $projectId');
      print('- Backlog ID: $backlogId');
      print('- Task ID: $taskId');
      print('- New Status: $newStatus');

      // Update the task in Firestore
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')
          .doc(backlogId)
          .collection('backlogTasks')
          .doc(taskId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local cache
      _tasks[taskIndex]['status'] = newStatus;

      print('TeamMemberTaskService: Successfully updated task status');
      notifyListeners();

    } catch (e) {
      print('TeamMemberTaskService: Error updating task status: $e');
      throw e;
    }
  }

  /// Get current user's individual status for a task
  String getCurrentUserTaskStatus(String taskId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 'Not Started';

    final currentUserId = currentUser.uid;
    final task = getTaskById(taskId);

    if (task == null) return 'Not Started';

    // Check if task has member statuses
    if (task.containsKey('memberStatuses') && task['memberStatuses'] is Map) {
      final memberStatuses = Map<String, dynamic>.from(task['memberStatuses']);
      return memberStatuses[currentUserId]?.toString() ?? 'Not Started';
    }

    // Fall back to overall task status
    return task['status']?.toString() ?? 'Not Started';
  }

  /// Check if a task is assigned to a sub-team
  bool isSubTeamTask(String taskId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final currentUserId = currentUser.uid;
    final task = getTaskById(taskId);

    if (task == null) return false;

    if (task.containsKey('assignedMembersData') && task['assignedMembersData'] is List) {
      final assignedMembersData = task['assignedMembersData'] as List;

      for (var memberItem in assignedMembersData) {
        if (memberItem is Map) {
          final memberData = Map<String, dynamic>.from(memberItem);

          // Check if this is a sub-team with members array
          if (memberData.containsKey('members') && memberData['members'] is List) {
            final members = memberData['members'] as List;

            // Check if current user is in this sub-team and there are multiple members
            bool currentUserInTeam = false;
            for (var subMemberItem in members) {
              if (subMemberItem is Map) {
                final subMember = Map<String, dynamic>.from(subMemberItem);
                if (subMember['id'] == currentUserId) {
                  currentUserInTeam = true;
                  break;
                }
              }
            }

            if (currentUserInTeam && members.length > 1) {
              return true; // This is a sub-team with multiple members
            }
          }
        }
      }
    }

    return false;
  }

  /// Get team member statuses for a sub-team task
  Map<String, String> getTeamMemberStatuses(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) return {};

    if (task.containsKey('memberStatuses') && task['memberStatuses'] is Map) {
      final memberStatuses = Map<String, dynamic>.from(task['memberStatuses']);
      return memberStatuses.map((key, value) => MapEntry(key, value.toString()));
    }

    return {};
  }


}