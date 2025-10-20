#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Sum Warehouse - Запуск Тестов       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Опции
PS3=$'Выберите действие:\n'
options=(
  "Запустить все тесты"
  "Тесты Inventory (Остатки на складе)"
  "Тесты Sales (Реализация)"
  "Тесты Products Inflow (Поступление товаров)"
  "Тесты Acceptance (Приемка товаров)"
  "Тесты API Models"
  "Запустить тесты с покрытием"
  "Запустить с вербозным выводом"
  "Выход"
)

select opt in "${options[@]}"
do
  case $REPLY in
    1)
      echo -e "${YELLOW}▶ Запуск всех тестов...${NC}"
      flutter test
      break
      ;;
    2)
      echo -e "${YELLOW}▶ Запуск тестов Inventory...${NC}"
      flutter test test/features/inventory/inventory_tests.dart -v
      break
      ;;
    3)
      echo -e "${YELLOW}▶ Запуск тестов Sales...${NC}"
      flutter test test/features/sales/sales_tests.dart -v
      break
      ;;
    4)
      echo -e "${YELLOW}▶ Запуск тестов Products Inflow...${NC}"
      flutter test test/features/products_inflow/products_inflow_tests.dart -v
      break
      ;;
    5)
      echo -e "${YELLOW}▶ Запуск тестов Acceptance...${NC}"
      flutter test test/features/acceptance/acceptance_tests.dart -v
      break
      ;;
    6)
      echo -e "${YELLOW}▶ Запуск тестов API Models...${NC}"
      flutter test test/core/models/api_response_model_test.dart -v
      break
      ;;
    7)
      echo -e "${YELLOW}▶ Запуск тестов с покрытием...${NC}"
      flutter test --coverage
      echo ""
      echo -e "${GREEN}✓ Покрытие сохранено в coverage/lcov.info${NC}"
      echo -e "${BLUE}Чтобы открыть отчет, выполните:${NC}"
      echo -e "  genhtml coverage/lcov.info -o coverage/html"
      echo -e "  open coverage/html/index.html"
      break
      ;;
    8)
      echo -e "${YELLOW}▶ Запуск всех тестов с вербозным выводом...${NC}"
      flutter test -v
      break
      ;;
    9)
      echo -e "${GREEN}Выход${NC}"
      break
      ;;
    *)
      echo -e "${YELLOW}Неверный выбор$((REPLY)). Попробуйте еще раз.${NC}"
      ;;
  esac
done

echo ""
echo -e "${GREEN}✓ Готово!${NC}"
