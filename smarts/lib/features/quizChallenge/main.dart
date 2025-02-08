// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class QuizChallenge extends StatefulWidget {
  const QuizChallenge({super.key});

  @override
  State<QuizChallenge> createState() => _QuizChallengeState();
}

class _QuizChallengeState extends State<QuizChallenge> {
  final List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  int _timeLeft = 30; // 30 seconds per question
  late Timer _timer;
  Map<String, bool> _answeredQuestions = {};
  bool _quizCompleted = false;

  // Performance tracking
  int _totalAttempts = 0;
  double _averageScore = 0;
  String _bestCategory = '';
  
  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadPerformance();
  }

  Future<void> _loadQuestions() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance.collection('quiz_questions').get();
      setState(() {
        _questions.addAll(querySnapshot.docs.map((doc) => {
          'id': doc.id,
          'question': doc['question'],
          'options': List<String>.from(doc['options']),
          'correctAnswer': doc['correctAnswer'],
          'category': doc['category'],
          'explanation': doc['explanation'],
          'points': doc['points'] ?? 10,
        }));
        _questions.shuffle(); // Randomize question order
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      print("Error loading questions: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPerformance() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var doc = await FirebaseFirestore.instance
            .collection('quiz_performance')
            .doc(user.uid)
            .get();
            
        if (doc.exists) {
          setState(() {
            _totalAttempts = doc['totalAttempts'] ?? 0;
            _averageScore = doc['averageScore']?.toDouble() ?? 0.0;
            _bestCategory = doc['bestCategory'] ?? '';
          });
        }
      } catch (e) {
        print("Error loading performance: $e");
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _timer.cancel();
    if (!_answeredQuestions.containsKey(_questions[_currentQuestionIndex]['id'])) {
      setState(() {
        _answeredQuestions[_questions[_currentQuestionIndex]['id']] = false;
      });
      _showAnswerFeedback(false);
    }
  }

void _handleAnswer(String selectedAnswer) {
    if (_answeredQuestions.containsKey(_questions[_currentQuestionIndex]['id'])) {
      return; // Prevent multiple answers
    }

    _timer.cancel();
    bool isCorrect = selectedAnswer == _questions[_currentQuestionIndex]['correctAnswer'];
    
    setState(() {
      _answeredQuestions[_questions[_currentQuestionIndex]['id']] = isCorrect;
      if (isCorrect) {
        // Calculate points based on time left
        int timeBonus = (_timeLeft ~/ 5); // Integer division
        int questionPoints = (_questions[_currentQuestionIndex]['points'] as num).toInt(); // Cast to int
        _score += questionPoints + timeBonus;
      }
    });

    _showAnswerFeedback(isCorrect);
}


  void _showAnswerFeedback(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? 'Correct! 🎉' : 'Incorrect ❌'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_questions[_currentQuestionIndex]['explanation']),
            SizedBox(height: 10),
            if (isCorrect) Text(
              'Time Bonus: +${(_timeLeft / 5).round()} points',
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(_currentQuestionIndex + 1 < _questions.length ? 'Next Question' : 'Finish Quiz'),
            onPressed: () {
              Navigator.pop(context);
              _moveToNextQuestion();
            },
          ),
        ],
      ),
    );
  }

  void _moveToNextQuestion() {
    if (_currentQuestionIndex + 1 < _questions.length) {
      setState(() {
        _currentQuestionIndex++;
        _timeLeft = 30;
      });
      _startTimer();
    } else {
      _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    setState(() => _quizCompleted = true);
    await _savePerformance();
    _showQuizSummary();
  }

  Future<void> _savePerformance() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Calculate category performance
        Map<String, int> categoryScores = {};
        _questions.forEach((q) {
          if (_answeredQuestions[q['id']] == true) {
            categoryScores[q['category']] = (categoryScores[q['category']] ?? 0) + 1;
          }
        });
        
        String bestCategory = categoryScores.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        double percentage = (_score / (_questions.length * 10)) * 100;
        double newAverage = ((_averageScore * _totalAttempts) + percentage) / (_totalAttempts + 1);

        await FirebaseFirestore.instance
            .collection('quiz_performance')
            .doc(user.uid)
            .set({
          'totalAttempts': _totalAttempts + 1,
          'averageScore': newAverage,
          'bestCategory': bestCategory,
          'lastScore': _score,
          'lastAttemptDate': DateTime.now(),
        });
      } catch (e) {
        print("Error saving performance: $e");
      }
    }
  }

  void _showQuizSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Quiz Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: $_score'),
            Text('Correct Answers: ${_answeredQuestions.values.where((v) => v).length}/${_questions.length}'),
            SizedBox(height: 10),
            Text('Average Score: ${_averageScore.toStringAsFixed(1)}%'),
            Text('Total Attempts: ${_totalAttempts + 1}'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Return Home'),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/02.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildQuestionCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: _timeLeft < 10 ? Colors.red : Colors.blue),
                SizedBox(width: 8),
                Text(
                  '$_timeLeft s',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _timeLeft < 10 ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Score: $_score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      margin: EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 80),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1}/${_questions.length}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            Text(
              _questions[_currentQuestionIndex]['question'],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: _questions[_currentQuestionIndex]['options'].length,
                itemBuilder: (context, index) {
                  String option = _questions[_currentQuestionIndex]['options'][index];
                  bool isAnswered = _answeredQuestions.containsKey(_questions[_currentQuestionIndex]['id']);
                  bool isCorrect = option == _questions[_currentQuestionIndex]['correctAnswer'];
                  
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      onPressed: isAnswered ? null : () => _handleAnswer(option),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        backgroundColor: isAnswered
                            ? (isCorrect ? Colors.green : Colors.red.withOpacity(0.3))
                            : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          color: isAnswered && !isCorrect ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}