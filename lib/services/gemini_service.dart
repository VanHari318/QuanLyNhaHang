import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/dish_model.dart';
import '../utils/constants.dart';

class GeminiService {
  late final GenerativeModel _model;
  ChatSession? _chat;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: AppConstants.geminiApiKey,
      systemInstruction: Content.system('''
        Bạn là "Trợ lý ảo Vị Lai Quán" - một chuyên gia ẩm thực thân thiện, tinh tế và am hiểu sâu sắc về văn hóa nhà hàng. 
        Mục tiêu của bạn không chỉ là cung cấp thông tin, mà là tạo ra trải nghiệm trò chuyện ấm áp, chuyên nghiệp như một quản lý nhà hàng thực thụ đang đối thoại cùng khách quý.

        Tính cách & Ngôn ngữ:
        - THÂN THIỆN & LỄ PHÉP: Luôn bắt đầu bằng lời chào nồng nhiệt. Sử dụng các từ "Dạ", "Thưa", "Quý khách", "Mời quý khách" một cách tự nhiên.
        - TINH TẾ & SÁNG TẠO: Thay vì liệt kê khô khan, hãy mô tả món ăn một cách hấp dẫn (Ví dụ: thay vì "Có món lẩu", hãy nói "Nhà hàng em có món lẩu nấm thanh đạm, nước dùng được ninh từ rau củ tự nhiên rất ngọt và bổ dưỡng ạ").
        - KIÊN NHẪN & CHỦ ĐỘNG: Luôn sẵn sàng tư vấn và đưa ra các gợi ý phù hợp với tâm trạng hoặc sở thích của khách (Ví dụ: "Nếu quý khách muốn một món nhẹ nhàng cho buổi tối, em xin gợi ý...").

        Thông tin cốt lõi:
        - Tên: Vị Lai Quán (Ẩm thực chay & Món Việt cao cấp).
        - Địa chỉ: Trung tâm thành phố (xem bản đồ chi tiết tại tab Đặt hàng).
        - Giờ mở cửa: 09:00 - 22:00.
      '''),
    );
  }

  /// Khởi tạo hội thoại mới với ngữ cảnh thực đơn hiện tại
  void startNewChat(List<DishModel> dishes) {
    final menuContext = dishes.map((d) => 
      "- ${d.name}: ${_fmtPrice(d.price)}đ (Danh mục: ${d.category}, ${d.isAvailable ? 'Sẵn sàng' : 'Hết hàng'}, ${d.isBestSeller ? 'Bán chạy' : ''})"
    ).join('\n');

    _chat = _model.startChat(history: [
      Content.text("Dưới đây là thực đơn hiện tại của nhà hàng:\n$menuContext"),
      Content.model([TextPart("Dạ, tôi đã nắm rõ thực đơn của Vị Lai Quán. Tôi đã sẵn sàng hỗ trợ quý khách tư vấn món ăn!")])
    ]);
  }

  Future<String> generateResponse(String message, List<DishModel> dishes) async {
    try {
      if (_chat == null) startNewChat(dishes);
      
      final content = Content.text(message);
      final response = await _chat!.sendMessage(content);
      return response.text ?? 'Dạ, tôi chưa rõ ý của bạn. Bạn có thể hỏi lại được không ạ?';
    } catch (e) {
      print('Gemini Error: $e');
      return 'Dạ, hệ thống của tôi đang bận một chút. Quý khách vui lòng thử lại sau giây lát nhé!';
    }
  }

  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
