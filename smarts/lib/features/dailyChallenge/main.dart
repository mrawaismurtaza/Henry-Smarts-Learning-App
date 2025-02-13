import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailChallenge extends StatefulWidget {
  const DailChallenge({super.key});

  @override
  State<DailChallenge> createState() => _DailChallengeState();
}

class _DailChallengeState extends State<DailChallenge> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  Map<String, dynamic>? todayChallenge;
  bool isLoading = true;
  bool isChallengeCompleted = false;
  int currentStreak = 0;
  String userAnswer = '';

  @override
  void initState() {
    super.initState();
    _loadTodayChallenge();
    _loadUserProgress();
  }

  Future<void> _loadTodayChallenge() async {
    try {
      final challengeDoc = await _firestore
          .collection('dailychallenge')
          .doc(DateTime.now().toString().split(' ')[0])
          .get();

      setState(() {
        todayChallenge = challengeDoc.data();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading challenge: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserProgress() async {
    try {
      final userDoc = await _firestore
          .collection('dailychallenge-perf')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          currentStreak = userDoc.data()?['streak'] ?? 0;
          isChallengeCompleted = userDoc.data()?['lastCompleted'] == 
              DateTime.now().toString().split(' ')[0];
        });
      }
    } catch (e) {
      print('Error loading user progress: $e');
    }
  }

  Future<void> _updateUserProgress() async {
    try {
      final today = DateTime.now().toString().split(' ')[0];
      
      await _firestore.collection('dailychallenge-perf').doc(userId).set({
        'lastCompleted': today,
        'streak': currentStreak + 1,
        'challengeType': todayChallenge?['type'],
        'language': todayChallenge?['language'],
      }, SetOptions(merge: true));

      setState(() {
        isChallengeCompleted = true;
        currentStreak++;
      });
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  Widget _buildChallengeContent() {
    switch (todayChallenge?['type']) {
      case 'vocabulary':
        return _buildVocabularyChallenge();
      case 'phrase':
        return _buildPhraseChallenge();
      case 'grammar':
        return _buildGrammarChallenge();
      default:
        return _buildVocabularyChallenge();
    }
  }

  Widget _buildVocabularyChallenge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Word of the Day: ${todayChallenge?['word']}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pronunciation: ${todayChallenge?['pronunciation']}',
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Meaning: ${todayChallenge?['meaning']}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Text(
          'Example: ${todayChallenge?['example']}',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPhraseChallenge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Phrase',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          todayChallenge?['phrase'] ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Translation: ${todayChallenge?['translation']}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 15),
        Text(
          'Usage: ${todayChallenge?['usage']}',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildGrammarChallenge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grammar Challenge',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          todayChallenge?['rule'] ?? '',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 15),
        Text(
          'Example: ${todayChallenge?['example']}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 15),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Write your practice sentence...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              userAnswer = value;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (todayChallenge == null) {
      return const Center(child: Text('No challenge available today'));
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/02.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Daily Challenge',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    todayChallenge?['language'] ?? 'English',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Streak: $currentStreak days',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: _buildChallengeContent(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isChallengeCompleted ? null : _updateUserProgress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isChallengeCompleted
                            ? Colors.green
                            : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isChallengeCompleted
                            ? 'Completed!'
                            : 'Complete Challenge',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}