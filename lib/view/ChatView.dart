import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speakingapp/controller/ChatController.dart';
import 'package:provider/provider.dart';


class ChatView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
      print("I am i view mode");
    return ChangeNotifierProvider(
      // ignore: avoid_print
      create: (_) => ChatController(),
      child: Consumer<ChatController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(title: Text("AI Chat")),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[controller.messages.length - 1 - index];
                      final isUser = message.role == "user";
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
                            message.message,
                            style: TextStyle(color: isUser ? Colors.white : Colors.black),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (controller.isLoading) CircularProgressIndicator(),
                if (controller.partialText.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text(
                      "Listening: ${controller.partialText}",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                AvatarGlow(
                  animate: controller.isListening,
                  glowColor: Colors.blue,
                  duration: Duration(milliseconds: 2000),
                  repeat: true,
                  child: FloatingActionButton(
                    onPressed: controller.listen,
                    child: controller.isProcessing
                        ? CircularProgressIndicator(color: Colors.white)
                        : Icon(controller.isListening ? Icons.mic : Icons.mic_none),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}