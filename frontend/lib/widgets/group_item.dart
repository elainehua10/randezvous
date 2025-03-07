import 'package:flutter/material.dart';
import 'package:frontend/models/group.dart';

class GroupItem extends StatelessWidget {
  final Group group;
  final bool isSelected;
  final VoidCallback onTap;

  const GroupItem({
    Key? key,
    required this.group,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
        child:
            group.iconUrl == null
                ? Icon(Icons.group, color: Colors.blue[800])
                : Image.network(
                  group.iconUrl!,
                  height: 80, // Optional: adding height to match icon size
                  width: 80, // Optional: adding width to match icon size
                ),
      ),
      title: Text(group.name ?? 'Unnamed Group'),
      tileColor: isSelected ? Colors.blue[100] : null,
      onTap: onTap,
    );
  }
}
