// File: lib/services/navigation_service.dart
import 'package:flutter/material.dart';
import 'package:task_orbit/main.dart' show navigatorKey;

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  Future<dynamic> navigateToReplacement(String routeName) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName);
  }

  void goBack() {
    // Add a check to see if we can pop before attempting to pop
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop();
    }
  }

  // Handle Scrum Master navigation - use direct context navigation
  void onScrumMasterDrawerItemSelected(BuildContext context, String title) {
    // NOTE: No need to pop here, as it's already handled in the drawer widget

    // Use delayed navigation to avoid conflicts
    Future.delayed(Duration(milliseconds: 300), () {
      // Use the provided context for navigation
      if (title == 'Home') {
        Navigator.pushReplacementNamed(context, '/scrumMasterHome');
      } else if (title == 'My Profile') {
        Navigator.pushReplacementNamed(context, '/smMyProfile');
      } else if (title == 'Task Management') {
        Navigator.pushReplacementNamed(context, '/smAllTasksManagement');
      } else if (title == 'Workload Monitoring') {
        Navigator.pushReplacementNamed(context, '/smWorkloadMonitor');
      } else if (title == 'My Projects') {
        Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
      } else if (title == 'My Tasks') {
        Navigator.pushReplacementNamed(context, '/smMyTasks');
      } else if (title == 'Settings') {
        Navigator.pushReplacementNamed(context, '/scrumMasterSettings');
      } else if (title == 'Time Scheduling') {
        Navigator.pushReplacementNamed(context, '/smTimeScheduling');
      } else if (title == 'Retrospective') {
        Navigator.pushReplacementNamed(context, '/retroScreen');
      } else if (title == 'Add Members') {
        Navigator.pushReplacementNamed(context, '/smAddMembers');
      } else if (title == 'Log Out') {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        // Show a "Not implemented yet" message for other features
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This feature is not implemented yet.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
  void onProductOwnerDrawerItemSelected(BuildContext context, String title) {
    // NOTE: No need to pop here, as it's already handled in the drawer widget

    // Use delayed navigation to avoid conflicts
    Future.delayed(Duration(milliseconds: 300), () {
      if (title == 'Home') {
        Navigator.pushReplacementNamed(context, '/productOwnerHome');
      } else if (title == 'My Profile') {
        Navigator.pushReplacementNamed(context, '/MyProfile');
      } else if (title == 'My Tasks') {
        Navigator.pushReplacementNamed(context, '/MyTasks');
      } else if (title == 'My Projects') {
        Navigator.pushReplacementNamed(context,  '/myProjects');
      } else if (title == 'Clients Feedback') {
        Navigator.pushReplacementNamed(context, '/POClientsFeedback');
      } else if (title == 'Add Members') {
        Navigator.pushReplacementNamed(context, '/addMembers');
      } else if (title == 'Time Scheduling') {
        Navigator.pushReplacementNamed(context, '/timeScheduling');
      } else if (title == 'Activity Logs') {
        Navigator.pushReplacementNamed(context, '/activityLogsProjectSelection');
      } else if (title == 'Settings') {
        Navigator.pushReplacementNamed(context, '/settings');
      } else if (title == 'Log Out') {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        // Show a "Not implemented yet" message for other features
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This feature is not implemented yet.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
  void onTeamMemberDrawerItemSelected(BuildContext context, String title) {
    // NOTE: No need to pop here, as it's already handled in the drawer widget

    // Use delayed navigation to avoid conflicts
    Future.delayed(Duration(milliseconds: 300), () {
      if (title == 'Home') {
        Navigator.pushReplacementNamed(context, '/teamMemberHome');
      } else if (title == 'My Profile') {
        Navigator.pushReplacementNamed(context, 'tmMyProfile');
      } else if (title == 'My To-Do') {
        Navigator.pushReplacementNamed(context,'/tmMyTodo');
      } else if (title == 'Assigned Tasks') {
        Navigator.pushReplacementNamed(context, '/teamMemberAssignedTasks');
      } else if (title == 'Projects') {
        Navigator.pushReplacementNamed(context, '/teamMemberProjects');
      } else if (title == 'Time Scheduling') {
        Navigator.pushReplacementNamed(context,  '/tmTimeScheduling');
      } else if (title == 'My Workload') {
        Navigator.pushReplacementNamed(context, '/teamMemberWorkload');
      } else if (title == 'Retrospective') {
        Navigator.pushReplacementNamed(context, '/teamMemberRetrospective');
      } else if (title == 'Settings') {
        Navigator.pushReplacementNamed(context, '/teamMemberSettings');
      } else if (title == 'Log Out') {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        // Show a "Not implemented yet" message for other features
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This feature is not implemented yet.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
  void onClientDrawerItemSelected(BuildContext context, String title) {
    // NOTE: No need to pop here, as it's already handled in the drawer widget

    // Use delayed navigation to avoid conflicts
    Future.delayed(Duration(milliseconds: 300), () {
      if (title == 'Home') {
        Navigator.pushReplacementNamed(context, '/clientHome');
      } else if (title == 'My Profile') {
        Navigator.pushReplacementNamed(context, '/clientProfile');
      } else if (title == 'Projects') {
        Navigator.pushReplacementNamed(context,  '/clientProjects');
      } else if (title == 'Time Scheduling') {
        Navigator.pushReplacementNamed(context, '/clientTimeScheduling');
      }  else if (title == 'Feedback') {
        Navigator.pushReplacementNamed(context, '/clientFeedback');
      } else if (title == 'Settings') {
        Navigator.pushReplacementNamed(context, '/clientSettings');
      } else if (title == 'Log Out') {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        // Show a "Not implemented yet" message for other features
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This feature is not implemented yet.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
}