import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/ui/screens/battle_screen.dart';
import 'package:shinjuu_league/ui/screens/battlepass_screen.dart';
import 'package:shinjuu_league/ui/screens/evolution_select_screen.dart';
import 'package:shinjuu_league/ui/screens/friends_screen.dart';
import 'package:shinjuu_league/ui/screens/lobby_screen.dart';
import 'package:shinjuu_league/ui/screens/matching_screen.dart';
import 'package:shinjuu_league/ui/screens/onboarding_screen.dart';
import 'package:shinjuu_league/ui/screens/rank_screen.dart';
import 'package:shinjuu_league/ui/screens/result_screen.dart';
import 'package:shinjuu_league/ui/screens/shop_screen.dart';
import 'package:shinjuu_league/ui/screens/splash_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const lobby = '/lobby';
  static const matching = '/matching';
  static const evolution = '/evolution';
  static const battle = '/battle';
  static const result = '/result';
  static const rank = '/rank';
  static const friends = '/friends';
  static const shop = '/shop';
  static const battlePass = '/battlepass';
}

/// フェード + わずかな上方向スライドで統一した画面遷移
CustomTransitionPage<T> _buildPage<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(fade);
      return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
    },
  );
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) => _buildPage(context, state, const OnboardingScreen()),
    ),
    GoRoute(
      path: AppRoutes.lobby,
      pageBuilder: (context, state) => _buildPage(context, state, const LobbyScreen()),
    ),
    GoRoute(
      path: AppRoutes.matching,
      pageBuilder: (context, state) => _buildPage(context, state, MatchingScreen(mode: state.extra as BattleMode)),
    ),
    GoRoute(
      path: AppRoutes.evolution,
      pageBuilder: (context, state) =>
          _buildPage(context, state, EvolutionSelectScreen(match: state.extra as MatchResult)),
    ),
    GoRoute(
      path: AppRoutes.battle,
      pageBuilder: (context, state) => _buildPage(context, state, BattleScreen(match: state.extra as MatchResult)),
    ),
    GoRoute(
      path: AppRoutes.result,
      pageBuilder: (context, state) => _buildPage(context, state, ResultScreen(battle: state.extra as Battle)),
    ),
    GoRoute(
      path: AppRoutes.rank,
      pageBuilder: (context, state) => _buildPage(context, state, const RankScreen()),
    ),
    GoRoute(
      path: AppRoutes.friends,
      pageBuilder: (context, state) => _buildPage(context, state, const FriendsScreen()),
    ),
    GoRoute(
      path: AppRoutes.shop,
      pageBuilder: (context, state) => _buildPage(context, state, const ShopScreen()),
    ),
    GoRoute(
      path: AppRoutes.battlePass,
      pageBuilder: (context, state) => _buildPage(context, state, const BattlePassScreen()),
    ),
  ],
);
