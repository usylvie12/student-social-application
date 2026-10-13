import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController messageController = TextEditingController();

  Future<void> sendMessage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    try {
      final publicProfile = await _firestore
          .collection('publicProfiles')
          .doc(user.uid)
          .get();

      String senderName =
          publicProfile.data()?['name']?.toString().trim() ?? '';

      if (senderName.isEmpty) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        senderName = userDoc.data()?['name']?.toString().trim() ?? '';
      }

      if (senderName.isEmpty) {
        senderName = user.email ?? 'Unknown user';
      }

      await _firestore
          .collection('groupConversations')
          .doc(widget.groupId)
          .collection('messages')
          .add({
            'senderId': user.uid,
            'senderName': senderName,
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      messageController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not send message: $e')));
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You are not logged in.')),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(widget.groupName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('groupConversations')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading group messages:\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\n'
                      'Start the group conversation!',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;

                    final senderId = message['senderId'];
                    final text = message['text'] ?? '';

                    final senderName = message['senderName']?.toString().trim();

                    final displayName =
                        (senderName != null && senderName.isNotEmpty)
                        ? (senderId == user.uid ? 'You' : senderName)
                        : (senderId == user.uid ? 'You' : 'Group member');

                    final isMe = senderId == user.uid;

                    final createdAt = message['createdAt'];

                    final dateText = createdAt is Timestamp
                        ? createdAt.toDate().toLocal().toString().substring(
                            0,
                            16,
                          )
                        : 'Sending...';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sender name.
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Message content.
                            Text(
                              text.toString(),
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),

                            // Date and time.
                            Text(
                              dateText,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a group message...',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send),
                    tooltip: 'Send group message',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
