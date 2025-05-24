import 'dart:math';

class UserIdGenerator {
  static const String _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static final Random _random = Random();

  static String generate() {
    final buffer = StringBuffer();
    
    // 3文字のランダムなローマ字を生成
    for (int i = 0; i < 3; i++) {
      buffer.write(_letters[_random.nextInt(_letters.length)]);
    }
    
    // 3桁のランダムな数字を生成
    for (int i = 0; i < 3; i++) {
      buffer.write(_numbers[_random.nextInt(_numbers.length)]);
    }
    
    return buffer.toString();
  }
} 