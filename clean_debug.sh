#!/bin/bash

# Скрипт для удаления отладочного кода из Flutter приложения

echo "🧹 Начинаем очистку отладочного кода..."

# Файлы для обработки
files=(
    "lib/core/network/dio_client.dart"
    "lib/features/producers/presentation/providers/producers_provider.dart"
    "lib/features/warehouses/data/datasources/warehouses_remote_datasource.dart"
    "lib/features/warehouses/presentation/pages/warehouse_form_page.dart"
    "lib/features/sales/data/datasources/sales_remote_datasource.dart"
    "lib/features/sales/data/repositories/sales_repository_impl.dart"
    "lib/features/sales/presentation/providers/sales_providers.dart"
    "lib/features/sales/presentation/pages/sale_form_page.dart"
    "lib/features/sales/presentation/pages/sales_list_page.dart"
    "lib/features/auth/data/datasources/auth_remote_datasource.dart"
    "lib/features/auth/domain/usecases/login_usecase.dart"
    "lib/features/auth/presentation/providers/auth_provider.dart"
    "lib/features/auth/presentation/pages/splash_page_simple.dart"
    "lib/features/auth/presentation/pages/login_page.dart"
    "lib/features/auth/presentation/widgets/login_form.dart"
    "lib/features/requests/data/datasources/requests_remote_datasource.dart"
    "lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart"
    "lib/features/dashboard/data/datasources/admin_stats_datasource.dart"
    "lib/features/dashboard/data/repositories/admin_stats_repository.dart"
    "lib/features/dashboard/presentation/providers/dashboard_provider.dart"
    "lib/features/dashboard/presentation/pages/admin_dashboard_page.dart"
    "lib/features/dashboard/presentation/pages/dashboard_page.dart"
    "lib/features/dashboard/presentation/widgets/modern_sidebar.dart"
    "lib/features/acceptance/data/datasources/acceptance_remote_datasource.dart"
    "lib/features/acceptance/presentation/providers/acceptance_provider.dart"
    "lib/features/acceptance/presentation/pages/acceptance_list_page.dart"
    "lib/features/acceptance/presentation/pages/acceptance_form_page.dart"
    "lib/features/inventory/data/datasources/inventory_stocks_remote_datasource.dart"
    "lib/features/inventory/data/datasources/inventory_remote_datasource.dart"
    "lib/features/users/data/datasources/users_remote_datasource.dart"
    "lib/features/users/presentation/pages/user_form_page.dart"
    "lib/features/products_in_transit/data/datasources/product_template_remote_datasource.dart"
    "lib/features/products_in_transit/data/datasources/products_in_transit_remote_datasource.dart"
    "lib/features/products_in_transit/presentation/providers/products_in_transit_provider.dart"
    "lib/features/products_in_transit/presentation/pages/product_in_transit_detail_page.dart"
    "lib/features/products_in_transit/presentation/pages/products_in_transit_list_page.dart"
    "lib/features/products_inflow/data/datasources/products_inflow_remote_datasource.dart"
    "lib/features/products_inflow/data/datasources/product_template_remote_datasource.dart"
    "lib/features/products_inflow/presentation/providers/products_inflow_provider.dart"
    "lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart"
    "lib/features/products_inflow/presentation/pages/products_inflow_list_page.dart"
    "lib/features/products_inflow/presentation/pages/product_inflow_detail_page.dart"
    "lib/shared/models/product_model.dart"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Очищаем $file..."

        # Удаляем строки с отладочными принтами
        sed -i '/print.*🔵/d' "$file"
        sed -i '/print.*🔴/d' "$file"
        sed -i '/print.*🔍/d' "$file"
        sed -i '/print.*💡/d' "$file"
        sed -i '/print.*⚠️/d' "$file"
        sed -i '/print.*✅/d' "$file"
        sed -i '/print.*❌/d' "$file"
        sed -i '/print.*📊/d' "$file"
        sed -i '/print.*🎯/d' "$file"

        # Удаляем пустые строки, оставшиеся после удаления принтов
        sed -i '/^[[:space:]]*$/d' "$file"

        echo "✅ $file очищен"
    else
        echo "❌ Файл не найден: $file"
    fi
done

echo "🎉 Очистка завершена!"


