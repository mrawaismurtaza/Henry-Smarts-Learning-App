import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smarts/routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  await dotenv.load();  // Load environment variables

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDL8fVLqHgKB2kpdooJDJ7Ij03VL023OaI",
      appId: "1:986463954633:android:32304513ec161143ee4f18",
      messagingSenderId: "986463954633",
      projectId: "smarts-54b47"
    )
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/signup',
      routes: appRoutes,
    );
  }
}
