import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TodoService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _todos = [];
  bool _isLoading = false;
  bool _hasError = false;

  // Getters
  List<Map<String, dynamic>> get todos => _todos;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  // Constructor - load todos when service is created
  TodoService() {
  }

  // Get incomplete todos for UI display
  List<Map<String, dynamic>> get incompleteTodos {
    return _todos.where((todo) => todo['isCompleted'] == false).toList();
  }

  // Get completed todos for UI display
  List<Map<String, dynamic>> get completedTodos {
    return _todos.where((todo) => todo['isCompleted'] == true).toList();
  }

  Future<void> refreshTodos() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _todos = []; // Clear todos if not authenticated
        _isLoading = false;
        notifyListeners();
        return;
      }

      print("Refreshing todos for user: ${user.uid}");

      // Query Firestore for todos belonging to current user
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .get();

      print("Found ${querySnapshot.docs.length} todos in Firestore");

      // Map documents to todos with IDs
      final loadedTodos = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      // ENSURE we only include this user's todos
      _todos = loadedTodos.where((todo) => todo['userId'] == user.uid).toList();

      print("Final filtered todos count: ${_todos.length}");

      // Sort todos
      _todos.sort((a, b) {
        var aTime = a['createdAt'];
        var bTime = b['createdAt'];

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime); // Newest first
        }

        return 0;
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error refreshing todos: $e');
      _hasError = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTodo(Map<String, dynamic> todo) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a new map instead of modifying the original
      final todoToAdd = Map<String, dynamic>.from(todo);

      // CRITICAL: Ensure userId is set to current user
      todoToAdd['userId'] = user.uid;

      // Add timestamp and default values
      todoToAdd['createdAt'] = Timestamp.now();
      todoToAdd['isCompleted'] = todoToAdd['isCompleted'] ?? false;

      print("Adding todo for user ${user.uid}: ${todoToAdd['title']}");
      print("Todo data: $todoToAdd");

      // Add to Firestore
      final docRef = await _firestore.collection('tasks').add(todoToAdd);
      print("Todo added with ID: ${docRef.id}");

      // Refresh todos
      await refreshTodos();

      return true;
    } catch (e) {
      print('Error adding todo: $e');
      _hasError = true;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update an existing todo
  Future<bool> updateTodo(String todoId, Map<String, dynamic> updatedTodo) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Add update timestamp
      updatedTodo['updatedAt'] = Timestamp.now();

      print("Updating todo in Firestore: $todoId");

      // Update in Firestore
      await _firestore.collection('tasks').doc(todoId).update(updatedTodo);

      print("Todo updated successfully, refreshing todo list");

      // Always refresh the entire list to ensure consistency
      await refreshTodos();

      return true;
    } catch (e) {
      print('Error updating todo: $e');
      _hasError = true;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a todo
  Future<bool> deleteTodo(String todoId) async {
    _isLoading = true;
    notifyListeners();

    try {
      print("Deleting todo from Firestore: $todoId");

      // Delete from Firestore
      await _firestore.collection('tasks').doc(todoId).delete();

      print("Todo deleted successfully, refreshing todo list");

      // Always refresh the entire list to ensure consistency
      await refreshTodos();

      return true;
    } catch (e) {
      print('Error deleting todo: $e');
      _hasError = true;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle todo completion status
  Future<bool> toggleTodoCompletion(String todoId) async {
    try {
      // Find todo in local list
      final index = _todos.indexWhere((todo) => todo['id'] == todoId);
      if (index == -1) return false;

      // Get current completion status
      final currentStatus = _todos[index]['isCompleted'] ?? false;

      print("Toggling todo completion: $todoId to ${!currentStatus}");

      // Toggle status
      final updatedTodo = {
        'isCompleted': !currentStatus,
        'updatedAt': Timestamp.now(),
      };

      // Update Firestore
      return await updateTodo(todoId, updatedTodo);
    } catch (e) {
      print('Error toggling todo completion: $e');
      _hasError = true;
      notifyListeners();
      return false;
    }
  }

  // Get todos for home view display
  List<Map<String, dynamic>> getTodosForHomeView() {
    try {
      if (incompleteTodos.isEmpty) {
        return [];
      }

      // Get at most 3 todos
      List<Map<String, dynamic>> result = [];
      int count = 0;

      for (var todo in incompleteTodos) {
        if (count >= 3) break;

        try {
          // Check if deadline exists and is a valid date
          DateTime? deadline;
          if (todo['deadline'] != null) {
            deadline = DateTime.tryParse(todo['deadline']);
          }

          final formattedDeadline = deadline != null
              ? DateFormat('dd-MM-yyyy').format(deadline)
              : 'No deadline';

          final formattedDate = deadline != null
              ? DateFormat('yyyy-MM-dd').format(deadline)
              : '';

          result.add({
            'id': todo['id'],
            'title': todo['title'] ?? 'Untitled',
            'description': todo['description'] ?? '',
            'priority': todo['priority'] ?? 'Medium',
            'deadline': formattedDeadline,
            'date': formattedDate,
          });

          count++;
        } catch (e) {
          print('Error formatting todo: $e');
          // Skip this todo and continue
          continue;
        }
      }

      return result;
    } catch (e) {
      print('Error getting todos for home view: $e');
      return [];
    }
  }
}