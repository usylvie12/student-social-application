import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/profile_screen.dart';
import 'screens/discover_screen.dart';

import 'screens/groups_screen.dart';
import 'screens/event_screen.dart';
import 'services/analytics_service.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAnalytics.instance.logLogin(loginMethod: 'email');

  runApp(const StudentConnectApp());
}

class StudentConnectApp extends StatelessWidget {
  const StudentConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudentConnect',
      home: const LoginScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> setAttendance(String eventId, String status) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('attendance')
        .doc(user.uid)
        .set({
          'status': status,
          'userId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (status == 'attending') {
      await AnalyticsService.logEventJoined();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StudentConnect')),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('dateTime')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading events:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final events = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),

            children: [
              const Text(
                'Welcome to StudentConnect!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // DISCOVER STUDENTS
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DiscoverScreen(),
                      ),
                    );
                  },
                  child: const Text('Discover Students'),
                ),
              ),

              const SizedBox(height: 10),

              // GROUPS
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GroupsScreen(),
                      ),
                    );
                  },
                  child: const Text('Groups'),
                ),
              ),

              const SizedBox(height: 10),

              // PROFILE
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: const Text('My Profile'),
                ),
              ),

              const SizedBox(height: 10),

              // CREATE EVENT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.event),
                  label: const Text('Create Event'),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Upcoming Events',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              // NO EVENTS
              if (events.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No upcoming events yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // EVENT LIST
              ...events.map((event) {
                final data = event.data() as Map<String, dynamic>;

                final title = data['title'] ?? 'Untitled Event';

                final description = data['description'] ?? '';

                final location = data['location'] ?? 'Unknown location';

                final creatorName = data['creatorName'] ?? 'Student';

                final timestamp = data['dateTime'] as Timestamp?;

                String dateText = 'Date not available';

                if (timestamp != null) {
                  final date = timestamp.toDate();

                  dateText =
                      '${date.day}/'
                      '${date.month}/'
                      '${date.year} '
                      '${date.hour.toString().padLeft(2, '0')}:'
                      '${date.minute.toString().padLeft(2, '0')}';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // EVENT TITLE + DELETE BUTTON
                        Row(
                          children: [
                            const Icon(Icons.event, size: 30),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                title.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            if (FirebaseAuth.instance.currentUser?.uid ==
                                data['createdBy'])
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete event',

                                onPressed: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) {
                                      return AlertDialog(
                                        title: const Text('Delete Event'),

                                        content: const Text(
                                          'Are you sure you want to delete this event?',
                                        ),

                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(dialogContext)
                                                  .pop(false);
                                            },
                                            child: const Text('Cancel'),
                                          ),

                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(dialogContext)
                                                  .pop(true);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (shouldDelete != true) {
                                    return;
                                  }

                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(event.id)
                                        .delete();

                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Event deleted'),
                                      ),
                                    );
                                  } on FirebaseException catch (e) {
                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not delete event: ${e.message}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text('Date & Time: $dateText'),

                        const SizedBox(height: 6),

                        Text('Location: ${location.toString()}'),

                        const SizedBox(height: 6),

                        Text('Created by: ${creatorName.toString()}'),

                        if (description.toString().isNotEmpty) ...[
                          const SizedBox(height: 10),

                          Text(description.toString()),
                        ],
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('events')
                              .doc(event.id)
                              .collection('attendance')
                              .where('status', isEqualTo: 'attending')
                              .snapshots(),
                          builder: (context, attendanceSnapshot) {
                            if (attendanceSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Loading attendance...');
                            }

                            if (attendanceSnapshot.hasError) {
                              return const Text('Unable to load attendance.');
                            }

                            final attendingCount =
                                attendanceSnapshot.data?.docs.length ?? 0;

                            final currentUserId =
                                FirebaseAuth.instance.currentUser?.uid;

                            final creatorId = data['createdBy'];

                            if (currentUserId != creatorId) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.people, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$attendingCount '
                                    '${attendingCount == 1 ? 'person' : 'people'} '
                                    'will attend',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            // ATTEND
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await setAttendance(event.id, 'attending');

                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'You are attending this event.',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not save attendance: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Attend'),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // NOT ATTEND
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    await setAttendance(
                                      event.id,
                                      'not_attending',
                                    );

                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'You are not attending this event.',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not save attendance: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Not Attend'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // LOGOUT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService().signOut();

                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Logout'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    setState(() {
      loading = true;
    });

    final user = await _authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      loading = false;
    });

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .orderBy('dateTime')
              .snapshots(),

          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildPage(
                context,
                const Text(
                  'Events could not be loaded.',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final events = snapshot.data?.docs ?? [];

            return _buildPage(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator()),

                  if (snapshot.connectionState != ConnectionState.waiting &&
                      events.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('No upcoming events yet.')),
                      ),
                    ),

                  ...events.map((event) {
                    final data = event.data() as Map<String, dynamic>;

                    final title = data['title'] ?? 'Untitled Event';

                    final description = data['description'] ?? '';

                    final location = data['location'] ?? 'Unknown location';

                    final creatorName = data['creatorName'] ?? 'Student';

                    final timestamp = data['dateTime'] as Timestamp?;

                    String dateText = 'Date not available';

                    if (timestamp != null) {
                      final date = timestamp.toDate();

                      dateText =
                          '${date.day}/'
                          '${date.month}/'
                          '${date.year} '
                          '${date.hour.toString().padLeft(2, '0')}:'
                          '${date.minute.toString().padLeft(2, '0')}';
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                title.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text('Date & Time: $dateText'),

                              const SizedBox(height: 5),

                              Text(
                                'Location: '
                                '${location.toString()}',
                              ),

                              const SizedBox(height: 5),

                              Text(
                                'Created by: '
                                '${creatorName.toString()}',
                              ),

                              if (description.toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(description.toString()),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, Widget eventsSection) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),

      child: Column(
        children: [
          const Icon(Icons.people, size: 80, color: Colors.blue),

          const SizedBox(height: 20),

          const Text(
            'StudentConnect',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          const Text(
            'Connect with students around you',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),

          const SizedBox(height: 30),

          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 50,

            child: ElevatedButton(
              onPressed: loading ? null : login,

              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Login', style: TextStyle(fontSize: 18)),
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },

            child: const Text('Create an account'),
          ),

          const SizedBox(height: 30),

          const Divider(),

          const SizedBox(height: 20),

          eventsSection,
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final universityController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();
  final interestsController = TextEditingController();

  bool loading = false;
  String preferredLanguage = 'English';

  Future<void> register() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final user = await _authService.register(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Registration failed')));
        }
        return;
      }

      final interests = interestsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final profileData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'university': universityController.text.trim(),
        'city': cityController.text.trim(),
        'country': countryController.text.trim(),
        'preferredLanguage': preferredLanguage,
        'languages': [preferredLanguage],
        'interests': interests,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _databaseService.createUserProfile(user.uid, profileData);

      await _databaseService.createPublicProfile(user.uid, {
        'name': nameController.text.trim(),
        'university': universityController.text.trim(),
        'city': cityController.text.trim(),
        'country': countryController.text.trim(),
        'preferredLanguage': preferredLanguage,
        'languages': [preferredLanguage],
        'interests': interests,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account created!')));

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.code}');
      debugPrint('Firestore message: ${e.message}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase error: ${e.code}\n${e.message ?? ''}'),
        ),
      );
    } catch (e) {
      debugPrint('Registration error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 70, color: Colors.blue),

              const SizedBox(height: 20),

              const Text(
                'Create your account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
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

              TextField(
                controller: interestsController,
                decoration: const InputDecoration(
                  labelText: 'Interests',
                  hintText: 'Example: Football, Music, Programming',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.favorite),
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: preferredLanguage,
                decoration: const InputDecoration(
                  labelText: 'Preferred Language',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Polish', child: Text('Polish')),
                  DropdownMenuItem(value: 'Swahili', child: Text('Swahili')),
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

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : register,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Register', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
