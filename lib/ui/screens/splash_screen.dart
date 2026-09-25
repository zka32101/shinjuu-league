import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  void _handle(BuildContext context, AsyncValue<User?> value) {
    value.when(
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(userViewModelProvider, (previous, next) => _handle(context, next));

    // ref.listen only reacts to *future* state changes. UserViewModel._init()
    // sets state synchronously (to AsyncValue.data(null)) when there is no
    // signed-in user yet — e.g. a fresh install with no anonymous session —
    // and that happens during provider creation, before the listener above
    // attaches. Without this, that transition is missed and the splash
    // screen hangs forever instead of navigating to onboarding. Handle the
    // already-current value too, once this frame has committed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _handle(context, ref.read(userViewModelProvider));
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '神獣リーグ',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'v${AppConfig.version}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
