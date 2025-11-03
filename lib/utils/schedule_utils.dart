// file: lib/utils/schedule_utils.dart

class ScheduleUtils {
  // 1. Định nghĩa tất cả các mốc thời gian cho các tiết học
  //    Dựa trên quy tắc: 50 phút học, 5 phút nghỉ, bắt đầu từ 7h00.
  //    (Giả sử nghỉ trưa và bắt đầu ca chiều lúc 13h00)
  static final Map<int, Map<String, String>> _lessonTimes = {
    // --- Ca Sáng ---
    1: {'start': '7h00', 'end': '7h50'},
    2: {'start': '7h55', 'end': '8h45'},
    3: {'start': '8h50', 'end': '9h40'},
    4: {'start': '9h45', 'end': '10h35'},
    5: {'start': '10h40', 'end': '11h30'},
    6: {'start': '11h35', 'end': '12h25'},
    // --- Ca Chiều ---
    7: {'start': '12h55', 'end': '13h45'},
    8: {'start': '13h50', 'end': '14h50'},
    9: {'start': '14h55', 'end': '15h45'},
    10: {'start': '15h50', 'end': '16h40'},
    11: {'start': '16h45', 'end': '17h35'},
    12: {'start': '17h35', 'end': '18h20'},
    // --- Ca Tối (Nếu có) ---
    // 11: {'start': '18h00', 'end': '18h50'},
    // 12: {'start': '18h55', 'end': '19h45'},
  };

  /// 2. Hàm tính toán thời gian bắt đầu và kết thúc
  ///    dựa trên danh sách các tiết được chọn.
  ///
  ///    Ví dụ: [1, 2, 3] => "7h00-9h40"
  ///    Ví dụ: [3, 5] => "8h50-11h30" (Xử lý cả trường hợp tiết không liên tục)
  static String getLessonTimeRange(List<int> selectedLessons) {
    if (selectedLessons.isEmpty) {
      return "N/A"; // Hoặc "" tùy bạn muốn
    }

    // Sắp xếp lại để chắc chắn lấy đúng tiết đầu và tiết cuối
    // Quan trọng nếu người dùng chọn [3, 1, 2]
    final sortedLessons = List<int>.from(selectedLessons)..sort();

    final int startLesson = sortedLessons.first;
    final int endLesson = sortedLessons.last;

    // Lấy thời gian BẮT ĐẦU của tiết ĐẦU TIÊN
    final String? startTime = _lessonTimes[startLesson]?['start'];

    // Lấy thời gian KẾT THÚC của tiết CUỐI CÙNG
    final String? endTime = _lessonTimes[endLesson]?['end'];

    if (startTime == null || endTime == null) {
      // Xử lý trường hợp chọn tiết không có trong map (ví dụ: tiết 13, 14...)
      return "Không hợp lệ";
    }

    // Trả về định dạng "7h00-9h40" (Bạn có thể .replaceAll('h00', 'h') nếu muốn)
    // Ví dụ: return '$startTime-$endTime'.replaceAll('h00', 'h');
    // để ra kết quả "7h-9h40"

    return '$startTime-$endTime';
  }
}