import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/ui/screens/battle_screen.dart';
import 'package:shinjuu_league/ui/screens/evolution_select_screen.dart';
import 'package:shinjuu_league/ui/screens/friends_screen.dart';
import 'package:shinjuu_league/ui/screens/lobby_screen.dart';
import 'package:shinjuu_league/ui/screens/matching_screen.dart';
import 'package:shinjuu_league/ui/screens/onboarding_screen.dart';
import 'package:shinjuu_league/ui/screens/rank_screen.dart';
import 'package:shinjuu_league/ui/screens/result_screen.dart';
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
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
    GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: AppRoutes.lobby, builder: (context, state) => const LobbyScreen()),
    GoRoute(
      path: AppRoutes.matching,
      builder: (context, state) => MatchingScreen(mode: state.extra as BattleMode),
    ),
    GoRoute(
      path: AppRoutes.evolution,
      builder: (context, state) => EvolutionSelectScreen(match: state.extra as MatchResult),
    ),
    GoRoute(
      path: AppRoutes.battle,
      builder: (context, state) => BattleScreen(match: state.extra as MatchResult),
    ),
    GoRoute(
      path: AppRoutes.result,
      builder: (context, state) => ResultScreen(battle: state.extra as Battle),
    ),
    GoRoute(path: AppRoutes.rank, builder: (context, state) => const RankScreen()),
    GoRoute(path: AppRoutes.friends, builder: (context, state) => const FriendsScreen()),
  ],
);
