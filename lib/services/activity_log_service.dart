import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/activity_log_model.dart';

class ActivityLogService extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  ActivityLogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get activity logs for a specific project
  Stream<List<ActivityLog>> getProjectActivityLogs(String projectId) {
    return _firestore
        .collection('activity_logs')
        .where('projectId', isEqualTo: projectId)
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to recent logs
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityLog.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Filter logs by action type
  Stream<List<ActivityLog>> getFilteredLogs(String projectId, String actionType) {
    if (actionType == 'all') {
      return getProjectActivityLogs(projectId);
    }

    return _firestore
        .collection('activity_logs')
        .where('projectId', isEqualTo: projectId)
        .where('entityType', isEqualTo: actionType)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityLog.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Filter logs by user
  Stream<List<ActivityLog>> getLogsByUser(String projectId, String userId) {
    return _firestore
        .collection('activity_logs')
        .where('projectId', isEqualTo: projectId)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityLog.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Add an activity log (for other parts of the app to use)
  Future<void> addActivityLog(ActivityLog log) async {
    try {
      await _firestore.collection('activity_logs').add(log.toFirestore());
    } catch (e) {
      print('Error adding activity log: $e');
      rethrow;
    }
  }
}