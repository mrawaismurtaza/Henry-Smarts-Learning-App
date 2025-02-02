import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Error: ${e.message}");
      return null;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error: $e");
    }
  }

  // Fetch Flashcards from Firestore
  Future<List<Map<String, dynamic>>> getFlashcards() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance.collection('flashcards').get();
      return querySnapshot.docs.map((doc) {
        return {
          'question': doc['question'],
          'options': List<String>.from(doc['options']),
          'answer': doc['answer']
        };
      }).toList();
    } catch (e) {
      print("Error fetching flashcards: $e");
      return [];
    }
  }
}
