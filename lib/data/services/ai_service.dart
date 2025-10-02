import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _model = 'deepseek/deepseek-r1';

  AIService();

  Future<String> getGeneralResponse(String userMessage) async {
    try {
      final response = await _makeApiRequest([
        {
          'role': 'system',
          'content': 'You are a specialized Heart Disease Management Assistant. You ONLY provide guidance related to cardiovascular health and heart disease management. Your expertise includes: heart-healthy diet plans (DASH, Mediterranean), safe exercise routines for heart patients, heart medication information and adherence, blood pressure and cholesterol management, stress management for heart health, warning signs requiring immediate medical attention, lifestyle modifications for heart disease patients, and cardiovascular risk reduction strategies. You do NOT provide general health advice, technology help, cooking recipes, travel advice, or entertainment suggestions. Stay strictly focused on heart disease management and always recommend consulting cardiologists for medical decisions.'
        },
        {
          'role': 'user',
          'content': userMessage
        }
      ]);
      
      return response;
    } catch (e) {
      print('AI Service Error: $e');
      throw Exception('Failed to get AI response: $e');
    }
  }

  Future<String> getHealthAdvice(String healthQuery) async {
    try {
      final response = await _makeApiRequest([
        {
          'role': 'system',
          'content': 'You are a specialized cardiovascular health assistant for heart disease patients. Provide evidence-based advice focused on: heart-healthy lifestyle modifications, cardiovascular risk reduction, medication adherence, dietary recommendations for heart health, safe exercise guidelines, stress management techniques, blood pressure and cholesterol management, and warning signs that require immediate medical attention. Always emphasize consulting with cardiologists and healthcare providers for medical decisions. Focus on practical, actionable advice for daily heart health management.'
        },
        {
          'role': 'user',
          'content': healthQuery
        }
      ]);
      
      return response;
    } catch (e) {
      print('AI Health Service Error: $e');
      throw Exception('Failed to get health advice: $e');
    }
  }

  Future<String> getMedicationReminder(String medicationInfo) async {
    try {
      final response = await _makeApiRequest([
        {
          'role': 'system',
          'content': 'You are a specialized cardiovascular medication assistant for heart disease patients. Provide helpful information about heart medications including: - Purpose and benefits for cardiovascular health - Common side effects to monitor - Proper storage and administration guidelines - Drug interactions with other heart medications - Importance of medication adherence for heart health - When to contact healthcare providers about side effects - Reminder that this is general information and not medical advice - Always emphasize following cardiologist\'s specific instructions'
        },
        {
          'role': 'user',
          'content': medicationInfo
        }
      ]);
      
      return response;
    } catch (e) {
      print('AI Medication Service Error: $e');
      throw Exception('Failed to get medication information: $e');
    }
  }

  Future<String> getHeartDiseaseAdvice(String query) async {
    try {
      final response = await _makeApiRequest([
        {
          'role': 'system',
          'content': 'You are a specialized heart disease lifestyle coach. Provide comprehensive guidance on: heart-healthy diet plans (DASH diet, Mediterranean diet), safe exercise routines for heart patients, stress management techniques, blood pressure monitoring, cholesterol management, weight management strategies, smoking cessation support, sleep optimization for heart health, warning signs requiring immediate medical attention, and daily lifestyle modifications to improve cardiovascular health. Always provide practical, actionable advice while emphasizing the importance of regular medical checkups and following healthcare provider recommendations.'
        },
        {
          'role': 'user',
          'content': query
        }
      ]);
      
      return response;
    } catch (e) {
      print('AI Heart Disease Service Error: $e');
      throw Exception('Failed to get heart disease advice: $e');
    }
  }

  Future<String> _makeApiRequest(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://cardio-tech-app.com',
          'X-Title': 'CardioTech AI Assistant',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 1000,
          'temperature': 0.7,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'I apologize, but I was unable to generate a response. Please try again.';
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('HTTP Request Error: $e');
      throw Exception('Failed to make API request: $e');
    }
  }
}