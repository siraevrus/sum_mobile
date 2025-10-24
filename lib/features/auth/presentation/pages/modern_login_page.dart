import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/auth/presentation/widgets/modern_login_form.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';

/// Современный экран авторизации в стиле веб-фронта
class ModernLoginPage extends ConsumerWidget {
  const ModernLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Слушаем изменения состояния аутентификации
    ref.listen<AuthState>(authProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user, token) {
          if (context.mounted) {
            final target = user.role == UserRole.admin ? '/dashboard' : '/inventory';
            context.go(target);
          }
        },
        error: (message) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // Логотип
                SvgPicture.asset(
                  'assets/logos/logo-expertwood-green.svg',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 24),
                
                // Заголовок
                const Text(
                  'Wood Warehouse',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF256437),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Система складского учета
                const Text(
                  'Система складского учета',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF256437),
                  ),
                ),
                const SizedBox(height: 60),
                
                // Форма входа в белой карточке
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: ModernLoginForm(),
                  ),
                ),
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
