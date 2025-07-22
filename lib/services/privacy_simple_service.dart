import 'package:shared_preferences/shared_preferences.dart';

class PrivacySimpleService {
  static const String _privacyAcceptedKey = 'privacy_terms_accepted';
  static const String _acceptedDateKey = 'privacy_accepted_date';

  // Verificar si ya aceptó los términos
  static Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyAcceptedKey) ?? false;
  }

  // Guardar que aceptó los términos
  static Future<void> acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyAcceptedKey, true);
    await prefs.setString(_acceptedDateKey, DateTime.now().toIso8601String());
    
    print('✅ Usuario aceptó términos de privacidad');
  }

  // Obtener cuándo aceptó
  static Future<DateTime?> getAcceptedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_acceptedDateKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  // Borrar aceptación (para testing)
  static Future<void> resetAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_privacyAcceptedKey);
    await prefs.remove(_acceptedDateKey);
  }
}