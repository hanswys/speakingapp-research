

import 'dart:io';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Voice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final Map<String, HighlightedWord> _highlights = {
    'flutter': HighlightedWord(
      onTap: () => print('flutter'),
      textStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    ),
    'voice': HighlightedWord(
      onTap: () => print('voice'),
      textStyle: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
    'subscribe': HighlightedWord(
      onTap: () => print('subscribe'),
      textStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
    ),
    'like': HighlightedWord(
      onTap: () => print('like'),
      textStyle: const TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
      ),
    ),
    'comment': HighlightedWord(
      onTap: () => print('comment'),
      textStyle: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
  };

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;
  String _response = ""; // AI response
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI Chatbot"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Theme.of(context).primaryColor,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
          onPressed: _listen,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: Column(
            children: [
              TextHighlight(
                text: _text,
                words: _highlights,
                textStyle: const TextStyle(
                  fontSize: 32.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator() // Show loading indicator
                  : Text(
                      _response.isNotEmpty ? _response : "Waiting for response...",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      fetchData();
    }
  }

Future<void> fetchData() async {
  const url = "http://csai01:8000/generate/";

  final payload = {
    "prompt": _text,
    "max_tokens": 200,
  };

  setState(() {
    _isLoading = true;
    _response = "";
  });

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(payload),
    );

    print("Status Code: ${response.statusCode}");
    print("Raw Response Body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        final responseData = json.decode(response.body);
        print("Decoded Response: $responseData");

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('response')) {
            final responseText = responseData['response'];

            if (responseText is Map<String, dynamic> && responseText.containsKey('content')) {
              setState(() {
                _response = responseText['content']; // Extract only the "content" field
                _isLoading = false;
              });
            } else {
              setState(() {
                _response = "Unexpected response format: ${json.encode(responseText)}";
                _isLoading = false;
              });
            }
          } else {
            setState(() {
              _response = "Missing 'response' key in API response.";
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _response = "Unexpected response format: ${json.encode(responseData)}";
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _response = "JSON Decoding Error: $e\nRaw: ${response.body}";
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _response = "Request failed with status: ${response.statusCode}\nBody: ${response.body}";
        _isLoading = false;
      });
    }
  } catch (error) {
    setState(() {
      _response = "Network Error: $error";
      _isLoading = false;
    });
  }
}

}









//   Future<void> fetchData() async {
//     final prompt = """
// You are a compassionate and empathetic AI chatbot designed to support veterans suffering from depression. Your primary goal is to provide a safe, non-judgmental space for veterans to express their feelings and thoughts. Carefully analyze the veteran's choice of words, tone, and emotional state in their messages, and respond in a way that is supportive, understanding, and encouraging.

// **Guidelines for Responses:**
// 1. **Empathy and Validation**: Acknowledge the veteran's feelings and experiences. Use phrases like "That sounds really tough" or "I can understand why you feel that way."
// 2. **Avoid Judgment**: Never dismiss or invalidate their emotions. Avoid phrases like "You shouldn't feel that way" or "Just cheer up."
// 3. **Encourage Expression**: Gently encourage them to share more if they seem open to it. For example, "Would you like to talk more about what's been on your mind?"
// 4. **Offer Support**: Provide reassurance and remind them that they are not alone. For example, "It's okay to feel this way, and I'm here to listen."
// 5. **Avoid Giving Direct Advice**: Unless explicitly asked, avoid giving direct advice. Instead, guide them toward self-reflection. For example, "What do you think might help you feel better?"
// 6. **Monitor for Crisis**: If the veteran expresses thoughts of self-harm or suicide, respond with immediate concern and provide resources. For example, "I'm really concerned about what you're saying. Please reach out to a crisis hotline or a trusted person right away. You are not alone."

// **Veteran's Message:**
// $_text

// **AI Response:**
// """;
//   const url = "http://csai01:8000/generate/";
//   final payload = {
//     "prompt": prompt,
//     "max_tokens": 200,
//   };

//   try {
//     var response = await http.post(
//       Uri.parse(url),
//       headers: {"Content-Type": "application/json"},
//       body: json.encode(payload),
//     );

//     if (response.statusCode == 200) {
//       final responseData = json.decode(response.body);
//       print("Generated Response: ${responseData['response']}");
//       response = responseData['response'];

//     } else {
//       print("Request failed with status code: ${response.statusCode}");
//       print("Error details: ${response.body}");
//     }
//   } catch (error) {
//     print("Error: $error");
//   }
// }