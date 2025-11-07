import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  // Automatically load the API key from your .env file
  final String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  /// Sends a user prompt to Groq's Llama 3.3 model and returns the AI response.
  Future<String> getResponse(String userPrompt) async {
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    if (apiKey.isEmpty) {
      return "⚠️ Error: Missing Groq API key. Please add it to your .env file.";
    }

    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile", // latest Groq model
          "messages": [
            {"role": "user", "content": userPrompt},
          ],
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final output = data["choices"]?[0]?["message"]?["content"];
        return output?.trim() ?? "No response from AI.";
      } else {
        return "Groq error: ${res.statusCode} → ${res.body}";
      }
    } catch (e) {
      return "Error connecting to Groq API: $e";
    }
  }
}
