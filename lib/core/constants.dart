/// Uygulama genelinde kullanılacak sabit değerler
class AppConstants {
  // Renkler
  static const primaryColor = 0xFF4CAF50;
  static const secondaryColor = 0xFF2196F3;
  static const errorColor = 0xFFE53935;
  static const warningColor = 0xFFFFA000;
  static const successColor = 0xFF43A047;
  
  // Metin boyutları
  static const fontSizeSmall = 12.0;
  static const fontSizeNormal = 14.0;
  static const fontSizeMedium = 16.0;
  static const fontSizeLarge = 18.0;
  static const fontSizeXLarge = 22.0;
  
  // Mesafeler (padding, margin)
  static const spacingTiny = 4.0;
  static const spacingSmall = 8.0;
  static const spacingNormal = 16.0;
  static const spacingLarge = 24.0;
  static const spacingXLarge = 32.0;
  
  // Barkod
  static const barcodePrefix = "8690";
  
  // SKT Uyarı Süreleri
  static const sktCriticalDays = 7; // Kritik SKT günü
  static const sktWarningDays = 30; // Uyarı SKT günü
  
  // Sayfa başına maksimum öğe
  static const itemsPerPage = 20;
  
  // Api istekleri için timeout süresi (saniye)
  static const apiTimeout = 30;
  
  // Tarih formatları
  static const dateFormatDisplay = "dd/MM/yyyy";
  static const dateFormatStorage = "yyyy-MM-dd";
  
  // Uygulama versiyonu
  static const appVersion = "1.0.0";
}
