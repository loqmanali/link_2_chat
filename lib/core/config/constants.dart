class AppConstants {
  // App Info
  static const String appName = 'Link2Chat';
  static const String appTagline =
      'Convert phone numbers to chat links instantly';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String phoneEntriesBox = 'phone_entries';
  static const String userStatsBox = 'user_stats';

  // SharedPreferences Keys
  static const String totalLinksKey = 'total_links';
  static const String firstLaunchKey = 'first_launch';
  static const String themeKey = 'app_theme';

  // Supabase Configuration
  // Replace with your actual Supabase URL and anon key
  static const String supabaseUrl = 'https://ygvatwywiwcgpvevwgic.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlndmF0d3l3aXdjZ3B2ZXZ3Z2ljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MjU3NjAsImV4cCI6MjA2MzAwMTc2MH0.uQ55UegemcttNBtLleyXQywYKmqCu1-66cJkF8xMED8';

  // Default Values
  static const int maxRecentEntries = 10;
  static const int maxTopCountries = 5;

  // Platform Texts
  static const Map<String, String> platforms = {
    'whatsapp': 'WhatsApp',
    'telegram': 'Telegram',
  };

  // Messages
  static const String invalidNumberMessage =
      'Please enter a valid phone number';
  static const String copySuccessMessage = 'Link copied to clipboard';
  static const String shareSuccessMessage = 'Link shared successfully';
  static const String qrExportSuccessMessage = 'QR code saved to gallery';

  // URLs
  static const String privacyPolicyUrl =
      'https://link2chat.example.com/privacy';
  static const String termsUrl = 'https://link2chat.example.com/terms';
  static const String helpUrl = 'https://link2chat.example.com/help';

  // PWA
  static const String pwaDescription =
      'Convert phone numbers to WhatsApp and Telegram links with one click';
  static const String pwaShortName = 'Link2Chat';
  static const String pwaThemeColor = '#4CAF50';
  static const String pwaBackgroundColor = '#FFFFFF';
}
