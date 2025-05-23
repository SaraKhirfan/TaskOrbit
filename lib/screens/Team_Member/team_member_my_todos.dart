import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/main.dart';
import 'package:task_orbit/screens/Product_Owner/AddToDo.dart';
import 'package:task_orbit/services/TodoService.dart';
import 'package:task_orbit/widgets/team_member_drawer.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/sm_app_bar.dart';

class TMMyTodos extends StatefulWidget {
  const TMMyTodos({super.key});

  @override
  State<TMMyTodos> createState() => _TMMyTodosState();
}

class _TMMyTodosState extends State<TMMyTodos> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
  }

  void _addNewTodo(Map<String, dynamic> newTodo) {
    // Use the TodoService provider to add the todo
    Provider.of<TodoService>(context, listen: false).addTodo(newTodo);
  }

  void _navigateToEditPage(Map<String, dynamic> todo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AddTodo(
          onTodoAdded: (updatedTodo) {
            // Use the TodoService provider to update the todo
            Provider.of<TodoService>(
              context,
              listen: false,
            ).updateTodo(todo['id'], updatedTodo);
          },
          initialTask: todo,
        ),
      ),
    );
  }

  void _toggleTodoCompletion(String todoId, bool isCompleted) {
    // Use the TodoService provider to toggle todo completion
    Provider.of<TodoService>(
      context,
      listen: false,
    ).toggleTodoCompletion(todoId);
  }

  void _deleteTodo(String todoId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Are you sure?',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: const Text(
            'Do you want to delete this todo? This action cannot be undone.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            TextButton(
              onPressed: () {
                // Use the TodoService provider to delete the todo
                Provider.of<TodoService>(
                  context,
                  listen: false,
                ).deleteTodo(todoId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Todo deleted successfully.",
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // Explicitly refresh todos when this screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TodoService>(context, listen: false).refreshTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      key: _scaffoldKey,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "My To-Do"),
      drawer: TeamMemberDrawer(selectedItem: 'My To-Do'),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddTodo(onTodoAdded: _addNewTodo),
          ),
        ),
        backgroundColor: MyApp.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildTodoList(),
      bottomNavigationBar: TMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildTodoList() {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        final todos = todoService.todos;
        final completedTodos = todoService.completedTodos;
        final incompleteTodos = todoService.incompleteTodos;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (incompleteTodos.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Pending Todos",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004AAD),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              ...incompleteTodos.map((todo) => _buildTodoCard(todo)),
            ],
            if (completedTodos.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  "Completed Todos",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004AAD),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              ...completedTodos.map((todo) => _buildTodoCard(todo)),
            ],
            if (todos.isEmpty) ...[
              const Center(
                child: Text(
                  "No todos added yet",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTodoCard(Map<String, dynamic> todo) {
    final deadline =
    todo['deadline'] != null ? DateTime.tryParse(todo['deadline']) : null;

    Color priorityColor;
    switch (todo['priority']) {
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
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToEditPage(todo),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  todo['isCompleted']
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color:
                  todo['isCompleted']
                      ? const Color(0xFF004AAD)
                      : Colors.grey.shade400,
                ),
                onPressed:
                    () =>
                    _toggleTodoCompletion(todo['id'], todo['isCompleted']),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo['title'] ?? 'Untitled',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration:
                        todo['isCompleted']
                            ? TextDecoration.lineThrough
                            : null,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (todo['description'] != null &&
                        todo['description'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          todo['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            decoration:
                            todo['isCompleted']
                                ? TextDecoration.lineThrough
                                : null,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (deadline != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color:
                              _isDeadlinePassed(deadline)
                                  ? Colors.red
                                  : Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, yyyy').format(deadline),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                _isDeadlinePassed(deadline)
                                    ? Colors.red
                                    : Colors.grey[700],
                                fontWeight:
                                _isDeadlinePassed(deadline)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (todo['priority'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        todo['priority'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => _deleteTodo(todo['id']),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDeadlinePassed(DateTime deadline) {
    final now = DateTime.now();
    return deadline.isBefore(now);
  }
}