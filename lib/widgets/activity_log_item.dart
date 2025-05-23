import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_log_model.dart';

class ActivityLogItem extends StatelessWidget {
  final ActivityLog log;
  final VoidCallback? onTap;

  const ActivityLogItem({
    Key? key,
    required this.log,
    this.onTap,
  }) : super(key: key);

  IconData _getActionIcon(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'task':
        return Icons.task_alt;
      case 'sprint':
        return Icons.speed;
      case 'backlog':
        return Icons.view_list;
      case 'project':
        return Icons.work;
      case 'user':
        return Icons.person;
      case 'retrospective':
        return Icons.feedback;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'task':
        return Colors.green;
      case 'sprint':
        return Colors.purple;
      case 'backlog':
        return Colors.orange;
      case 'project':
        return Colors.blue;
      case 'user':
        return Colors.teal;
      case 'retrospective':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert Timestamp to DateTime before formatting
    final DateTime dateTime = log.timestamp.toDate();
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(dateTime);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getActionColor(log.entityType).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActionIcon(log.entityType),
                  color: _getActionColor(log.entityType),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action description
                    Text(
                      '${log.userName} ${log.action} ${log.entityName}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                    SizedBox(height: 4),
                    // Category badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getActionColor(log.entityType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.entityType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getActionColor(log.entityType),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Timestamp
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}