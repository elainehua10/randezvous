import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/auth.dart';
import 'package:frontend/models/group.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/group_preview.dart';
import 'package:http/http.dart';
import 'package:frontend/member_profile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  List<User> _userResults = [];
  List<Group> _groupResults = [];
  bool _isLoading = false;
  final Set<String> _joiningGroups = {}; // Track groups being joined

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _searchController.clear();
          _userResults = [];
          _groupResults = [];
        });
        // Perform an empty search right away to load all public groups
        _performSearch('');
      }
    });
    if (_tabController.index == 1) {
      _performSearch('');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    if (query.trim().isEmpty) {
      await _fetchAllPublicGroups();
      return;
    }

    try {
      if (_tabController.index == 0) {
        Response response = await Auth.makeAuthenticatedPostRequest(
          "user/search",
          {"username": query.trim()},
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          List<User> results =
              (responseData["users"] as List)
                  .map(
                    (user) => User(
                      id: user["id"],
                      name: "${user["first_name"]} ${user["last_name"]}",
                      avatarUrl: user["profile_picture"],
                      username: user["username"] ?? '',
                    ),
                  )
                  .toList();

          setState(() {
            _userResults = results;
            _groupResults = [];
          });
        } else {
          _showErrorSnackBar('Failed to search users: ${response.body}');
          setState(() {
            _userResults = [];
          });
        }
      } else {
        Response response = await Auth.makeAuthenticatedPostRequest(
          "groups/search",
          {"groupName": query.trim()},
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          List<Group> results =
              (responseData["groups"] as List)
                  .map(
                    (group) => Group(
                      id: group["id"],
                      name: group["name"],
                      leaderId: group["leader_id"],
                      isPublic: group["is_public"],
                      iconUrl: group["icon_url"],
                    ),
                  )
                  .toList();

          setState(() {
            _groupResults = results;
            _userResults = [];
          });
        } else {
          _showErrorSnackBar('Failed to search groups: ${response.body}');
          setState(() {
            _groupResults = [];
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error during search: $e');
      setState(() {
        _userResults = [];
        _groupResults = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllPublicGroups() async {
    try {
      Response response = await Auth.makeAuthenticatedPostRequest(
        "groups/all-public",
        {},
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<Group> results =
            (responseData["groups"] as List)
                .map(
                  (group) => Group(
                    id: group["id"],
                    name: group["name"],
                    leaderId: group["leader_id"],
                    isPublic: group["is_public"],
                    iconUrl: group["icon_url"],
                  ),
                )
                .toList();
        setState(() {
          _groupResults = results;
          _userResults = [];
        });
      } else {
        _showErrorSnackBar(
          'Failed to load all public groups: ${response.body}',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed loading public groups: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGroup(String groupId) async {
    setState(() {
      _joiningGroups.add(groupId);
    });

    try {
      final response = await Auth.makeAuthenticatedPostRequest("groups/join", {
        "groupId": groupId,
      });

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Successfully joined the group!');
        _performSearch(_searchController.text);
      } else {
        _showErrorSnackBar('Failed to join group: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error joining group: $e');
    } finally {
      setState(() {
        _joiningGroups.remove(groupId);
      });
    }
  }

  Future<void> _blockUser(String blockedUserId) async {
    try {
      final response = await Auth.makeAuthenticatedPostRequest("user/block", {
        "blockedId": blockedUserId,
      });

      if (response.statusCode == 200) {
        _showSuccessSnackBar('User blocked successfully!');
        // Remove the blocked user from the results
        setState(() {
          _userResults.removeWhere((user) => user.id == blockedUserId);
        });
      } else {
        _showErrorSnackBar('Failed to block user: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error blocking user: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Search", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber[800],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Users"), Tab(text: "Groups")],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    _tabController.index == 0
                        ? 'Search users'
                        : 'Search groups',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.amber[800]!),
                )
              ),
              onSubmitted: _performSearch,
              onChanged: (value) {
                if (value.isEmpty) _performSearch('');
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildUserResults(), _buildGroupResults()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_userResults.isEmpty) {
      return const Center(
        child: Text('No users found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
            child:
                user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Text(user.name.isNotEmpty == true ? user.name[0] : 'U')
                    : null,
          ),
          title: Text(user.name ?? 'Unnamed User'),
          subtitle: Text('@${user.username ?? ''}'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') {
                _showBlockConfirmationDialog(user);
              } else if (value == 'report') {
                _showReportConfirmation(user);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Block'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report_gmailerrorred, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Report'),
                      ],
                    ),
                  ),
                ],
            icon: const Icon(Icons.more_vert),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MemberProfileScreen(userId: user.id),
              ),
            );
          },
        );
      },
    );
  }

  void _showBlockConfirmationDialog(User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Block User'),
          content: Text(
            'Are you sure you want to block ${user.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _blockUser(user.id ?? '');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  void _showReportConfirmation(User user) {
    final List<String> reportReasons = [
      "Inappropriate content",
      "Harassment or bullying",
      "Fake profile",
      "Spam",
      "Other"
    ];

    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        String selectedReason = reportReasons[0];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Report User"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...reportReasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedReason = value;
                            });
                          }
                        },
                      );
                    }).toList(),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: "Additional details (optional)",
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("Submit"),
                  onPressed: () async {
                    Navigator.pop(context);

                    // Replace with API call
                    print("Reporting ${user.name}");
                    print("Reason: $selectedReason");
                    print("Details: ${descriptionController.text}");

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Report submitted. Thank you.")),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildGroupResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_groupResults.isEmpty) {
      return const Center(
        child: Text('No groups found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _groupResults.length,
      itemBuilder: (context, index) {
        final group = _groupResults[index];
        final isJoining = _joiningGroups.contains(group.id);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                group.iconUrl != null && group.iconUrl!.isNotEmpty
                    ? NetworkImage(group.iconUrl!)
                    : null,
            child:
                group.iconUrl == null || group.iconUrl!.isEmpty
                    ? const Icon(Icons.group)
                    : null,
          ),
          title: Text(group.name ?? "Unnamed group"),
          trailing: ElevatedButton(
            onPressed: isJoining ? null : () => _joinGroup(group.id ?? "no"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child:
                isJoining
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Join'),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupPreview(groupId: group.id ?? ''),
              ),
            );
          },
        );
      },
    );
  }
}
