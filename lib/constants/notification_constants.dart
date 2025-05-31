class NotificationType {
  static const String stock = 'stock';
  static const String skt = 'skt';
  static const String count = 'count';
  static const String announcement = 'announcement';
  static const String order = 'order';
  static const String inventory = 'inventory';

  static const List<String> allTypes = [
    stock,
    skt,
    count,
    announcement,
    order,
    inventory,
  ];

  static String getTypeName(String type) {
    switch (type) {
      case stock:
        return 'Stok Bildirimi';
      case skt:
        return 'SKT Bildirimi';
      case count:
        return 'Sayım Bildirimi';
      case announcement:
        return 'Duyuru';
      case order:
        return 'Sipariş Bildirimi';
      case inventory:
        return 'Envanter Bildirimi';
      default:
        return 'Bildirim';
    }
  }
}

class NotificationTopic {
  static const String all = 'all';
  static const String managers = 'managers';
  static const String employees = 'employees';
  static const String inventory = 'inventory';
  static const String orders = 'orders';
  static const String announcements = 'announcements';

  static const List<String> allTopics = [
    all,
    managers,
    employees,
    inventory,
    orders,
    announcements,
  ];

  static String getTopicName(String topic) {
    switch (topic) {
      case managers:
        return 'Yöneticiler';
      case employees:
        return 'Çalışanlar';
      case inventory:
        return 'Envanter';
      case orders:
        return 'Siparişler';
      case announcements:
        return 'Duyurular';
      default:
        return 'Hepsi';
    }
  }
}
