// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_orbit/screens/Client/ClientProjectAnalytics.dart';
import 'package:task_orbit/screens/Client/ClientTeamOverview.dart';
import 'package:task_orbit/screens/Client/ClientsFeedbackforclient.dart';
import 'package:task_orbit/screens/Client/clientProfile.dart';
import 'package:task_orbit/screens/Client/clientSettings.dart';
import 'package:task_orbit/screens/Client/clientTimeScheduling.dart';
import 'package:task_orbit/screens/Client/client_project_sprints_screen.dart';
import 'package:task_orbit/screens/Product_Owner/ActivityLogsProjectSelectionScreen.dart';
import 'package:task_orbit/screens/Product_Owner/activity_logs_screen.dart';
import 'package:task_orbit/screens/Product_Owner/clients_feedback.dart';
import 'package:task_orbit/screens/ScrumMaster/retro_screen.dart';
import 'package:task_orbit/screens/ScrumMaster/smReports.dart';
import 'package:task_orbit/screens/ScrumMaster/sm_workloadmonitoring_screen.dart';
import 'package:task_orbit/screens/Team_Member/TMAnalyticsScreen.dart';
import 'package:task_orbit/screens/Team_Member/TMTeamOverview.dart';
import 'package:task_orbit/screens/Team_Member/TeamMemberBacklogScreen.dart';
import 'package:task_orbit/screens/Team_Member/team_member_my_profile.dart';
import 'package:task_orbit/screens/Team_Member/team_member_my_todos.dart';
import 'package:task_orbit/screens/Team_Member/team_member_product_backlog_detail_screen.dart';
import 'package:task_orbit/screens/Team_Member/team_member_project_details_screen.dart';
import 'package:task_orbit/screens/Team_Member/team_member_settings.dart';
import 'package:task_orbit/screens/Team_Member/team_member_time_scheduling.dart';
import 'package:task_orbit/services/FeedbackService.dart';
import 'package:task_orbit/services/RetrospectiveService.dart';
import 'package:task_orbit/services/TeamMemberTaskService.dart';
import 'package:task_orbit/services/activity_log_service.dart';
//Registration
import 'screens/Registration/welcome_screen.dart';
import 'screens/Registration/login_screen.dart';
import 'screens/Registration/signup_screen.dart';
//Product Owner
import 'package:task_orbit/screens/Product_Owner/ReportsAndAnalysis.dart';
import 'package:task_orbit/screens/Product_Owner/Roadblocks_screen.dart';
import 'package:task_orbit/screens/Product_Owner/Team_Overview.dart';
import 'package:task_orbit/screens/Product_Owner/add_members_screen.dart';
import 'package:task_orbit/screens/Product_Owner/my_profile_screen.dart';
import 'package:task_orbit/screens/Product_Owner/product_backlog_screen.dart';
import 'package:task_orbit/screens/Product_Owner/project_details_screen.dart';
import 'package:task_orbit/screens/Product_Owner/settings_screen.dart';
import 'package:task_orbit/screens/Product_Owner/sprint_details_screen.dart';
import 'package:task_orbit/screens/Product_Owner/sprint_planning_screen.dart';
import 'package:task_orbit/screens/Product_Owner/team_performance_screen.dart';
import 'package:task_orbit/screens/Product_Owner/backlog_details_screen.dart';
import 'package:task_orbit/screens/Product_Owner/time_scheduling_screen.dart';
import 'screens/Product_Owner/product_owner_home_screen.dart';
import 'screens/Product_Owner/my_projects_screen.dart';
import 'screens/Product_Owner/MyTasks.dart';
//Scrum Master
import 'package:task_orbit/screens/ScrumMaster/sm_backlog_screen.dart';
import 'package:task_orbit/screens/ScrumMaster/sm_home_screen.dart';
import 'package:task_orbit/screens/ScrumMaster/sm_my_tasks.dart';
import 'package:task_orbit/screens/ScrumMaster/sm_myprofile.dart';
import 'package:task_orbit/screens/ScrumMaster/sm_project_details_screen.dart';
import 'package:task_orbit/screens/ScrumMaster/sm_project_team_screen.dart';
import 'package:task_orbit/screens/ScrumMaster/sm_projects_screen.dart';
import 'package:task_orbit/screens/ScrumMaster/sm_settings_screen.dart';
import 'package:task_orbit/screens/ScrumMaster/sm_taskmanagement_screen.dart';
import 'package:task_orbit/screens/ScrumMaster/sm_time_scheduling.dart';
//Services
import 'package:task_orbit/services/AuthService.dart';
import 'package:task_orbit/services/FirestoreService.dart';
import 'package:task_orbit/services/TodoService.dart';
import 'package:task_orbit/services/sprint_service.dart';
import 'package:task_orbit/services/user_service.dart';
import 'services/project_service.dart';
// Team Member screens import
import 'package:task_orbit/screens/Team_Member/team_member_home_screen.dart';
import 'package:task_orbit/screens/Team_Member/team_member_assigned_tasks_screen.dart';
import 'package:task_orbit/screens/Team_Member/team_member_task_details_screen.dart';
import 'package:task_orbit/screens/Team_Member/team_member_workload_screen.dart';
import 'package:task_orbit/screens/Team_Member/team_member_retrospective_screen.dart';
import 'package:task_orbit/screens/Team_Member/team_member_projects_screen.dart';
import 'package:task_orbit/screens/Team_Member/team_member_sprint_planning_screen.dart';
// Client Screens import
import 'package:task_orbit/screens/Client/client_home_screen.dart';
import 'package:task_orbit/screens/Client/client_project_details_screen.dart';
import 'package:task_orbit/screens/Client/client_projects_screen.dart';

