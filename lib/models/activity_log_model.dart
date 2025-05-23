// In activity_log_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String userId;
  final String userName;
  final String projectId;
  final String action; // created, updated, deleted, completed, assigned
  final String description;
  final Timestamp timestamp;
  final String entityType; // task, sprint, project, user, backlog, retrospective
  final String entityId;
  final String entityName; // The name of the entity that was affected

  ActivityLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.projectId,
    required this.action,
    required this.description,
    required this.timestamp,
    required this.entityType,
    required this.entityId,
    required this.entityName,
  });

  factory ActivityLog.fromFirestore(Map<String, dynamic> data, String id) {
    return ActivityLog(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      projectId: data['projectId'] ?? '',
      action: data['action'] ?? '',
      description: data['description'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      entityType: data['entityType'] ?? 'other',
      entityId: data['entityId'] ?? '',
      entityName: data['entityName'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'projectId': projectId,
      'action': action,
      'description': description,
      'timestamp': timestamp,
      'entityType': entityType,
      'entityId': entityId,
      'entityName': entityName,
    };
  }
}