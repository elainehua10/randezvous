import 'package:flutter/material.dart';

class InviteMembersDialog {
  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => _InviteMembersDialog());
  }
}

class _InviteMembersDialog extends StatefulWidget {
  @override
  _InviteMembersDialogState createState() => _InviteMembersDialogState();
}

class _InviteMembersDialogState extends State<_InviteMembersDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];

  // Dummy data for search results
  void _performUserSearch(String userId) {
    setState(() {
      // Clear previous results
      _searchResults.clear();

      // Dummy search logic
      if (userId.isNotEmpty) {
        _searchResults =
            [
                  {'id': 'USR001', 'name': 'John Doe', 'username': '@johndoe'},
                  {
                    'id': 'USR002',
                    'name': 'Jane Smith',
                    'username': '@janesmith',
                  },
                  {
                    'id': 'USR003',
                    'name': 'Bob Johnson',
                    'username': '@bobjohnson',
                  },
                ]
                .where(
                  (user) =>
                      user['id']!.contains(userId) ||
                      user['username']!.contains(userId),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Invite Members'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search for a user by ID:'),
            SizedBox(height: 16),
            // User ID Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter User ID',
                prefixIcon: Icon(Icons.person),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _performUserSearch(_searchController.text);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Search Results
            if (_searchResults.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(user['name']![0])),
                      title: Text(user['name']!),
                      subtitle: Text(user['username']!),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          // Add user functionality to be implemented
                        },
                      ),
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty)
              Text('No results found'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
