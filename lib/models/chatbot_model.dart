// Model dữ liệu chatbot FAQ – Firestore collection: 'chatbot_data'
class ChatBotModel {
  final String id;
  final String question;
  final String answer;

  const ChatBotModel({
    required this.id,
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'question': question,
    'answer': answer,
  };

  factory ChatBotModel.fromMap(Map<String, dynamic> map) {
    return ChatBotModel(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
    );
  }
}
