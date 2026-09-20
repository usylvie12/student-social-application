import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final nameController = TextEditingController();
  final universityController = TextEditingController();
  final countryController = TextEditingController();

  List<String> languages = [];
  List<String> interests = [];

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    final document = await _firestore.collection('users').doc(user.uid).get();

    if (document.exists) {
      final data = document.data()!;

      nameController.text = data['name'] ?? '';
      universityController.text = data['university'] ?? '';
      countryController.text = data['country'] ?? '';

      languages = List<String>.from(data['languages'] ?? []);

      interests = List<String>.from(data['interests'] ?? []);
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> addLanguage() async {
    final languageController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Language'),
          content: TextField(
            controller: languageController,
            decoration: const InputDecoration(
              labelText: 'Language',
              hintText: 'Example: English',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final language = languageController.text.trim();

                if (language.isNotEmpty) {
                  setState(() {
                    languages.add(language);
                  });
                }

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    languageController.dispose();
  }

  Future<void> addInterest() async {
    final interestController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Interest'),
          content: TextField(
            controller: interestController,
            decoration: const InputDecoration(
              labelText: 'Interest',
              hintText: 'Example: Programming',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final interest = interestController.text.trim();

                if (interest.isNotEmpty) {
                  setState(() {
                    interests.add(interest);
                  });
                }

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    interestController.dispose();
  }

  Future<void> saveProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      saving = true;
    });

    await _firestore.collection('users').doc(user.uid).update({
      'name': nameController.text.trim(),
      'university': universityController.text.trim(),
      'country': countryController.text.trim(),
      'languages': languages,
      'interests': interests,
    });

    setState(() {
      saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 45,
                child: Icon(Icons.person, size: 50),
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: universityController,
              decoration: const InputDecoration(
                labelText: 'University',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Languages',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...languages.map((language) {
                  return Chip(
                    label: Text(language),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      setState(() {
                        languages.remove(language);
                      });
                    },
                  );
                }),

                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('Add Language'),
                  onPressed: addLanguage,
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              'Interests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      setState(() {
                        interests.remove(interest);
                      });
                    },
                  );
                }),

                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('Add Interest'),
                  onPressed: addInterest,
                ),
              ],
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saving ? null : saveProfile,
                child: saving
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Save Profile',
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
