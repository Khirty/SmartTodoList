import 'package:google_generative_ai/google_generative_ai.dart';



class AIChatService {

final model = GenerativeModel(

  model: 'gemini-2.5-flash', // Change it here

  apiKey: 'AIzaSyC4Xp_h3Oq1RnqR14nEDCGJ1pxfZKzhJY4',

); 



  Future<String> sendMessage(String userMessage, List<Map<String, dynamic>> tasks) async {

    try {

      String context = tasks.isEmpty 

          ? "No tasks" 

          : "${tasks.length} tasks (${tasks.where((t) => !t['done']).length} pending)";

      

      final fullPrompt = 'You are a helpful productivity assistant. User has $context. Question: $userMessage. Answer in under 100 words with emojis.';

      

      final content = [Content.text(fullPrompt)];

      final response = await model.generateContent(content);

      

      final text = response.text;

      

      if (text == null || text.isEmpty) {

        return "🤖 I received an empty response. Please try again.";

      }

      

      return text;

    } catch (e) {

      return 'Error: $e';

    }

  }



  static const quickActions = [

    {'icon': '🎯', 'text': 'Prioritize', 'prompt': 'What should I focus on?'},

    {'icon': '💪', 'text': 'Motivate me', 'prompt': 'Give me motivation!'},

    {'icon': '📋', 'text': 'Break down', 'prompt': 'Help break down my task'},

    {'icon': '📊', 'text': 'Progress', 'prompt': 'How am I doing?'},

  ];

}