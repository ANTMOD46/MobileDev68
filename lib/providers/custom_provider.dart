import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CustomLlmProvider {
  final String name;

  CustomLlmProvider({required this.name});

  Future<String> sendMessage(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? ''; // อ่าน API Key จาก .env
    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": prompt}
        ],
        "max_tokens": 150,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["choices"][0]["message"]["content"];
    } else {
      throw Exception("Failed to load data from API");
    }
  }
}
