import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mcp_llm/mcp_llm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late McpLlm _mcpLlm;
  LlmClient? _client;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeLlm();
  }

  Future<void> _initializeLlm() async {
    _mcpLlm = McpLlm();
    _mcpLlm.registerProvider('claude', ClaudeProviderFactory());

    final apiKey = dotenv.env['CLAUDE_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      _showError('API key not found. Please check your .env file.');
      return;
    }

    try {
      _client = await _mcpLlm.createClient(
        providerName: 'claude',
        config: LlmConfiguration(
          apiKey: apiKey,
          model: 'claude-3-haiku-20240307',
          options: {
            'temperature': 0.7,
            'max_tokens': 1500,
          },
        ),
        systemPrompt: 'You are a helpful assistant. Be concise and friendly.',
      );
    } catch (e) {
      _showError('Failed to initialize AI: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isTyping = true;
    });

    if (_client == null) {
      _showError('AI client not initialized');
      setState(() {
        _isTyping = false;
      });
      return;
    }

    try {
      final response = await _client!.chat(text);

      setState(() {
        _messages.add(ChatMessage(
          text: response.text,
          isUser: false,
        ));
        _isTyping = false;
      });
    } catch (e) {
      _showError('Error getting AI response: $e');
      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat App'),
      ),
      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, index) => _messages[_messages.length - 1 - index],
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 8),
                  Text('AI is typing...'),
                ],
              ),
            ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.primary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Send a message',
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mcpLlm.shutdown();
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              child: Text(isUser ? 'You' : 'AI'),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : 'AI Assistant',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}