import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AIzaSyBprBojhJgPi885xaR-HD4TVERa0BgfUtA';
  print('Trying gemini-2.5-flash...');
  try {
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    final response = await model.generateContent([Content.text('Chào bạn, bạn là ai?')]);
    print('Response: ${response.text}');
  } catch (e) {
    print('Failed with gemini-2.5-flash: $e');
  }
}
