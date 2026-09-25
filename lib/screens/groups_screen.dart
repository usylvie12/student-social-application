import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'group_chat_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool loading = true;

  String currentCity = '';
  String currentCountry = '';
  List<String> currentInterests = [];

  @override
  void initState() {
    super.initState();
    loadMyProfile();
  }

  String normalizeText(String value) {
    return value.trim().toLowerCase();
  }

  Future<void> loadMyProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    final profile = await _firestore
        .collection('publicProfiles')
        .doc(user.uid)
        .get();

    if (!profile.exists) {
      setState(() {
        loading = false;
      });
      return;
    }

    final data = profile.data() as Map<String, dynamic>;

    final interestsData = data['interests'] ?? [];

    setState(() {
      currentCity = normalizeText((data['city'] ?? '').toString());

      currentCountry = normalizeText((data['country'] ?? '').toString());

      currentInterests = List<String>.from(interestsData)
          .map(normalizeText)
          .toList();

      loading = false;
    });
  }

  void openSameCityGroup() {
    if (currentCity.isEmpty) {
      showMessage('Please add your city to your profile first.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SameCityStudentsScreen(city: currentCity),
      ),
    );
  }

  void openSameCountryGroup() {
    if (currentCountry.isEmpty) {
      showMessage('Please add your country to your profile first.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SameCountryStudentsScreen(country: currentCountry),
      ),
    );
  }

  void openSameInterestGroup() {
    if (currentInterests.isEmpty) {
      showMessage('Please add at least one interest to your profile first.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SameInterestStudentsScreen(interests: currentInterests),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Group Conversations',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Talk with students who share '
              'your city, country, or interests.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: openSameCityGroup,
                icon: const Icon(Icons.location_city),
                label: const Text('Same City', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: openSameCountryGroup,
                icon: const Icon(Icons.public),
                label: const Text(
                  'Same Country of Origin',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: openSameInterestGroup,
                icon: const Icon(Icons.favorite),
                label: const Text(
                  'Same Interest',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SameCityStudentsScreen extends StatelessWidget {
  final String city;

  const SameCityStudentsScreen({super.key, required this.city});

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
      appBar: AppBar(title: Text('Students in $city')),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('publicProfiles')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading students:\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final students =
                    snapshot.data?.docs.where((student) {
                      if (student.id == currentUser.uid) {
                        return false;
                      }

                      final data = student.data() as Map<String, dynamic>;

                      final studentCity = normalizeText(
                        (data['city'] ?? '').toString(),
                      );

                      return studentCity == city;
                    }).toList() ??
                    [];

                if (students.isEmpty) {
                  return const Center(child: Text('No other students found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),

                  itemCount: students.length,

                  itemBuilder: (context, index) {
                    final data = students[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),

                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),

                        title: Text(
                          (data['name'] ?? 'Unknown student').toString(),
                        ),

                        subtitle: Text(
                          '${data['university'] ?? 'Unknown university'}\n'
                          '${data['city'] ?? ''}, '
                          '${data['country'] ?? ''}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),

            child: SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatScreen(
                        groupId: 'city_$city',
                        groupName: 'Students in $city',
                      ),
                    ),
                  );
                },

                icon: const Icon(Icons.group),

                label: const Text('Open City Group Chat'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SameCountryStudentsScreen extends StatelessWidget {
  final String country;

  const SameCountryStudentsScreen({super.key, required this.country});

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
      appBar: AppBar(title: Text('Students from $country')),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('publicProfiles')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading students:\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final students =
                    snapshot.data?.docs.where((student) {
                      if (student.id == currentUser.uid) {
                        return false;
                      }

                      final data = student.data() as Map<String, dynamic>;

                      final studentCountry = normalizeText(
                        (data['country'] ?? '').toString(),
                      );

                      return studentCountry == country;
                    }).toList() ??
                    [];

                if (students.isEmpty) {
                  return const Center(child: Text('No other students found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),

                  itemCount: students.length,

                  itemBuilder: (context, index) {
                    final data = students[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),

                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),

                        title: Text(
                          (data['name'] ?? 'Unknown student').toString(),
                        ),

                        subtitle: Text(
                          '${data['university'] ?? 'Unknown university'}\n'
                          '${data['city'] ?? ''}, '
                          '$country',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),

            child: SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatScreen(
                        groupId: 'country_$country',
                        groupName: 'Students from $country',
                      ),
                    ),
                  );
                },

                icon: const Icon(Icons.group),

                label: const Text('Open Country Group Chat'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SameInterestStudentsScreen extends StatelessWidget {
  final List<String> interests;

  const SameInterestStudentsScreen({super.key, required this.interests});

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
      appBar: AppBar(title: const Text('Students with Your Interests')),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('publicProfiles')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading students:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final students =
              snapshot.data?.docs.where((student) {
                if (student.id == currentUser.uid) {
                  return false;
                }

                final data = student.data() as Map<String, dynamic>;

                final studentInterests = List<String>.from(
                  data['interests'] ?? [],
                ).map(normalizeText).toList();

                return studentInterests.any(
                  (interest) => interests.contains(interest),
                );
              }).toList() ??
              [];

          if (students.isEmpty) {
            return const Center(
              child: Text(
                'No other students found '
                'with your interests.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),

                  itemCount: students.length,

                  itemBuilder: (context, index) {
                    final data = students[index].data() as Map<String, dynamic>;

                    final studentInterests = List<String>.from(
                      data['interests'] ?? [],
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),

                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),

                        title: Text(
                          (data['name'] ?? 'Unknown student').toString(),
                        ),

                        subtitle: Text(
                          '${data['university'] ?? 'Unknown university'}\n'
                          'Interests: '
                          '${studentInterests.join(', ')}',
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),

                child: SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      final interest = interests.first;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupChatScreen(
                            groupId: 'interest_$interest',
                            groupName: 'Interest: $interest',
                          ),
                        ),
                      );
                    },

                    icon: const Icon(Icons.group),

                    label: const Text('Open Interest Group Chat'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