// Global navigator key for context access anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Run app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProjectService()),
        ChangeNotifierProvider(create: (context)=> TodoService()),
        ChangeNotifierProvider(create: (_)=> RetrospectiveService()),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(
            firebaseAuth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
          ),
        ),
        ChangeNotifierProvider<FirestoreService>(
          create: (_) => FirestoreService(firestore: FirebaseFirestore.instance),
        ),
        ChangeNotifierProvider(create: (context) => UserService()),
        ChangeNotifierProvider(create: (_) => SprintService()),
        ChangeNotifierProvider(create: (context) => TeamMemberTaskService()),
        ChangeNotifierProvider(create: (_) => FeedbackService()),
        ChangeNotifierProvider<ActivityLogService>(create: (context) => ActivityLogService(),),
      ],
      child: const MyApp(),
    ),
  );
}

// Function to check for pending invitations
void _checkPendingInvitations() async {
  if (navigatorKey.currentContext == null) return;

  final auth = Provider.of<AuthService>(navigatorKey.currentContext!, listen: false);

  if (auth.currentUser != null) {
    try {
      // Process invitations directly from AuthService
      // No need for a separate InvitationService
      await auth.processInvitationsForCurrentUser();
    } catch (e) {
      print('Error processing invitations: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryColor = Color(0xFF004AAD);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFE53935);
  static const Color shadowColor = Color(0x1A000000);

  @override
  Widget build(BuildContext context) {
    // Get the authentication service
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      navigatorKey: navigatorKey, // Add navigator key here
      title: 'TaskOrbit',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDFDFD),
        highlightColor: const Color(0xFFEDF1F3),
        primaryColor: primaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF313131),
            fontFamily: 'Poppins',
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Color(0xFF313131),
            fontFamily: 'Poppins',
          ),
        ),
      ),
      // Check auth state to determine initial route
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in, check for pending invitations
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkPendingInvitations();
            });

            // Get user's role and navigate to appropriate home screen
            return FutureBuilder<String>(
              future: authService.getUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Navigate based on user role
                final userRole = roleSnapshot.data ?? 'Product_Owner'; // Default fallback

                switch (userRole) {
                  case 'Product_Owner':
                    return const ProductOwnerHomeScreen(userRole: 'Product_Owner');
                  case 'Scrum Master':
                    return const ScrumMasterHomeScreen(userRole: 'Scrum Master');
                  case 'Team Member':
                    return const TeamMemberHomeScreen(userRole: 'Team Member');
                  case 'Client':
                    return const ClientHomeScreen(userRole: 'Client');
                  default:
                    return const ProductOwnerHomeScreen(userRole: 'Product_Owner');
                }
              },
            );
          }

          // User is not logged in, go to welcome screen
          return const WelcomeScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/productOwnerHome': (context) =>
        const ProductOwnerHomeScreen(userRole: 'Product Owner'),
        '/myProjects': (context) => const MyProjectsScreen(),
        '/activityLogsProjectSelection': (context) => ActivityLogsProjectSelectionScreen(),
        '/activityLogs': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          if (args != null && args is Map<String, dynamic>) {
            return ActivitylogsScreen(
              projectId: args['projectId'] as String,
              projectName: args['projectName'] as String,
            );
          } else {
            // Error screen
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: Missing project information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/myProjects'),
                      child: Text('Go to Projects'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
        '/POClientsFeedback': (context) => const POClientsFeedbackScreen(),
        '/MyTasks': (context) => const MyTasks(),
        '/MyProfile': (context) => const MyProfileScreen(),
        '/addMembers': (context) => const AddMembersScreen(),
        '/timeScheduling': (context) => const TimeSchedulingScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/projectDetails': (context) {
          final project = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ProjectDetailsScreen(projectId: project['id'] as String);
        },
        '/productBacklog': (context) {
          final project =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;

          return ProductBacklogScreen(project: project);
        },
        '/TeamOverview': (context) {
          final project =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;

          return TeamOverviewScreen(project: project);
        },
        '/userStoryDetails': (context) {
          final story =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
          return BacklogDetailsScreen(
              projectId: story['projectId'] ?? '',
              story: story
          );
        },
        '/sprintPlanning': (context) {
          final project =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
          return SprintPlanningScreen(project: project);
        },
        '/sprintDetails': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
          return POSprintDetailsScreen(
            sprint: args['sprint'],
           projectId: '', projectName: '',
          );
        },
        '/teamPerformance': (context) {
          final project =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
          return TeamPerformanceScreen();
        },
        '/roadblocks': (context) => const RoadblocksScreen(),
        '/Reports': (context) {
          final project = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return POReportsAnalyticsScreen(project: project);
        },
        //ScrumMaster
        '/scrumMasterHome':
            (context) => const ScrumMasterHomeScreen(userRole: 'Scrum Master'),
        '/scrumMasterProjects': (context) => const ScrumMasterProjectsScreen(),
        '/scrumMasterProjectDetails': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
          return ScrumMasterProjectDetailsScreen(project: args);
        },
        '/scrumMasterBacklog': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
          return ScrumMasterBacklogScreen(project: args);
        },
        '/scrumMasterSettings': (context) => const SMSettingsScreen(),
        '/smTimeScheduling': (context) => const SMTimeSchedulingScreen(),
        '/smMyTasks': (context) => const SMMyTodos(),
        '/retroScreen': (context) => RetrospectiveScreen(),
        '/smProjectTeam': (context) => const SMProjectTeamScreen(),
        '/smMyProfile': (context) => const SMMyProfileScreen(),
        '/TMTeamOverview': (context) {
          final project =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;

          return TMTeamOverviewScreen(project: project);
        },
        '/smAllTasksManagement': (context) => const SMAllTasksManagementScreen(),
        '/SMReports': (context) => const SMReportsAnalyticsScreen(project: {}),
        '/smWorkloadMonitor': (context) => const SMTeamWorkloadDashboardScreen(),
        //Team Member
        '/teamMemberHome': (context) => const TeamMemberHomeScreen(userRole: 'Team Member'),
        '/teamMemberBacklogDetailsScreen': (context) {
          final projectId = ModalRoute.of(context)!.settings.arguments as String;
          return TeamMemberBacklogScreen(projectId: projectId);
        },
        '/teamMemberTaskDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TeamMemberTaskDetailsScreen(
            taskId: args['taskId'],
            projectId: args['projectId'],
            backlogId: args['backlogId'],
          );
        },
        '/teamMemberWorkload': (context) => const TeamMemberWorkloadScreen(),
        '/teamMemberRetrospective':
            (context) => const TeamMemberRetrospectiveScreen(),
        '/teamMemberProjects': (context) => const TeamMemberProjectsScreen(),
        '/teamMemberAssignedTasks': (context) => const TeamMemberAssignedTasksScreen(),
        '/teamMemberProjectDetails': (context) => const TeamMemberProjectDetailsScreen(projectId: '',),
        '/tmMyProfile': (context) => const TMProfileScreen(),
        '/tmMyTodo': (context) => const TMMyTodos(),
        '/tmTimeScheduling' : (context) => const TMTimeSchedulingScreen(),
        '/teamMemberSettings' : (context) => const TeamMemberSettings(),
        '/TMAnalytics': (context)  {final project = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
         return TMReportsAnalyticsScreen(project: project);},
        '/teamMemberSprintPlanning':
            (context) => TMSprintPlanningScreen(
          project:
          Provider.of<ProjectService>(
            context,
            listen: false,
          ).projects[0],
        ),
         //Client routes
        '/clientHome': (context) => const ClientHomeScreen(userRole: 'Client'),
        '/clientTimeScheduling': (context) => const ClientTimeSchedulingScreen(),
        '/clientSettings': (context) => const ClientSettingsScreen(),
        '/clientFeedback': (context) => const ClientFeedbackScreen(),
        '/clientProfile': (context) => const clientProfileScreen(),
        '/clientAnalytics': (context)  {final project = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return CReportsAnalyticsScreen(project: project);},
        '/clientProjects': (context) => const ClientProjectsScreen(),
        '/ClientTeamOverview': (context) {
          final project =
          ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;

          return ClientTeamOverviewScreen(project: project);
        },
        '/clientMemberSprintPlanning':
            (context) => ClientSprintPlanningScreen(
          project:
          Provider.of<ProjectService>(
            context,
            listen: false,
          ).projects[0],
        ),
        '/client/project_details': (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return ClientProjectDetailsScreen(projectId: '',);
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
