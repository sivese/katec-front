import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivityCardWidget extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const ActivityCardWidget({super.key, required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: activity.type.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(activity.type.icon, color: activity.type.color, size: 20),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity.location,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              '${_formatTime(activity.startTime)} - ${_formatTime(activity.endTime)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (activity.description.isNotEmpty)
              Text(
                activity.description,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: activity.status.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            activity.status.displayName,
            style: TextStyle(
              color: activity.status.color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
