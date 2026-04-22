import 'dart:math';

class UuidHelper {
  static final Random _random = Random();
  
  /// Génère un UUID v4 simple
  static String generate() {
    // Générer 16 octets aléatoires
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    
    // Version 4 bits
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    // Variant bits
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    
    // Convertir en hexadécimal avec tirets
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
