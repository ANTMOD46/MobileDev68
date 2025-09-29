import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Princess AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF69B4),
          primary: const Color(0xFFFF69B4),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF0F5),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  String _selectedProvider = "openai";
  String _selectedModel = "gpt-4o-mini";

  final Map<String, List<String>> providerModels = {
    "openai": ["gpt-4o-mini", "gpt-4", "gpt-3.5-turbo"],
    "anthropic": ["claude-3-haiku-20240307", "claude-3-opus-20240229"]
  };

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });

    try {
      final reply = await sendMessage(text);
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error: $e", isUser: false));
        _isTyping = false;
      });
    }
  }

  Future<String> sendMessage(String prompt) async {
    if (_selectedProvider == "openai") {
      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": _selectedModel,
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 500,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data["choices"] != null && data["choices"].isNotEmpty) {
        return data["choices"][0]["message"]["content"];
      } else if (data["error"] != null) {
        return "API Error: ${data["error"]["message"]}";
      }
      return "No response";
    }

    if (_selectedProvider == "anthropic") {
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
      final response = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {
          "x-api-key": apiKey,
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01"
        },
        body: jsonEncode({
          "model": _selectedModel,
          "max_tokens": 500,
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": prompt}
              ]
            }
          ]
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data["content"] != null && data["content"].isNotEmpty) {
        return data["content"][0]["text"];
      } else if (data["error"] != null) {
        return "API Error: ${data["error"]["message"]}";
      }
      return "No response";
    }

    return "Invalid provider";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF0F5),
              const Color(0xFFFFE4E9),
              const Color(0xFFFFD6E0),
            ],
          ),
        ),
        child: Row(
          children: [
            // Sidebar เจ้าหญิง
            Container(
              width: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFB6C1),
                    const Color(0xFFFF69B4),
                    const Color(0xFFFF1493),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.shade200.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(5, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Header สวยๆ
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Princess AI",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "✨ Model Selector ✨",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Provider dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Provider",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: DropdownButton<String>(
                            value: _selectedProvider,
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Color(0xFFFF69B4)),
                            style: const TextStyle(
                              color: Color(0xFFFF1493),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            items: providerModels.keys
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedProvider = v!;
                                _selectedModel = providerModels[v]!.first;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Model dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Model",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: DropdownButton<String>(
                            value: _selectedModel,
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Color(0xFFFF69B4)),
                            style: const TextStyle(
                              color: Color(0xFFFF1493),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            items: providerModels[_selectedProvider]!
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedModel = v!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Footer decoration
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Made with 💖",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Chat Area
            Expanded(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.shade100.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF69B4),
                                    Color(0xFFFF1493)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.chat_bubble,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Princess Chat Room",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF1493),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.star,
                                color: Colors.pink.shade300, size: 20),
                            const SizedBox(width: 8),
                            Icon(Icons.auto_awesome,
                                color: Colors.pink.shade300, size: 20),
                            const SizedBox(width: 8),
                            Icon(Icons.star,
                                color: Colors.pink.shade300, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Messages area
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (_, idx) =>
                            _messages[_messages.length - 1 - idx],
                      ),
                    ),
                  ),

                  if (_isTyping)
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.pink.shade300),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Princess AI is typing...",
                            style: TextStyle(
                              color: Colors.pink.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Input box
                  _buildComposer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade100.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.pink.shade200,
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: "✨ Type your magical message...",
                  hintStyle: TextStyle(
                    color: Colors.pink.shade300,
                    fontStyle: FontStyle.italic,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.shade300.withOpacity(0.6),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _handleSubmitted(_controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.all(16),
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          )
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: alignment,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
                  )
                : null,
            color: isUser ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isUser
                    ? Colors.pink.shade300.withOpacity(0.4)
                    : Colors.grey.shade300.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 14),
                ),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF333333),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}