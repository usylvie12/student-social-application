import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/matching_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final MatchingService _matchingService = MatchingService();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> matches = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMatches();
  }

  Future<void> loadMatches() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final results = await _matchingService.findMatches(user.uid);

    setState(() {
      matches = results;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Students')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : matches.isEmpty
          ? const Center(child: Text('No matching students found yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final student = matches[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(student['university']),

                        Text(student['country']),

                        const SizedBox(height: 10),

                        Text(
                          'Languages: '
                          '${student['languages'].join(', ')}',
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Interests: '
                          '${student['interests'].join(', ')}',
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Match score: '
                          '${student['score']}',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
