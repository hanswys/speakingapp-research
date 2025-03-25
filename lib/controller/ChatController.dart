import 'package:flutter/material.dart';
import 'package:speakingapp/model/ChatMessage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_error.dart';


class ChatController extends ChangeNotifier {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late PorcupineManager _porcupineManager;

  List<ChatMessage> messages = [];
  bool isListening = false;
  bool isLoading = false;
  String partialText = "";
  bool isButtonDisabled = false;
  bool isProcessing = false;

  final String accessKey = "3kqE8xgq0/l2/TTwavhy26Frh0ZzDTzkcs30VagEaaeHLtpY8naFKA==";
  final ChatService _chatService = ChatService();

  ChatController() {
    _initializeSpeech();
    _initializeTts();
    createPorcupineManager();
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (!available) {
      print("Speech recognition not available");
    }
    notifyListeners();
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void createPorcupineManager() async {
    try {
      _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
        accessKey,
        [BuiltInKeyword.PICOVOICE, BuiltInKeyword.PORCUPINE],
        _wakeWordCallback,
      );
      await _porcupineManager.start();
      print("PorcupineManager initialized");
    } on PorcupineException catch (err) {
      print("Porcupine initialization error: $err");
    }
  }

  void _wakeWordCallback(int keywordIndex) async {
    if (keywordIndex == 0) {
      print("pico word detected!");
      await _porcupineManager.stop();
      listen();
    } else if (keywordIndex == 1) {
      print("porcupine word detected!");
    }
  }

  void listen() async {
    stopSpeaking();
    if (isButtonDisabled || isProcessing) return;

    isButtonDisabled = true;
    isProcessing = true;
    isListening = !isListening;
    
    if (isListening) {
      _speech.listen(
        onResult: (val) async {
          if (val.finalResult) {
            String recognizedText = val.recognizedWords;
            messages.add(ChatMessage(role: "user", message: recognizedText));
            await fetchResponse(recognizedText);
            partialText = "";
            await _porcupineManager.start();
          } else {
            partialText = val.recognizedWords;
          }
          notifyListeners();
        },
      );
    } else {
      _speech.stop();
    }

    Future.delayed(Duration(milliseconds: 500), () {
      isButtonDisabled = false;
      isProcessing = false;
      notifyListeners();
    });
  }

  Future<void> fetchResponse(String prompt) async {
    isLoading = true;
    notifyListeners();

    try {
      ChatMessage aiResponse = await _chatService.fetchAIResponse(prompt);
      messages.add(aiResponse);
      await speak(aiResponse.message);
    } catch (error) {
      messages.add(ChatMessage(role: "ai", message: "Error: $error"));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _porcupineManager.delete();
    _speech.cancel();
    _flutterTts.stop();
  }
}