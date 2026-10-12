import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/analytics_service.dart';

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
  final cityController = TextEditingController();
  final countryController = TextEditingController();
  String preferredLanguage = 'English';
  List<String> languages = [];
  List<String> interests = [];

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    universityController.dispose();
    cityController.dispose();
    countryController.dispose();

    super.dispose();
  }

  Future<void> loadProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      return;
    }

    try {
      final document = await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) return;

      if (document.exists) {
        final data = document.data()!;

        nameController.text = data['name']?.toString() ?? '';

        universityController.text = data['university']?.toString() ?? '';

        cityController.text = data['city']?.toString() ?? '';

        countryController.text = data['country']?.toString() ?? '';

        preferredLanguage = data['preferredLanguage']?.toString() ?? 'English';

        languages = List<String>.from(data['languages'] ?? []);

        interests = List<String>.from(data['interests'] ?? []);
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      debugPrint('Profile loading error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> addLanguage() async {
    final language = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text('Add Language'),

          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Language',
              hintText: 'Example: English',
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (language != null && language.isNotEmpty) {
      setState(() {
        languages.add(language);
      });
    }
  }

  Future<void> addInterest() async {
    final interest = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text('Add Interest'),

          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Interest',
              hintText: 'Example: Programming',
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (interest != null && interest.isNotEmpty) {
      setState(() {
        interests.add(interest);
      });
    }
  }

  Future<void> saveProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'university': universityController.text.trim(),
        'city': cityController.text.trim(),
        'country': countryController.text.trim(),
        'preferredLanguage': preferredLanguage,
        'languages': languages,
        'interests': interests,
      });

      await AnalyticsService.logProfileCompleted();

      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    }
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
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Example: Poznań',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: countryController,
              decoration: const InputDecoration(
                labelText: 'Country of Origin',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: preferredLanguage,
              decoration: const InputDecoration(
                labelText: 'Preferred Language',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Polish', child: Text('Polish')),
                DropdownMenuItem(value: 'French', child: Text('French')),
                DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    preferredLanguage = value;
                  });
                }
              },
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
