import 'package:flutter/material.dart';
import 'package:smarts/features/auth/login.dart';
import 'package:smarts/features/auth/signup';
import 'package:smarts/features/flashcard/main.dart';
import 'package:smarts/features/home/main.dart';
import 'package:smarts/features/memorygame/main.dart';

// Import your game pages here
final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => HomePage(),
  '/signup': (context) => SignupPage(),
  '/login': (context) => LoginPage(),
  '/flashcards': (context) => FlashCard(),
  '/memory-game': (context) => MemoryGame(),
  // '/quiz-challenge': (context) => QuizChallengePage(),
  // '/daily-challenges': (context) => DailyChallengesPage(),
  // '/ai-chat-room': (context) => AIChatRoomPage(),
};
