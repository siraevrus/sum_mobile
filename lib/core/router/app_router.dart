import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/auth/presentation/pages/modern_login_page.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/dashboard/presentation/pages/responsive_dashboard_page.dart';
import 'package:sum_warehouse/features/auth/presentation/pages/splash_page_simple.dart';

part 'app_router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentLocation = state.matchedLocation;
      final isLoginRoute = currentLocation == '/login';
      final isDashboardRoute = currentLocation == '/dashboard';
      final isSplashRoute = currentLocation == '/';
      
      print('🔄 Router redirect check: $currentLocation (auth: ${authState.runtimeType})');
      
      final redirect = authState.when(
        initial: () {
          // Во время инициализации показываем splash
          if (!isSplashRoute) {
            print('🔄 Router: Initial state, redirect to splash');
            return '/';
          }
          return null;
        },
        loading: () {
          // ВО ВРЕМЯ LOADING показываем splash
          print('🔄 Router: Loading state, staying on $currentLocation');
          if (!isSplashRoute) {
            print('🔄 Router: Loading - redirect to splash');
            return '/';
          }
          return null;
        },
        authenticated: (user, token) {
          // Если пользователь авторизован — перенаправляем на секцию по роли
          String defaultForRole() {
            switch (user.role) {
              case UserRole.admin:
                return '/dashboard';
              case UserRole.salesManager:
                // sales менеджер — сначала остатки
                return '/inventory';
              case UserRole.operator:
                return '/inventory';
              case UserRole.warehouseWorker:
                return '/inventory';
              case UserRole.manager:
                return '/inventory';
            }
          }

          final target = defaultForRole();

          if (isSplashRoute) {
            print('🔄 Router: Авторизован, переход с splash на $target');
            return target;
          }
          if (isLoginRoute) {
            print('🔄 Router: Авторизован, переход с логина на $target');
            return target;
          }
          return null;
        },
        unauthenticated: () {
          // Если не авторизован - ВСЕГДА перенаправляем на логин (кроме уже на логине)
          if (!isLoginRoute) {
            print('🔄 Router: Не авторизован, переход с $currentLocation на логин');
            return '/login';
          }
          return null;
        },
        error: (message) {
          // При ошибке авторизации - перенаправляем на логин ТОЛЬКО если не на логине
          if (!isLoginRoute) {
            print('🔄 Router: Ошибка авторизации ($message), переход на логин');
            return '/login';
          }
          return null;
        },
      );
      
      if (redirect != null) {
        print('🔄 Router redirect: $currentLocation → $redirect');
      }
      
      return redirect;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SimpleSplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const ModernLoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const ResponsiveDashboardPage(),
      ),
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ResponsiveDashboardPage(selectedSection: 'products'),
      ),
      GoRoute(
        path: '/warehouses',
        name: 'warehouses',
        builder: (context, state) => const ResponsiveDashboardPage(selectedSection: 'warehouses'),
      ),
      GoRoute(
        path: '/sales',
        name: 'sales',
        builder: (context, state) => const ResponsiveDashboardPage(selectedSection: 'sales'),
      ),
      GoRoute(
        path: '/requests',
        name: 'requests',
        builder: (context, state) => const ResponsiveDashboardPage(selectedSection: 'requests'),
      ),
      GoRoute(
        path: '/employees',
        name: 'employees',
        builder: (context, state) => const ResponsiveDashboardPage(selectedSection: 'employees'),
      ),
      GoRoute(
        path: '/companies',
        name: 'companies',
        builder: (context, state) => const ResponsiveDashboardPage(selectedSection: 'companies'),
      ),
      GoRoute(
        path: '/producers',
        name: 'producers',
        builder: (context, state) => const ResponsiveDashboardPage(selectedSection: 'producers'),
      ),
      GoRoute(
        path: '/inventory',
        name: 'inventory',
        builder: (context, state) => const ResponsiveDashboardPage(selectedSection: 'inventory'),
      ),
      GoRoute(
        path: '/reception',
        name: 'reception',
        builder: (context, state) => const ResponsiveDashboardPage(selectedSection: 'reception'),
      ),
      GoRoute(
        path: '/goods_in_transit',
        name: 'goods_in_transit',
        builder: (context, state) => const ResponsiveDashboardPage(selectedSection: 'goods_in_transit'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text('Страница не найдена: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    ),
  );
}

