import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/main.dart';
import 'package:task_orbit/screens/Product_Owner/AddToDo.dart';
import 'package:task_orbit/services/TodoService.dart';
import 'package:task_orbit/widgets/drawer_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/AuthService.dart';
import '../../widgets/product_owner_drawer.dart';

class MyTasks extends StatefulWidget {
  const MyTasks({super.key});

  @override
  State<MyTasks> createState() => _MyTasksState();
}

class _MyTasksState extends State<MyTasks> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Check if user is authenticated and refresh tasks
    _checkUserAndLoadTasks();
  }

  // Verify user authentication and load tasks
  Future<void> _checkUserAndLoadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        print("User authenticated: ${currentUser.uid}");
        // If using TaskService via provider, it will handle loading tasks
        await Provider.of<TodoService>(context, listen: false).refreshTodos();
      } else {
        print("No user authenticated, redirecting to login");
        // Navigate to login if needed
        // Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      print("Error checking authentication: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  void _addNewTask(Map<String, dynamic> newTask) {
    // Use the TaskService provider to add the task
    Provider.of<TodoService>(context, listen: false).addTodo(newTask);
  }

  void _navigateToEditPage(Map<String, dynamic> task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTodo(
          onTodoAdded: (updatedTask) {
            // Use the TaskService provider to update the task
            Provider.of<TodoService>(context, listen: false)
                .updateTodo(task['id'], updatedTask);
          },
          initialTask: task,
        ),
      ),
    );
  }

  void _toggleTaskCompletion(String taskId, bool isCompleted) {
    // Use the TaskService provider to toggle task completion
    Provider.of<TodoService>(context, listen: false).toggleTodoCompletion(taskId);
  }

  void _deleteTask(String taskId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?', style: TextStyle(fontFamily: 'Poppins')),
          content: const Text('Do you want to delete this task? This action cannot be undone.',
              style: TextStyle(fontFamily: 'Poppins')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
            ),
            TextButton(
              onPressed: () {
                // Use the TaskService provider to delete the task
                Provider.of<TodoService>(context, listen: false).deleteTodo(taskId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Task deleted successfully.",
                        style: TextStyle(fontFamily: 'Poppins')),
                  ),
                );
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red, fontFamily: 'Poppins')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        foregroundColor: const Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: const Color(0xFF004AAD),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chat),
            color: Color(0xFF004AAD),
            onPressed: () {
              Navigator.pushNamed(context, '/POChat_list');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color(0xFF004AAD),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'My Taskse'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddTodo(onTodoAdded: _addNewTask),
          ),
        ),
        backgroundColor: MyApp.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTodoList(),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Home", 0),
            _buildNavItem(Icons.assignment, "Project", 1),
            _buildNavItem(Icons.access_time_filled_rounded, "Schedule", 2),
            _buildNavItem(Icons.person, "Profile", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Poppins-SemiBold',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoList() {
    return Consumer<TodoService>(
        builder: (context, taskService, child) {
          final tasks = taskService.todos;

          // Check if user is authenticated
          if (_auth.currentUser == null) {
            return const Center(
              child: Text(
                "Please log in to view your tasks",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                ),
              ),
            );
          }

          final completedTasks = tasks.where((task) => task['isCompleted'] == true).toList();
          final incompleteTasks = tasks.where((task) => task['isCompleted'] == false).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await taskService.refreshTodos();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (incompleteTasks.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Pending Tasks",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004AAD),
                          fontFamily: 'Poppins'
                      ),
                    ),
                  ),
                  ...incompleteTasks.map((task) => _buildTaskCard(task)),
                ],
                if (completedTasks.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      "Completed Tasks",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004AAD),
                          fontFamily: 'Poppins'
                      ),
                    ),
                  ),
                  ...completedTasks.map((task) => _buildTaskCard(task)),
                ],
                if (tasks.isEmpty) ...[
                  const Center(
                    child: Text(
                      "No tasks added yet",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final deadline = task['deadline'] != null
        ? DateTime.parse(task['deadline'])
        : null;

    Color priorityColor;
    switch (task['priority']) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      case 'Low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      color: const Color(0xFFEDF1F3),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToEditPage(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  task['isCompleted']
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: task['isCompleted']
                      ? const Color(0xFF004AAD)
                      : Colors.grey.shade400,
                ),
                onPressed: () => _toggleTaskCompletion(task['id'], task['isCompleted']),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] ?? 'Untitled Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task['isCompleted']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task['isCompleted']
                            ? Colors.grey
                            : const Color(0xFF313131),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        decoration: task['isCompleted']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task['priority'] ?? 'Medium',
                            style: TextStyle(
                              fontSize: 12,
                              color: priorityColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (deadline != null)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd MMM').format(deadline),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[400],
                onPressed: () => _deleteTask(task['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }
}