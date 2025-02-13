// import 'dart:convert';
// import 'package:avatar_glow/avatar_glow.dart';
// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:http/http.dart' as http;

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'AI Chat',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: ChatScreen(),
//     );
//   }
// }

// class ChatScreen extends StatefulWidget {
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   late stt.SpeechToText _speech;
//   bool _isListening = false;
//   List<Map<String, String>> messages = [];
//   bool _isLoading = false;
//   String _partialText = ""; // To store partial speech recognition results

//   @override
//   void initState() {
//     super.initState();
//     _speech = stt.SpeechToText();
//   }

//   void _listen() async {
//     if (!_isListening) {
//       bool available = await _speech.initialize(
//         onStatus: (val) => print('onStatus: $val'),
//         onError: (val) => print('onError: $val'),
//       );
//       if (available) {
//         setState(() => _isListening = true);
//         _speech.listen(
//           onResult: (val) {
//             if (val.finalResult) {
//               // Only process final recognized speech
//               setState(() {
//                 String recognizedText = val.recognizedWords;
//                 messages.add({"role": "user", "message": recognizedText});
//                 _fetchResponse(recognizedText);
//                 _partialText = ""; // Clear partial text
//               });
//             } else {
//               // Store partial text but don't create a text bubble
//               setState(() {
//                 _partialText = val.recognizedWords;
//               });
//             }
//           },
//         );
//       }
//     } else {
//       setState(() => _isListening = false);
//       _speech.stop();
//     }
//   }

//   Future<void> _fetchResponse(String prompt) async {
//     const url = "http://csai01:8000/generate/";
//     final payload = {"prompt": prompt, "max_tokens": 200};

//     setState(() => _isLoading = true);

//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {"Content-Type": "application/json"},
//         body: json.encode(payload),
//       );

//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         setState(() {
//           messages.add({"role": "ai", "message": responseData['response']['content']});
//         });
//       } else {
//         setState(() {
//           messages.add({"role": "ai", "message": "Error: ${response.statusCode}"});
//         });
//       }
//     } catch (error) {
//       setState(() {
//         messages.add({"role": "ai", "message": "Network Error: $error"});
//       });
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("AI Chat")),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               reverse: true, // Display latest messages at the bottom
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 final message = messages[messages.length - 1 - index];
//                 final isUser = message["role"] == "user";
//                 return Align(
//                   alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: isUser ? Colors.blue : Colors.grey.shade300,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       message["message"]!,
//                       style: TextStyle(color: isUser ? Colors.white : Colors.black),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           if (_isLoading) CircularProgressIndicator(),
//           if (_partialText.isNotEmpty)
//             Padding(
//               padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//               child: Text(
//                 "Listening: $_partialText",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ),
//           AvatarGlow(
//             animate: _isListening,
//             glowColor: Colors.blue,
//             duration: Duration(milliseconds: 2000),
//             repeat: true,
//             child: FloatingActionButton(
//               onPressed: _listen,
//               child: Icon(_isListening ? Icons.mic : Icons.mic_none),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  List<Map<String, String>> messages = [];
  bool _isLoading = false;
  String _partialText = ""; // To store partial speech recognition results
  bool _isButtonDisabled = false; // To debounce the microphone button
  bool _isProcessing = false; // To show loading state on the microphone button
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeech(); // Initialize speech recognition on app start
     _initializeTts();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (!available) {
      // Handle case where speech recognition is not available
      print("Speech recognition not available");
    }
  }

   Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US"); // Set language
    await _flutterTts.setSpeechRate(0.5); // Adjust speech rate (0.0 to 1.0)
    await _flutterTts.setVolume(1.0); // Adjust volume (0.0 to 1.0)
    await _flutterTts.setPitch(1.0); // Adjust pitch (0.5 to 2.0)
  }

  void _listen() async {
          _stopSpeaking();
    if (_isButtonDisabled || _isProcessing) return; // Prevent multiple clicks
    _isButtonDisabled = true;
    _isProcessing = true;

    setState(() {
      _isListening = !_isListening;
      if (!_isListening) {
        _speech.stop();
      }
    });

    if (_isListening) {
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            setState(() {
              String recognizedText = val.recognizedWords;
              messages.add({"role": "user", "message": recognizedText});
              _fetchResponse(recognizedText);
              _partialText = ""; // Clear partial text
            });
          } else {
            setState(() {
              _partialText = val.recognizedWords; // Update partial text
            });
          }
        },
      );
    }

    // Re-enable the button after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      _isButtonDisabled = false;
      _isProcessing = false;
      setState(() {}); // Update UI to remove loading state
    });
  }

  Future<void> _fetchResponse(String prompt) async {
    const url = "http://csai01:8000/generate/";
    final payload = {"prompt": prompt, "max_tokens": 200};

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
          String aiResponse = responseData['response']['content'];
        setState(() {
          messages.add({"role": "ai", "message": responseData['response']['content']});
        });
          _speak(aiResponse);
      } else {
        setState(() {
          messages.add({"role": "ai", "message": "Error: ${response.statusCode}"});
        });
      }
    } catch (error) {
      setState(() {
        messages.add({"role": "ai", "message": "Network Error: $error"});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

   Future<void> _speak(String text) async {
    await _flutterTts.speak(text); // Convert text to speech
  }

  Future<void> _stopSpeaking() async {
  await _flutterTts.stop();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Display latest messages at the bottom
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                final isUser = message["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message["message"]!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) CircularProgressIndicator(),
          if (_partialText.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                "Listening: $_partialText",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          AvatarGlow(
            animate: _isListening,
            glowColor: Colors.blue,
            duration: Duration(milliseconds: 2000),
            repeat: true,
            child: FloatingActionButton(
              onPressed: _listen,
              child: _isProcessing
                  ? CircularProgressIndicator(color: Colors.white)
                  : Icon(_isListening ? Icons.mic : Icons.mic_none),
            ),
          ),
        ],
      ),
    );
  }
}