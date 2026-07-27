import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';

const _selectTimeoutSeconds = 10;

class EvolutionSelectScreen extends ConsumerStatefulWidget {
  const EvolutionSelectScreen({super.key, required this.match});
  final MatchResult match;

  @override
  ConsumerState<EvolutionSelectScreen> createState() =>
      _EvolutionSelectScreenState();
}

class _EvolutionSelectScreenState extends ConsumerState<EvolutionSelectScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = _selectTimeoutSeconds;
  bool _isLocked = false;
  // prepareBattle()（非同期）の完了をselect()側で必ず待てるようにする。
  // 待たないと、初回フレーム直後の極めて短い間にユーザーがタップした場合
  // state.engineがまだnullで lockEvolution/beginCombat が無言で失敗し、
  // 試合が永久に開始されない状態になり得る（レースコンディション）。
  final _prepareCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepare();
      if (!_prepareCompleter.isCompleted) _prepareCompleter.complete();
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        _select(Evolution.attack()); // タイムアウト時は攻撃をデフォルト選択
      }
    });
  }

  Future<void> _prepare() async {
    final currentUser = ref.read(userViewModelProvider).value;
    if (currentUser == null) return;
    await ref
        .read(battleViewModelProvider.notifier)
        .prepareBattle(widget.match, currentUser.uid, currentUser.eloRating);
  }

  Future<void> _select(Evolution evolution) async {
    if (_isLocked) return;
    _isLocked = true;
    _countdownTimer?.cancel();

    await _prepareCompleter.future;
    if (!mounted) return;

    final viewModel = ref.read(battleViewModelProvider.notifier);
    viewModel.lockEvolution(evolution);
    viewModel.beginCombat();

    context.pushReplacement(AppRoutes.battle, extra: widget.match);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('試合前進化選択'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '残り $_remainingSeconds 秒',
                style: TextStyle(
                  fontSize: 16,
                  color: _remainingSeconds <= 3 ? Colors.red : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _EvolutionCard(
                        evolution: Evolution.attack(),
                        onTap: () => _select(Evolution.attack()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _EvolutionCard(
                        evolution: Evolution.defense(),
                        onTap: () => _select(Evolution.defense()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _EvolutionCard(
                        evolution: Evolution.mobility(),
                        onTap: () => _select(Evolution.mobility()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({required this.evolution, required this.onTap});
  final Evolution evolution;
  final VoidCallback onTap;

  IconData get _icon => switch (evolution.type) {
    EvolutionType.attack => Icons.local_fire_department,
    EvolutionType.defense => Icons.shield,
    EvolutionType.mobility => Icons.speed,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                evolution.type.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                evolution.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
