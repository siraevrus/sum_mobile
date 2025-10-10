import 'package:math_expressions/math_expressions.dart';

void main() {
  // Тестовые формулы из шаблонов товаров с заменой переменных на значения
  final testCases = [
    {'formula': 's * quantity', 'values': {'s': 100.0, 'quantity': 5.0}},  // Ожидаемый результат: 500
    {'formula': 'a1 * a2', 'values': {'a1': 10.0, 'a2': 20.0}},         // Ожидаемый результат: 200
    {'formula': '(T/1000*S/1000*D/1000)*quantity', 'values': {'T': 50.0, 'S': 100.0, 'D': 200.0, 'quantity': 3.0}},  // Ожидаемый результат: 0.03
    {'formula': '(D/1000*S/1000*T/1000)*quantity', 'values': {'D': 100.0, 'S': 200.0, 'T': 50.0, 'quantity': 2.0}},  // Ожидаемый результат: 0.02
    {'formula': '(dk1*rk*dp)/20* quantity', 'values': {'dk1': 10.0, 'rk': 5.0, 'dp': 8.0, 'quantity': 4.0}},  // Ожидаемый результат: 8.0
    {'formula': '(s*v*d)/100* quantity', 'values': {'s': 10.0, 'v': 20.0, 'd': 30.0, 'quantity': 2.0}},  // Ожидаемый результат: 12.0
    {'formula': '(d*v*s)/1000* quantity', 'values': {'d': 100.0, 'v': 200.0, 's': 50.0, 'quantity': 3.0}},  // Ожидаемый результат: 30.0
  ];

  final parser = Parser();

  print('🧪 Тестирование расчета формулы с библиотекой math_expressions');
  print('=' * 60);

  for (final testCase in testCases) {
    final formula = testCase['formula'] as String;
    final values = Map<String, double>.from(testCase['values'] as Map);

    // Заменяем переменные на значения (как в реальном коде)
    String processedFormula = formula;
    values.forEach((variable, value) {
      processedFormula = processedFormula.replaceAll(variable, value.toString());
    });

    print('📋 Исходная формула: $formula');
    print('🔄 Обработанная формула: $processedFormula');
    print('📊 Значения переменных: $values');

    try {
      final expression = parser.parse(processedFormula);
      final result = expression.evaluate(EvaluationType.REAL, ContextModel());

      print('✅ Результат: $result');
      print('   Тип: ${result.runtimeType}');
      print('');
    } catch (e) {
      print('❌ Ошибка: $e');
      print('');
    }
  }

  print('Тест завершен!');
}
