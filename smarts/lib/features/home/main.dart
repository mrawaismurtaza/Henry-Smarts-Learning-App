import 'package:flutter/material.dart';
import 'package:smarts/firebase/FirebaseService.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/02.png', fit: BoxFit.cover),
          Positioned(
            top: 50, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 50), // For balance
                Image.asset('assets/images/Logo.png', height: 100),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16.0),
                width: width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    Text('Language Games', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('Choose your learning adventure', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 20),
                    _buildGameOption('Flashcards', Icons.photo_library, '/flashcards'),
                    SizedBox(height: 10),
                    _buildGameOption('Memory Game', Icons.memory, '/memory-game'),
                    SizedBox(height: 10),
                    _buildGameOption('Quiz Challenge', Icons.quiz, '/quiz-challenge'),
                    SizedBox(height: 10),
                    _buildGameOption('Daily Challenges', Icons.calendar_today, '/daily-challenges'),
                    SizedBox(height: 10),
                    _buildGameOption('AI Chat Room', Icons.chat, '/ai-chat-room'),
                    SizedBox(height: 20),
                    SizedBox(
                      width: width,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading 
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Start Learning', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOption(String title, IconData icon, String routeName) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                SizedBox(width: 10),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}