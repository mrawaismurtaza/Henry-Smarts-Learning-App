import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatRoom extends StatefulWidget {
  @override
  _AIChatRoomState createState() => _AIChatRoomState();
}

class _AIChatRoomState extends State<AIChatRoom> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // dotenv.load(); // Load environment variables
    setState(() {});
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'message': message});
      _isLoading = true;
    });

    _controller.clear();

    // Load Together AI API Key securely from .env
    final String apiKey = dotenv.env['TOGETHER_AI_KEY'] ?? '';

    if (apiKey.isEmpty) {
      setState(() {
        _messages.add({'sender': 'bot', 'message': 'Error: Missing API Key!'});
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.together.xyz/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "meta-llama/Meta-Llama-3-70B-Instruct-Turbo",
          "messages": [
            {"role": "system", "content": "You are a helpful AI assistant."},
            {"role": "user", "content": message}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chatResponse = data['choices'][0]['message']['content'];

        setState(() {
          _messages.add({'sender': 'bot', 'message': chatResponse});
        });
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        setState(() {
          _messages.add({'sender': 'bot', 'message': 'Error: API request failed!'});
        });
      }
    } catch (e) {
      print('Exception: $e');
      setState(() {
        _messages.add({'sender': 'bot', 'message': 'Error: Unable to fetch response. Try again later.'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Chat Room (Together AI)")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg['sender'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg['sender'] == 'user' ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(msg['message']!, style: TextStyle(fontSize: 16)),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
