import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(userViewModelProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user == null) {
            context.go(AppRoutes.onboarding);
          } else {
            context.go(AppRoutes.lobby);
          }
        },
        loading: () {},
        error: (_, _) => context.go(AppRoutes.onboarding),
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('神獣リーグ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('v${AppConfig.version}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
