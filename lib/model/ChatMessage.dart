import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role;
  final String message;

  ChatMessage({required this.role, required this.message});

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'message': message,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      message: json['message'],
    );
  }
}

class ChatService {
  final String _baseUrl = "http://csai01:8000/generate/";

  Future<ChatMessage> fetchAIResponse(String prompt) async {
    try {
      final payload = {
        "prompt": prompt, 
        "max_tokens": 200
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ChatMessage(
          role: 'ai', 
          message: responseData['response']['content']
        );
      } else {
        return ChatMessage(
          role: 'ai', 
          message: "Error: ${response.statusCode}"
        );
      }
    } catch (error) {
      return ChatMessage(
        role: 'ai', 
        message: "Network Error: $error"
      );
    }
  }
}