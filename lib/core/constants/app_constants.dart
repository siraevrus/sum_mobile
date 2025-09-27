class AppConstants {
  static const String appName = 'Sum Warehouse';
  static const String baseUrl = 'http://31.184.253.122/api';
  
  // Размеры
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultElevation = 2.0;
  
  // Анимации
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  // Пагинация
  static const int defaultPageSize = 15;
  
  // Ограничения
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = ['jpg', 'jpeg', 'png', 'pdf', 'docx'];
  
  // Роли пользователей
  static const String roleAdmin = 'admin';
  static const String roleOperator = 'operator';
  static const String roleWorker = 'warehouse_worker';
  static const String roleManager = 'manager';
}
