import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AuthService.dart';

class ProjectService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Empty list for projects
  final List<Map<String, dynamic>> _projects = [];

  // Map to store Firestore document IDs for each project ID
  final Map<String, String> _projectFirestoreIds = {};

  ProjectService() {
    // Initialize by attempting to fetch from Firebase
    _initProjects();
  }

  Future<void> _initProjects() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print('Fetching projects for user: ${user.uid}');

      _projects.clear();
      _projectFirestoreIds.clear();

      final allDocs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

      // 1. Product Owner query
      final productOwnerQuery = await _firestore
          .collection('projects')
          .where('roles.productOwner', isEqualTo: user.uid)
          .get();
      print('Retrieved ${productOwnerQuery.docs.length} projects as Product Owner');
      for (var doc in productOwnerQuery.docs) allDocs[doc.id] = doc;

      // 2. Scrum Master query
      final scrumMasterQuery = await _firestore
          .collection('projects')
          .where('roles.scrumMasters', arrayContains: user.uid)
          .get();
      print('Retrieved ${scrumMasterQuery.docs.length} projects as Scrum Master');
      for (var doc in scrumMasterQuery.docs) allDocs[doc.id] = doc;

      // 3. Team Member query
      final teamMemberQuery = await _firestore
          .collection('projects')
          .where('roles.teamMembers', arrayContains: user.uid)
          .get();
      print('Retrieved ${teamMemberQuery.docs.length} projects as Team Member');
      for (var doc in teamMemberQuery.docs) allDocs[doc.id] = doc;

      // 4. Client query
      final clientQuery = await _firestore
          .collection('projects')
          .where('roles.clients', arrayContains: user.uid)
          .get();
      print('Retrieved ${clientQuery.docs.length} projects as Client');
      for (var doc in clientQuery.docs) allDocs[doc.id] = doc;

      // 5. Legacy Members query
      final membersQuery = await _firestore
          .collection('projects')
          .where('members', arrayContains: user.uid)
          .get();
      print('Retrieved ${membersQuery.docs.length} projects from legacy members array');
      for (var doc in membersQuery.docs) allDocs[doc.id] = doc;

      // Process all documents
      if (allDocs.isNotEmpty) {
        for (var doc in allDocs.values) {
          final data = doc.data();
          final projectData = {
            'id': doc.id,
            'firestoreId': doc.id,
            'name': data['name'] ?? 'Unnamed Project',
            'title': data['name'] ?? 'Unnamed Project',
            'description': data['description'] ?? '',
            'startDate': data['startDate'] ?? '',
            'endDate': data['endDate'] ?? '',
            'dueDate': data['endDate'] ?? '',
            'status': data['status'] ?? 'In Progress',
            'progress': data['progress'] ?? 0.0,
            'members': data['members'] ?? [user.uid],
            'roles': data['roles'] ?? {},
            'createdBy': data['createdBy'] ?? user.uid,
          };

          _projects.add(projectData);
          _projectFirestoreIds[projectData['id']] = doc.id;
        }

        print('Total projects loaded: ${_projects.length}');
        notifyListeners();
      } else {
        print('No projects found for user');
      }
    } catch (e) {
      print('Error loading projects from Firebase: $e');
    }
  }

  // Original getter - behavior remains the same
  List<Map<String, dynamic>> get projects => _projects;

  // Get Firestore document ID for a project
  String getFirestoreId(String projectId) {
    // First check if we have it in our mapping
    if (_projectFirestoreIds.containsKey(projectId)) {
      return _projectFirestoreIds[projectId]!;
    }

    // If not, look through projects
    for (var project in _projects) {
      if (project['id'] == projectId && project.containsKey('firestoreId')) {
        return project['firestoreId'];
      }
    }

    // If still not found, it might be a Firestore ID already
    return projectId;
  }

  // Add method to update project
  Future<void> updateProject(String id, Map<String, dynamic> updatedProject) async {
    final index = _projects.indexWhere((project) => project['id'] == id);
    if (index != -1) {
      // Update local state first
      _projects[index] = {
        ...updatedProject,
        'id': id,
        'firestoreId': _projects[index]['firestoreId'],
      };
      notifyListeners();

      try {
        // Then try to update Firebase
        final user = _auth.currentUser;
        if (user != null) {
          final firestoreId = getFirestoreId(id);

          // Keep the current user in the members array
          if (!updatedProject.containsKey('members')) {
            updatedProject['members'] = [user.uid];
          } else if (updatedProject['members'] is List && !(updatedProject['members'] as List).contains(user.uid)) {
            (updatedProject['members'] as List).add(user.uid);
          }

          await _firestore.collection('projects').doc(firestoreId).update({
            'name': updatedProject['name'],
            'description': updatedProject['description'],
            'startDate': updatedProject['startDate'],
            'endDate': updatedProject['endDate'],
            'status': updatedProject['status'],
            'progress': updatedProject['progress'] ?? 0.0,
            'members': updatedProject['members'],
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        // Continue with local update on error
        print('Error updating project in Firebase: $e');
      }
    }
  }

  // Add method to delete project
  Future<void> deleteProject(String id) async {
    // Update local state first
    _projects.removeWhere((project) => project['id'] == id);
    notifyListeners();

    try {
      // Then try to delete from Firebase
      final user = _auth.currentUser;
      if (user != null) {
        final firestoreId = getFirestoreId(id);
        await _firestore.collection('projects').doc(firestoreId).delete();
        // Remove from mapping
        _projectFirestoreIds.remove(id);
      }
    } catch (e) {
      // Continue with local deletion on error
      print('Error deleting project from Firebase: $e');
    }
  }

  // Get project by ID
  Map<String, dynamic>? getProjectById(String id) {
    try {
      return _projects.firstWhere((project) => project['id'] == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getProjectBacklogs(String projectId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Get the Firestore document ID for this project
      final firestoreId = getFirestoreId(projectId);

      final snapshot = await _firestore
          .collection('projects')
          .doc(firestoreId)
          .collection('backlogs')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'backlogTasks': [], // Initialize empty backlogTasks array
        };
      }).toList();
    } catch (e) {
      print('Error getting project backlogs: $e');
      // Return empty list on error
      return [];
    }
  }

  // Add a new backlog item to a project
  Future<Map<String, dynamic>?> addBacklogItem(
      String projectId, Map<String, dynamic> backlogData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      print('Adding backlog item for project ID: $projectId');

      // Check if the project exists in Firestore
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();

      if (!projectDoc.exists) {
        print('Project document does not exist in Firestore: $projectId');

        // If the project doesn't exist in Firestore, create it first
        final projectData = getProjectById(projectId);
        if (projectData != null) {
          print('Creating missing project in Firestore with ID: $projectId');

          await _firestore.collection('projects').doc(projectId).set({
            'id': projectId,
            'name': projectData['name'],
            'description': projectData['description'] ?? '',
            'startDate': projectData['startDate'] ?? '',
            'endDate': projectData['endDate'] ?? '',
            'status': projectData['status'] ?? 'In Progress',
            'createdBy': user.uid,
            'members': [user.uid],
            'createdAt': FieldValue.serverTimestamp(),
          });

          print('Successfully created missing project in Firestore');
        } else {
          print('Project not found in local data either.');
          return null;
        }
      }

      // Add created info
      final dataToSave = {
        ...backlogData,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
      };

      print('Adding backlog item to Firestore');

      // Add the document to Firestore
      final docRef = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')
          .add(dataToSave);

      print('Successfully added backlog with ID: ${docRef.id}');

      // Return the new backlog with ID
      return {
        ...backlogData,
        'id': docRef.id,
        'backlogTasks': [],
      };
    } catch (e) {
      print('Error adding backlog item: $e');
      return null;
    }
  }

  // Update backlog item
  Future<bool> updateBacklogItem(
      String projectId, String backlogId, Map<String, dynamic> updates) async {
    try {
      // Get the Firestore document ID for this project
      final firestoreId = getFirestoreId(projectId);

      await _firestore
          .collection('projects')
          .doc(firestoreId)
          .collection('backlogs')
          .doc(backlogId)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating backlog item: $e');
      return false;
    }
  }

  // Delete backlog item
  Future<bool> deleteBacklogItem(String projectId, String backlogId) async {
    try {
      // Get the Firestore document ID for this project
      final firestoreId = getFirestoreId(projectId);

      await _firestore
          .collection('projects')
          .doc(firestoreId)
          .collection('backlogs')
          .doc(backlogId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting backlog item: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getBacklogTasks(
      String projectId, String backlogId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Get the Firestore document ID for this project
      final firestoreId = getFirestoreId(projectId);

      final snapshot = await _firestore
          .collection('projects')
          .doc(firestoreId)
          .collection('backlogs')
          .doc(backlogId)
          .collection('backlogTasks')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Error getting backlog tasks: $e');
      return [];
    }
  }

  // Add a backlog task
  Future<Map<String, dynamic>?> addBacklogTask(
      String projectId, String backlogId, Map<String, dynamic> taskData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get the Firestore document ID for this project
      final firestoreId = getFirestoreId(projectId);

      // Add created info
      final dataToSave = {
        ...taskData,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
      };

      // Add the document to Firestore
      final docRef = await _firestore
          .collection('projects')
          .doc(firestoreId)
          .collection('backlogs')
          .doc(backlogId)
          .collection('backlogTasks')
          .add(dataToSave);

      // Return the new task with ID
      return {
        ...taskData,
        'id': docRef.id,
      };
    } catch (e) {
      print('Error adding backlog task: $e');
      return null;
    }
  }

  // Update backlog task
  Future<bool> updateBacklogTask(
      String projectId, String backlogId, String taskId, Map<String, dynamic> updates) async {
    try {
      // Get the Firestore document ID for this project
      final firestoreId = getFirestoreId(projectId);

      await _firestore
          .collection('projects')
          .doc(firestoreId)
          .collection('backlogs')
          .doc(backlogId)
          .collection('backlogTasks')
          .doc(taskId)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating backlog task: $e');
      return false;
    }
  }

  // Delete backlog task
  Future<bool> deleteBacklogTask(
      String projectId, String backlogId, String taskId) async {
    try {
      // Get the Firestore document ID for this project
      final firestoreId = getFirestoreId(projectId);

      await _firestore
          .collection('projects')
          .doc(firestoreId)
          .collection('backlogs')
          .doc(backlogId)
          .collection('backlogTasks')
          .doc(taskId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting backlog task: $e');
      return false;
    }
  }

  Future<bool> isUserProjectMember(String projectId, String userId) async {
    try {
      final project = await _firestore.collection('projects').doc(projectId).get();

      if (!project.exists) return false;

      final members = List<String>.from(project.data()?['members'] ?? []);
      return members.contains(userId);
    } catch (e) {
      print('Error checking project membership: $e');
      return false;
    }
  }

  Future<void> addMemberToProject(String projectId, String memberUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if user has permission (is member or creator)
      if (!(await isUserProjectMember(projectId, user.uid))) {
        throw Exception('You do not have permission to add members to this project');
      }

      // Add the member
      await _firestore.collection('projects').doc(projectId).update({
        'members': FieldValue.arrayUnion([memberUserId]),
      });

      notifyListeners();
    } catch (e) {
      print('Error adding member to project: $e');
      throw e;
    }
  }

  Future<void> removeMemberFromProject(String projectId, String memberUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Only creator should remove members or the member themselves (leaving)
      final project = await _firestore.collection('projects').doc(projectId).get();

      if (!project.exists) throw Exception('Project not found');

      final data = project.data() as Map<String, dynamic>;
      final creatorId = data['createdBy'];

      // Check if current user is creator or the member being removed
      if (user.uid != creatorId && user.uid != memberUserId) {
        throw Exception('You do not have permission to remove this member');
      }

      // Remove the member
      await _firestore.collection('projects').doc(projectId).update({
        'members': FieldValue.arrayRemove([memberUserId]),
      });

      notifyListeners();
    } catch (e) {
      print('Error removing member from project: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getScrumMasterBacklogs(String projectId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')
          .where('status', whereIn: ['Ready', 'In Sprint'])
          .get();

      return snapshot.docs
          .map((doc) => {
        'id': doc.id,
        ...doc.data(),
      })
          .toList();
    } catch (e) {
      print('Error getting scrum master backlogs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProjectTeamMembers(String projectId) async {
    try {
      print('ProjectService: Getting team members for project: $projectId');

      // Check if project ID is valid
      if (projectId.isEmpty) {
        print('ProjectService: Invalid project ID (empty)');
        return [];
      }

      // Find the project with the given ID
      final project = _projects.firstWhere(
            (p) => p['id'] == projectId,
        orElse: () => <String, dynamic>{},
      );

      if (project.isEmpty) {
        print('ProjectService: Project not found for ID: $projectId');
        return [];
      }

      // Get member IDs for this project
      final List<dynamic> memberIds = project['members'] ?? [];
      print('ProjectService: Found ${memberIds.length} member IDs in project: $memberIds');

      if (memberIds.isEmpty) {
        print('ProjectService: No members found for project: $projectId');
        return [];
      }

      // Create a list to hold the results
      List<Map<String, dynamic>> teamMembers = [];

      // Fetch details for each member - don't filter yet
      for (var memberId in memberIds) {
        if (memberId is String) {
          print('ProjectService: Fetching member with ID: $memberId');

          try {
            final userDoc = await _firestore.collection('users').doc(memberId).get();

            if (userDoc.exists && userDoc.data() != null) {
              final userData = userDoc.data()!;
              print('ProjectService: Found user ${userData['name']} with role ${userData['role']}');

              // Include all members for now to debug
              teamMembers.add({
                'id': userDoc.id,
                'name': userData['name'] ?? 'Unknown User',
                'email': userData['email'] ?? 'No email',
                'role': userData['role'] ?? 'Unknown Role',
                ...userData, // Include other fields from user data
              });
            } else {
              print('ProjectService: User document not found for ID: $memberId');
            }
          } catch (e) {
            print('ProjectService: Error fetching user $memberId: $e');
          }
        }
      }

      print('ProjectService: Returning ${teamMembers.length} team members');
      return teamMembers;
    } catch (e) {
      print('ProjectService ERROR getting team members: $e');
      return [];
    }
  }

// Move this function from SMTaskDetailsScreen to ProjectService
  Future<void> updateTaskAssignedMembers(
      String projectId,
      String backlogId,
      String taskId,
      List<Map<String, dynamic>> assignedMembers
      ) async {
    try {
      // Convert to member IDs
      List<String> memberIds = [];
      for (var member in assignedMembers) {
        if (member.containsKey('id')) {
          memberIds.add(member['id']);
        }

        // Extract from sub-teams if needed
        if (member.containsKey('members') && member['members'] is List) {
          for (var subMember in member['members']) {
            if (subMember is Map<String, dynamic> && subMember.containsKey('id')) {
              memberIds.add(subMember['id']);
            }
          }
        }
      }

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('backlogs')
          .doc(backlogId)
          .collection('backlogTasks')
          .doc(taskId)
          .update({
        'assignedTo': memberIds.isNotEmpty ? memberIds.first : null,
        'assignedMembers': memberIds,
        'assignedMembersData': assignedMembers,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('ProjectService ERROR updating task assigned members: $e');
      throw e;
    }
  }

  // Add this method to the ProjectService class:
  Future<List<Map<String, dynamic>>> getAllTeamMembers() async {
    try {
      print('ProjectService: Fetching all team members across projects');

      // Get all projects for current user
      final user = _auth.currentUser;
      if (user == null) return [];

      // Get the current user's projects
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('members', arrayContains: user.uid)
          .get();

      // Set to track unique member IDs
      final Set<String> uniqueMemberIds = {};

      // Collect all member IDs from projects
      for (var projectDoc in projectsSnapshot.docs) {
        final List<dynamic> memberIds = projectDoc.data()['members'] ?? [];
        for (var memberId in memberIds) {
          if (memberId is String) {
            uniqueMemberIds.add(memberId);
          }
        }
      }

      print('ProjectService: Found ${uniqueMemberIds.length} unique members');

      // Fetch details for each member
      List<Map<String, dynamic>> allMembers = [];
      for (var memberId in uniqueMemberIds) {
        final userDoc = await _firestore
            .collection('users')
            .doc(memberId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          allMembers.add({
            'id': userDoc.id,
            'name': userData['name'] ?? 'Unknown User',
            ...userData,
          });
        }
      }

      print('ProjectService: Returning ${allMembers.length} team members');
      return allMembers;
    } catch (e) {
      print('ProjectService ERROR getting all team members: $e');
      return [];
    }
  }
  // Add this method to ProjectService
  Future<String?> findProjectIdByBacklogId(String backlogId) async {
    try {
      // Check locally first from cached projects
      for (var project in _projects) {
        if (project.containsKey('backlogs')) {
          final backlogs = project['backlogs'] as List?;
          if (backlogs != null) {
            for (var backlog in backlogs) {
              if (backlog is Map && backlog['id'] == backlogId) {
                return project['id'];
              }
            }
          }
        }
      }

      // If not found locally, try Firestore
      final projectsCollection = _firestore.collection('projects');
      final projectsSnapshot = await projectsCollection.get();

      for (var doc in projectsSnapshot.docs) {
        final backlogsCollection = doc.reference.collection('backlogs');
        final backlogDoc = await backlogsCollection.doc(backlogId).get();

        if (backlogDoc.exists) {
          return getProjectIdFromFirestoreId(doc.id);
        }
      }

      return null;
    } catch (e) {
      print('ProjectService ERROR finding project by backlog: $e');
      return null;
    }
  }

// Helper method to convert Firestore ID to project ID
  String? getProjectIdFromFirestoreId(String firestoreId) {
    for (var project in _projects) {
      if (project['firestoreId'] == firestoreId) {
        return project['id'];
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getTeamMemberBacklogs(String projectId) async {
    try {
      // Reference to the backlogs collection for the specified project
      final backlogRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('backlogs');

      // Get all backlog items that are in Sprint
      // Team members should see all backlog items in sprints
      final snapshot = await backlogRef
          .where('status', isEqualTo: 'In Sprint')
          .get();

      final backlogItems = <Map<String, dynamic>>[];

      // Process each backlog item
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Add the document ID to the map
        backlogItems.add(data);
      }

      return backlogItems;
    } catch (e) {
      print('Error in getTeamMemberBacklogs: $e');
      rethrow;
    }
  }

  Future<void> refreshProjects() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print("Cannot fetch projects: No authenticated user");
        return;
      }

      print("Fetching projects for user: ${user.uid}");

      _projects.clear();
      _projectFirestoreIds.clear();
      final Set<String> addedProjectIds = {};

      // 1. Product Owner
      QuerySnapshot ownerSnapshot = await _firestore
          .collection('projects')
          .where('roles.productOwner', isEqualTo: user.uid)
          .get();
      print("Retrieved ${ownerSnapshot.docs.length} projects as Product Owner");
      for (var doc in ownerSnapshot.docs) {
        _processProjectDocument(doc, addedProjectIds, "Product Owner");
      }

      // 2. Scrum Master
      QuerySnapshot smSnapshot = await _firestore
          .collection('projects')
          .where('roles.scrumMasters', arrayContains: user.uid)
          .get();
      print("Retrieved ${smSnapshot.docs.length} projects as Scrum Master");
      for (var doc in smSnapshot.docs) {
        _processProjectDocument(doc, addedProjectIds, "Scrum Master");
      }

      // 3. Team Member
      QuerySnapshot tmSnapshot = await _firestore
          .collection('projects')
          .where('roles.teamMembers', arrayContains: user.uid)
          .get();
      print("Retrieved ${tmSnapshot.docs.length} projects as Team Member");
      for (var doc in tmSnapshot.docs) {
        _processProjectDocument(doc, addedProjectIds, "Team Member");
      }

      // 4. ADD THIS: Client role query
      QuerySnapshot clientSnapshot = await _firestore
          .collection('projects')
          .where('roles.clients', arrayContains: user.uid)
          .get();
      print("Retrieved ${clientSnapshot.docs.length} projects as Client");
      for (var doc in clientSnapshot.docs) {
        _processProjectDocument(doc, addedProjectIds, "Client");
      }

      // 5. ADD THIS: Legacy members array
      QuerySnapshot membersSnapshot = await _firestore
          .collection('projects')
          .where('members', arrayContains: user.uid)
          .get();
      print("Retrieved ${membersSnapshot.docs.length} projects from legacy members array");
      for (var doc in membersSnapshot.docs) {
        _processProjectDocument(doc, addedProjectIds, "Legacy Member");
      }

      notifyListeners();
    } catch (e) {
      print('Error refreshing projects from Firebase: $e');
    }
  }

  void _processProjectDocument(DocumentSnapshot doc, Set<String> addedProjectIds, String roleType) {
    final data = doc.data() as Map<String, dynamic>;
    final projectId = data['id'] ?? doc.id;

    // Skip if we've already added this project ID
    if (addedProjectIds.contains(projectId)) return;

    // Add to our tracking set
    addedProjectIds.add(projectId);

    // Store mapping of project ID to Firestore document ID
    _projectFirestoreIds[projectId] = doc.id;

    // Get role information
    Map<String, dynamic> roles = data['roles'] ?? {};

    // Add to projects list
    _projects.add({
      'id': projectId,
      'firestoreId': doc.id,
      'name': data['name'] ?? 'Unnamed Project',
      'title': data['name'] ?? 'Unnamed Project',
      'description': data['description'] ?? '',
      'startDate': data['startDate'] ?? '',
      'endDate': data['endDate'] ?? '',
      'dueDate': data['endDate'] ?? '',
      'status': data['status']?.toLowerCase() ?? 'in_progress',
      'progress': data['progress'] ?? 0.0,
      'userRole': roleType, // Add the user's role in this project
      'roles': roles, // Store the full roles object
    });
  }

  void addProject(Map<String, dynamic> newProject) async {
    // Check if a project with this ID already exists
    final existingIndex = _projects.indexWhere((project) => project['id'] == newProject['id']);

    if (existingIndex != -1) {
      // Update existing project instead of adding
      _projects[existingIndex] = newProject;
    } else {
      // Add project to local state (immediate UI update)
      _projects.insert(0, newProject);
    }

    notifyListeners();

    try {
      // Then try to add to Firebase
      final user = _auth.currentUser;
      if (user != null) {
        // Set up roles properly
        if (!newProject.containsKey('roles')) {
          newProject['roles'] = {
            'productOwner': user.uid,
            'scrumMasters': [],
            'teamMembers': [],
            'clients': []
          };
        }

        // IMPORTANT: Create the document with the user-friendly ID
        final projectId = newProject['id'];

        print('Adding project to Firestore with ID: ${projectId}');

        await _firestore.collection('projects').doc(projectId).set({
          ...newProject,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('Successfully added project to Firestore with ID: ${projectId}');
      }
    } catch (e) {
      print('Error adding project to Firebase: $e');
    }
  }

  Future<void> assignScrumMaster(String projectId, String scrumMasterId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get the project
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) {
        throw Exception("Project not found");
      }

      final projectData = projectDoc.data() as Map<String, dynamic>;
      final roles = projectData['roles'] as Map<String, dynamic>? ?? {};

      // Verify current user is the product owner
      if (roles['productOwner'] != user.uid) {
        throw Exception("Only the Product Owner can assign Scrum Masters");
      }

      // Update the project to add the Scrum Master
      await _firestore.collection('projects').doc(projectId).update({
        'roles.scrumMasters': FieldValue.arrayUnion([scrumMasterId])
      });

      // Refresh local projects data
      await refreshProjects();
    } catch (e) {
      print('Error assigning Scrum Master: $e');
      throw e;
    }
  }

  bool hasRoleInProject(String projectId, String role) {
    try {
      final project = getProjectById(projectId);
      if (project == null) return false;

      final user = _auth.currentUser;
      if (user == null) return false;

      final roles = project['roles'] as Map<String, dynamic>? ?? {};

      if (role == 'productOwner') {
        return roles['productOwner'] == user.uid;
      } else if (role == 'scrumMaster') {
        final scrumMasters = roles['scrumMasters'] as List? ?? [];
        return scrumMasters.contains(user.uid);
      } else if (role == 'teamMember') {
        final teamMembers = roles['teamMembers'] as List? ?? [];
        return teamMembers.contains(user.uid);
      } else if (role == 'client') {
        final clients = roles['clients'] as List? ?? [];
        return clients.contains(user.uid);
      }

      return false;
    } catch (e) {
      print('Error checking role: $e');
      return false;
    }
  }
}