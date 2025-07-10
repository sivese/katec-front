import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivityFilterWidget extends StatelessWidget {
  final ActivityType? selectedType;
  final Function(ActivityType?) onTypeChanged;

  const ActivityFilterWidget({
    super.key,
    this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip(null, 'All'),
          ...ActivityType.values.map(
            (type) => _buildFilterChip(type, type.displayName),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ActivityType? type, String label) {
    final isSelected = selectedType == type;
    final color = type?.color ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          onTypeChanged(selected ? type : null);
        },
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: color,
        checkmarkColor: Colors.white,
        side: BorderSide(color: isSelected ? color : Colors.grey, width: 1),
      ),
    );
  }
}
