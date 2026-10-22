import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FullProfileScreen extends StatelessWidget {
  final String userId;

  const FullProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('publicProfiles')
            .doc(userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load the student profile.'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile not found.'));
          }

          final data = snapshot.data!.data()!;

          String displayValue(dynamic value) {
            if (value == null || value.toString().trim().isEmpty) {
              return 'Not provided';
            }
            return value.toString();
          }

          List<String> displayList(dynamic value) {
            if (value is List) {
              return value.map((item) => item.toString()).toList();
            }
            return [];
          }

          Widget profileField(String label, dynamic value) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(displayValue(value)),
                ],
              ),
            );
          }

          Widget profileList(String label, dynamic value) {
            final items = displayList(value);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    const Text('Not provided')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: items
                          .map((item) => Chip(label: Text(item)))
                          .toList(),
                    ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 42,
                  child: Icon(Icons.person, size: 45),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  displayValue(data['name']),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              profileField('University', data['university']),
              profileField('City', data['city']),
              profileField('Country', data['country']),
              profileField('Preferred language', data['preferredLanguage']),
              profileList('Languages', data['languages']),
              profileList('Interests', data['interests']),
            ],
          );
        },
      ),
    );
  }
}
