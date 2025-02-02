import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  late List<Map<String, dynamic>> cards;
  late bool isRevealing;
  List<int> selectedCards = [];
  int score = 0;
  int remainingTime = 15;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startRevealTimer();
    _startCountdownTimer();
  }

  void _initializeGame() {
    cards = List.generate(9, (index) => {'isApple': index < 3, 'isFlipped': false});
    cards.shuffle();
    isRevealing = true;
  }

  void _startRevealTimer() async {
    await Future.delayed(Duration(seconds: 1));
    if (mounted) {
      setState(() {
        isRevealing = false;
      });
    }
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime == 0) {
        _timer.cancel();
        _savePerformance();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          setState(() {
            remainingTime--;
          });
        }
      }
    });
  }

  void _handleCardTap(int index) {
    if (isRevealing || selectedCards.length >= 3 || cards[index]['isFlipped']) return;

    setState(() {
      cards[index]['isFlipped'] = true;
      selectedCards.add(index);
    });

    if (selectedCards.length == 3) {
      _checkResult();
    }
  }

  void _checkResult() {
    final isWin = selectedCards.every((index) => cards[index]['isApple']);
    if (isWin) score++;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isWin ? 'You guessed correctly! 🎉' : 'Try again! ❌')),
    );

    Future.delayed(Duration(seconds: 2), () {
      _savePerformance();
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _savePerformance() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentReference performanceRef = FirebaseFirestore.instance.collection('memory_game').doc(user.uid);
      DocumentSnapshot docSnapshot = await performanceRef.get();

      if (docSnapshot.exists) {
        await performanceRef.update({'score': FieldValue.increment(score)});
      } else {
        await performanceRef.set({'score': score});
      }
    } catch (e) {
      print("Error saving performance: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = constraints.maxHeight;
        bool isLargeScreen = screenWidth > 900;
        bool isTablet = screenWidth > 600 && screenWidth <= 900;

        double headingFontSize = isLargeScreen ? 32 : (isTablet ? 28 : 24);
        double subheadingFontSize = isLargeScreen ? 22 : (isTablet ? 18 : 16);
        double timerFontSize = isLargeScreen ? 28 : (isTablet ? 24 : 20);
        double emojiSize = isLargeScreen ? 60 : (isTablet ? 50 : 40);
        double gridPadding = isLargeScreen ? 40.0 : (isTablet ? 30.0 : 20.0);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/02.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(gridPadding),
                child: isLargeScreen ? _buildLargeScreenLayout(
                  headingFontSize,
                  subheadingFontSize,
                  timerFontSize,
                  emojiSize,
                  screenHeight,
                  screenWidth,
                ) : _buildSmallScreenLayout(
                  headingFontSize,
                  subheadingFontSize,
                  timerFontSize,
                  emojiSize,
                  screenHeight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLargeScreenLayout(
    double headingFontSize,
    double subheadingFontSize,
    double timerFontSize,
    double emojiSize,
    double screenHeight,
    double screenWidth,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: _buildGameInfo(
            headingFontSize,
            subheadingFontSize,
            timerFontSize,
          ),
        ),
        Expanded(
          flex: 3,
          child: Center(
            child: _buildGameGrid(
              min(screenHeight * 0.8, screenWidth * 0.4),
              emojiSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout(
    double headingFontSize,
    double subheadingFontSize,
    double timerFontSize,
    double emojiSize,
    double screenHeight,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGameInfo(
          headingFontSize,
          subheadingFontSize,
          timerFontSize,
        ),
        SizedBox(height: 20),
        Expanded(
          child: Center(
            child: _buildGameGrid(
              screenHeight * 0.5,
              emojiSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameInfo(
    double headingFontSize,
    double subheadingFontSize,
    double timerFontSize,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Memory Game",
          style: TextStyle(
            fontSize: headingFontSize,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 4, 41, 248),
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Choose or Select Apple",
          style: TextStyle(
            fontSize: subheadingFontSize,
            fontWeight: FontWeight.w500,
            color: Colors.green,
          ),
        ),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 5)
            ],
          ),
          child: Text(
            remainingTime.toString(),
            style: TextStyle(
              fontSize: timerFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameGrid(double size, double emojiSize) {
    return Container(
      width: size,
      height: size,
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          final isFlipped = card['isFlipped'] || isRevealing;

          return GestureDetector(
            onTap: () => _handleCardTap(index),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isFlipped ? Colors.white : Colors.blue,
              child: Center(
                child: isFlipped
                    ? Text(
                        card['isApple'] ? '🍏' : '❌',
                        style: TextStyle(fontSize: emojiSize),
                      )
                    : Container(),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}