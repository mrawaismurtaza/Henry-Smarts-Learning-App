import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smarts/firebase/FirebaseService.dart';

class FlashCard extends StatefulWidget {
  const FlashCard({super.key});

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> {
  FirebaseService _firebaseService = FirebaseService();
  int _currentQuestionIndex = 0;
  int _score = 0;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  Map<String, Color> _answerColors = {};
  
  // Variables to store previous performance data
  double _previousPerformance = 0; 
  int _previousAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      // Fetch previous performance from Firestore
      User? user = _firebaseService.getCurrentUser();
      if (user != null) {
        DocumentReference performanceRef = FirebaseFirestore.instance.collection('flashcard').doc(user.uid);
        DocumentSnapshot docSnapshot = await performanceRef.get();

        if (docSnapshot.exists) {
          double previousPercentage = docSnapshot['percentage'] ?? 0;
          int previousAttempts = docSnapshot['totalAttempts'] ?? 0;
          setState(() {
            _previousPerformance = previousPercentage;
            _previousAttempts = previousAttempts;
          });
        }
      }

      // Load flashcards
      var querySnapshot = await FirebaseFirestore.instance.collection('flashcards').get();
      setState(() {
        _questions = querySnapshot.docs.map((doc) {
          return {
            'question': doc['question'],
            'options': List<String>.from(doc['options']),
            'answer': doc['answer']
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading questions: $e");
    }
  }

  void _answerQuestion(String selectedAnswer) async {
    setState(() {
      if (_questions[_currentQuestionIndex]['answer'] == selectedAnswer) {
        _score++;
        _answerColors[selectedAnswer] = Colors.green;
      } else {
        _answerColors[selectedAnswer] = Colors.red;
        _answerColors[_questions[_currentQuestionIndex]['answer']] = Colors.green;
      }
    });

    await Future.delayed(Duration(seconds: 2));

    if (_currentQuestionIndex + 1 < _questions.length) {
      setState(() {
        _currentQuestionIndex++;
        _answerColors.clear();
      });
    } else {
      _savePerformance();
      _showScoreDialog();
    }
  }

  Future<void> _savePerformance() async {
    User? user = _firebaseService.getCurrentUser();
    if (user != null) {
      try {
        double currentPercentage = (_score / _questions.length) * 100;

        // Combine previous and current performance (using average here)
        double updatedPercentage = ((_previousPerformance * _previousAttempts) + currentPercentage) /
            (_previousAttempts + 1);
        int updatedAttempts = _previousAttempts + 1;

        DocumentReference performanceRef = FirebaseFirestore.instance.collection('flashcard').doc(user.uid);
        DocumentSnapshot docSnapshot = await performanceRef.get();

        if (docSnapshot.exists) {
          await performanceRef.update({
            'percentage': updatedPercentage,
            'totalAttempts': updatedAttempts,
          });
        } else {
          await performanceRef.set({
            'percentage': updatedPercentage,
            'totalAttempts': 1,
          });
        }
      } catch (e) {
        print("Error saving performance: $e");
      }
    }
  }

  void _showScoreDialog() {
    double percentage = (_score / _questions.length) * 100;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Quiz Finished"),
          content: Text("Your score is $_score out of ${_questions.length}\nYour percentage is ${percentage.toStringAsFixed(2)}%"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (_currentQuestionIndex + 1 >= 5) {
                  Navigator.pushReplacementNamed(context, '/');
                } else {
                  setState(() {
                    _currentQuestionIndex = 0;
                    _score = 0;
                    _answerColors.clear();
                  });
                }
              },
              child: Text("Return Home"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/02.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 400,
              width: MediaQuery.of(context).size.width * 0.9,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _questions[_currentQuestionIndex]['question'],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ..._questions[_currentQuestionIndex]['options'].map((option) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _answerQuestion(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _answerColors[option] ?? Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(option, style: TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: 30),
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Progress", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("${_currentQuestionIndex + 1}/${_questions.length} Cards Complete"),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      "${((_score / _questions.length) * 100).toStringAsFixed(0)}%", 
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
