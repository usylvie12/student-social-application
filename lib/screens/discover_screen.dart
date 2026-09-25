import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  String normalizeText(String value) {
    return value.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('You are not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Discover Students')),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('publicProfiles')
            .doc(currentUser.uid)
            .get(),

        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading your profile:\n'
                '${userSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(
              child: Text('Your public profile could not be found.'),
            );
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;

          final currentCity = normalizeText(
            (userData['city'] ?? '').toString(),
          );

          final currentCountry = normalizeText(
            (userData['country'] ?? '').toString(),
          );

          final currentInterests = List<String>.from(
            userData['interests'] ?? [],
          ).map(normalizeText).toList();

          if (currentCity.isEmpty || currentCountry.isEmpty) {
            return const Center(
              child: Text(
                'Please complete your city and country '
                'information first.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('publicProfiles')
                .snapshots(),

            builder: (context, profilesSnapshot) {
              if (profilesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (profilesSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading students:\n'
                    '${profilesSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!profilesSnapshot.hasData) {
                return const Center(child: Text('No students found.'));
              }

              final profiles = profilesSnapshot.data!.docs;

              final matchingProfiles = profiles.where((profile) {
                if (profile.id == currentUser.uid) {
                  return false;
                }

                final data = profile.data() as Map<String, dynamic>;

                final otherCity = normalizeText(
                  (data['city'] ?? '').toString(),
                );

                final otherCountry = normalizeText(
                  (data['country'] ?? '').toString(),
                );

                final otherInterests = List<String>.from(
                  data['interests'] ?? [],
                ).map(normalizeText).toList();

                final sameCity = otherCity == currentCity;

                final sameCountry = otherCountry == currentCountry;

                final sharedInterests = currentInterests
                    .where((interest) => otherInterests.contains(interest))
                    .toList();

                final hasSharedInterest = sharedInterests.isNotEmpty;

                return sameCity || sameCountry || hasSharedInterest;
              }).toList();

              // No matches
              if (matchingProfiles.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 70,
                          color: Colors.grey,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'No matching students found.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'We could not find students who '
                          'share your city, country, '
                          'or interests.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Display matching students
              return ListView.builder(
                padding: const EdgeInsets.all(16),

                itemCount: matchingProfiles.length,

                itemBuilder: (context, index) {
                  final profile = matchingProfiles[index];

                  final data = profile.data() as Map<String, dynamic>;

                  final name = data['name'] ?? 'Unknown student';

                  final university = data['university'] ?? 'Unknown university';

                  final city = data['city'] ?? 'Unknown city';

                  final country = data['country'] ?? 'Unknown country';

                  final otherCity = normalizeText(city.toString());

                  final otherCountry = normalizeText(country.toString());

                  final otherInterests = List<String>.from(
                    data['interests'] ?? [],
                  ).map(normalizeText).toList();

                  final sameCity = otherCity == currentCity;

                  final sameCountry = otherCountry == currentCountry;

                  final sharedInterests = currentInterests
                      .where((interest) => otherInterests.contains(interest))
                      .toList();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),

                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // Name
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 28,
                                child: Icon(Icons.person),
                              ),

                              const SizedBox(width: 15),

                              Expanded(
                                child: Text(
                                  name.toString(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // University
                          Text(
                            'University: '
                            '$university',
                          ),

                          const SizedBox(height: 5),

                          // Location
                          Text(
                            'Location: '
                            '$city, $country',
                          ),

                          const SizedBox(height: 15),

                          // Why they matched
                          const Text(
                            'Matched because:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 8),

                          if (sameCity)
                            const Chip(
                              avatar: Icon(Icons.location_city, size: 18),
                              label: Text('Same city'),
                            ),

                          if (sameCountry)
                            const Chip(
                              avatar: Icon(Icons.public, size: 18),
                              label: Text('Same country'),
                            ),

                          if (sharedInterests.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sharedInterests.map((interest) {
                                return Chip(
                                  avatar: const Icon(Icons.favorite, size: 18),
                                  label: Text('Interest: $interest'),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 15),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      otherUserId: profile.id,
                                      otherUserName: name.toString(),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.message),
                              label: const Text('Message'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
