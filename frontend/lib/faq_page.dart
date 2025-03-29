import 'package:flutter/material.dart';

class FAQPage extends StatefulWidget {
  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<Map<String, String>> allFaqs = [
    {
      "question": "How do I edit my profile information?",
      "answer":
          "You can edit your profile by navigating to the 'Edit Profile' section from the Settings page. Here, you can update your name, username, and profile picture.",
    },
    {
      "question": "How can I enable or disable notifications?",
      "answer":
          "Go to the Settings page and toggle the 'Enable Notifications' option to turn notifications on or off.",
    },
    {
      "question": "What should I do if I forget my password?",
      "answer":
          "On the login screen, select 'Forgot Password' and follow the instructions to reset your password via email.",
    },
    {
      "question": "How do I report a bug or issue?",
      "answer":
          "Navigate to the 'Report an Issue' section in Settings and describe the problem. Our team will review and address it promptly.",
    },
    {
      "question": "Is my data secure?",
      "answer":
          "Yes. We use token-based authentication and data encryption to protect your personal information. You can read more in the 'Privacy & Security' section.",
    },
    {
      "question": "Can I delete my account?",
      "answer":
          "Yes, you can delete your account from the 'Account Actions' section in your profile settings. This action is permanent and cannot be undone.",
    },
    {
      "question": "How do I change my profile picture?",
      "answer":
          "Tap on your profile picture in the Profile section and select 'Choose from library' or 'Take photo' to update it.",
    },
    {
      "question": "Why am I not receiving notifications?",
      "answer":
          "Ensure that notifications are enabled in both the app settings and your device settings. If the issue persists, try logging out and back in.",
    },
    {
      "question": "How do I log out?",
      "answer":
          "Go to the 'Account Actions' section in Settings and select 'Log out' to safely sign out of your account.",
    },
  ];

  List<Map<String, String>> filteredFaqs = [];
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    filteredFaqs = allFaqs;

    // Add listener to search field
    searchController.addListener(() {
      filterFaqs(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void filterFaqs(String query) {
    setState(() {
      if (query.isEmpty) {
        // If search is empty, show all FAQs
        filteredFaqs = allFaqs;
        isSearching = false;
      } else {
        // Filter FAQs by question text (case insensitive)
        filteredFaqs =
            allFaqs
                .where(
                  (faq) => faq["question"]!.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .toList();
        isSearching = true;
      }
    });
  }

  void clearSearch() {
    searchController.clear();
    filterFaqs("");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Frequently Asked Questions",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.amber[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            color: Colors.white,
            child: Column(
              children: [
                Icon(
                  Icons.question_answer_rounded,
                  size: 48,
                  color: Colors.amber[800],
                ),
                const SizedBox(height: 16),
                Text(
                  "How can we help you?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Find answers to the most common questions below",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search FAQs",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    suffixIcon:
                        isSearching
                            ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
                              onPressed: clearSearch,
                            )
                            : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.amber[800]!,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                filteredFaqs.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No matching questions found",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Try using different keywords",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: filteredFaqs.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                              colorScheme: ColorScheme.light(
                                primary: Colors.amber[800]!,
                              ),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.all(16),
                              childrenPadding: EdgeInsets.zero,
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.help_outline_rounded,
                                    size: 22,
                                    color: Colors.amber[800],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      filteredFaqs[index]['question']!,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.subdirectory_arrow_right_rounded,
                                        size: 18,
                                        color: Colors.amber[600],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          filteredFaqs[index]['answer']!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.5,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  "Can't find what you're looking for?",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Contact support action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Contact Support",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
