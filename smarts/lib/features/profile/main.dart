import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  User? _user;
  Map<String, dynamic> _quizPerformance = {};
  Map<String, dynamic> _memoryGamePerformance = {};
  Map<String, dynamic> _flashcardPerformance = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _user = FirebaseAuth.instance.currentUser;
      if (_user != null) {
        await Future.wait([
          _loadQuizPerformance(),
          _loadMemoryGamePerformance(),
          _loadFlashcardPerformance(),
        ]);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadQuizPerformance() async {
    await _loadPerformance('quiz_performance', _quizPerformance);
  }

  Future<void> _loadMemoryGamePerformance() async {
    await _loadPerformance('memory-game-perf', _memoryGamePerformance);
  }

  Future<void> _loadFlashcardPerformance() async {
    await _loadPerformance('flashcard_performance', _flashcardPerformance);
  }

  Future<void> _loadPerformance(String collection, Map<String, dynamic> target) async {
    try {
      var doc = await FirebaseFirestore.instance.collection(collection).doc(_user!.uid).get();
      if (doc.exists) {
        setState(() {
          target.clear();
          target.addAll(doc.data() as Map<String, dynamic>);
        });
      }
    } catch (e) {
      debugPrint('Error loading $collection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Learning Progress"), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildUserHeader(),
          const SizedBox(height: 30),
          _buildPerformanceGrid(),
        ]),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          CircleAvatar(radius: 40, child: Text(_user!.displayName?[0].toUpperCase() ?? _user!.email![0].toUpperCase())),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_user!.displayName ?? _user!.email!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(_user!.email!, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildPerformanceGrid() {
    return Column(children: [
      _buildPerformanceCard("Flashcards", Icons.style, Colors.orange, _flashcardPerformance),
      _buildPerformanceCard("Quizzes", Icons.quiz, Colors.green, _quizPerformance),
      _buildPerformanceCard("Memory Game", Icons.psychology, Colors.purple, _memoryGamePerformance),
    ]);
  }

  Widget _buildPerformanceCard(String title, IconData icon, Color color, Map<String, dynamic> performance) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: color, size: 30), const SizedBox(width: 15), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 20),
          if (performance.isEmpty) const Text("No activity yet. Start learning!", style: TextStyle(color: Colors.grey, fontSize: 16))
          else ..._buildPerformanceMetrics(performance, color),
        ]),
      ),
    );
  }

  List<Widget> _buildPerformanceMetrics(Map<String, dynamic> performance, Color color) {
    List<Widget> metrics = [];
    performance.forEach((key, value) {
      if (key != 'lastAttemptDate') {
        double progressValue = (value is num && value > 0) ? (value / 100).clamp(0.0, 1.0) : 0.0;
        String displayValue = "${(progressValue * 100).toStringAsFixed(1)}";
        
        metrics.add(Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_formatKey(key), style: const TextStyle(fontSize: 16)),
              Text(displayValue, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ]),
        ));
      }
    });
    return metrics;
  }

  String _formatKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
  }
}
