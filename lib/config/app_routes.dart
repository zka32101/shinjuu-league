import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/ui/screens/battle_screen.dart';
import 'package:shinjuu_league/ui/screens/battlepass_screen.dart';
import 'package:shinjuu_league/ui/screens/evolution_select_screen.dart';
import 'package:shinjuu_league/ui/screens/friends_screen.dart';
import 'package:shinjuu_league/ui/screens/inventory_screen.dart';
import 'package:shinjuu_league/ui/screens/lobby_screen.dart';
import 'package:shinjuu_league/ui/screens/matching_screen.dart';
import 'package:shinjuu_league/ui/screens/mecha_select_screen.dart';
import 'package:shinjuu_league/ui/screens/onboarding_screen.dart';
import 'package:shinjuu_league/ui/screens/rank_screen.dart';
import 'package:shinjuu_league/ui/screens/result_screen.dart';
import 'package:shinjuu_league/ui/screens/shop_screen.dart';
import 'package:shinjuu_league/ui/screens/skill_build_screen.dart';
import 'package:shinjuu_league/ui/screens/skill_tree_progression_screen.dart';
import 'package:shinjuu_league/ui/screens/splash_screen.dart';
import 'package:shinjuu_league/ui/screens/achievements_screen.dart';
import 'package:shinjuu_league/ui/screens/quests_screen.dart';
import 'package:shinjuu_league/ui/screens/admin_dashboard_screen.dart';
import 'package:shinjuu_league/ui/screens/admin_difficulty_tuning_screen.dart';
import 'package:shinjuu_league/ui/screens/admin_feature_flags_screen.dart';
import 'package:shinjuu_league/ui/screens/admin_experiments_screen.dart';
import 'package:shinjuu_league/ui/screens/admin_audit_log_screen.dart';
import 'package:shinjuu_league/ui/screens/admin_snapshots_screen.dart';
import 'package:shinjuu_league/ui/screens/admin_roles_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const lobby = '/lobby';
  static const matching = '/matching';
  static const evolution = '/evolution';
  static const skillBuild = '/skill-build';
  static const battle = '/battle';
  static const result = '/result';
  static const rank = '/rank';
  static const friends = '/friends';
  static const shop = '/shop';
  static const battlePass = '/battlepass';
  static const mechaSelect = '/mecha-select';
  static const inventory = '/inventory';
  static const skillTreeProgression = '/skill-tree-progression';
  static const achievements = '/achievements';
  static const quests = '/quests';
  static const adminDashboard = '/admin-dashboard';
  static const adminDifficultyTuning = '/admin-difficulty-tuning';
  static const adminFeatureFlags = '/admin-feature-flags';
  static const adminExperiments = '/admin-experiments';
  static const adminAuditLog = '/admin-audit-log';
  static const adminSnapshots = '/admin-snapshots';
  static const adminRoles = '/admin-roles';
}

/// フェード + わずかな上方向スライドで統一した画面遷移
CustomTransitionPage<T> _buildPage<T>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(fade);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const OnboardingScreen()),
    ),
    GoRoute(
      path: AppRoutes.lobby,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const LobbyScreen()),
    ),
    GoRoute(
      path: AppRoutes.matching,
      pageBuilder: (context, state) {
        final mode = state.extra as BattleMode? ?? BattleMode.quick;
        return _buildPage(context, state, MatchingScreen(mode: mode));
      },
    ),
    GoRoute(
      path: AppRoutes.evolution,
      pageBuilder: (context, state) {
        final match = state.extra as MatchResult?;
        if (match == null) return _buildPage(context, state, const LobbyScreen());
        return _buildPage(context, state, EvolutionSelectScreen(match: match));
      },
    ),
    GoRoute(
      path: AppRoutes.skillBuild,
      pageBuilder: (context, state) {
        final match = state.extra as MatchResult?;
        if (match == null) return _buildPage(context, state, const LobbyScreen());
        return _buildPage(context, state, SkillBuildScreen(match: match));
      },
    ),
    GoRoute(
      path: AppRoutes.battle,
      pageBuilder: (context, state) {
        final match = state.extra as MatchResult?;
        if (match == null) return _buildPage(context, state, const LobbyScreen());
        return _buildPage(context, state, BattleScreen(match: match));
      },
    ),
    GoRoute(
      path: AppRoutes.result,
      pageBuilder: (context, state) {
        final battle = state.extra as Battle?;
        if (battle == null) return _buildPage(context, state, const LobbyScreen());
        return _buildPage(context, state, ResultScreen(battle: battle));
      },
    ),
    GoRoute(
      path: AppRoutes.rank,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const RankScreen()),
    ),
    GoRoute(
      path: AppRoutes.friends,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const FriendsScreen()),
    ),
    GoRoute(
      path: AppRoutes.shop,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const ShopScreen()),
    ),
    GoRoute(
      path: AppRoutes.battlePass,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const BattlePassScreen()),
    ),
    GoRoute(
      path: AppRoutes.mechaSelect,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const MechaSelectScreen()),
    ),
    GoRoute(
      path: AppRoutes.inventory,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const InventoryScreen()),
    ),
    GoRoute(
      path: AppRoutes.skillTreeProgression,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const SkillTreeProgressionScreen()),
    ),
    GoRoute(
      path: AppRoutes.achievements,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const AchievementsScreen()),
    ),
    GoRoute(
      path: AppRoutes.quests,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const QuestsScreen()),
    ),
    GoRoute(
      path: AppRoutes.adminDashboard,
      pageBuilder: (context, state) =>
          _buildPage(context, state, const AdminDashboardScreen()),
    ),
    GoRoute(
      path: AppRoutes.adminDifficultyTuning,
      pageBuilder: (context, state) {
        // Note: In a real app, dashboardService would be injected via Riverpod
        // For now, using a placeholder that must be initialized in the screen
        return _buildPage(
          context,
          state,
          AdminDifficultyTuningScreen(
            dashboardService: null as dynamic, // Placeholder
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminFeatureFlags,
      pageBuilder: (context, state) {
        return _buildPage(
          context,
          state,
          AdminFeatureFlagsScreen(
            dashboardService: null as dynamic, // Placeholder
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminExperiments,
      pageBuilder: (context, state) {
        return _buildPage(
          context,
          state,
          AdminExperimentsScreen(
            dashboardService: null as dynamic, // Placeholder
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminAuditLog,
      pageBuilder: (context, state) {
        return _buildPage(
          context,
          state,
          AdminAuditLogScreen(
            dashboardService: null as dynamic, // Placeholder
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminSnapshots,
      pageBuilder: (context, state) {
        return _buildPage(
          context,
          state,
          AdminSnapshotsScreen(
            dashboardService: null as dynamic, // Placeholder
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminRoles,
      pageBuilder: (context, state) {
        return _buildPage(
          context,
          state,
          const AdminRolesScreen(),
        );
      },
    ),
  ],
);
