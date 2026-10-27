import 'package:flutter/material.dart';

/// ミニマップ上の1エントリの種別
enum MinimapEntryType { self, ally, enemy, monster }

/// チームピング（UNITE風のプリセット合図）の種類。
/// このゲームは専用マルチプレイサーバーが未構築で、他デバイスへのリアルタイム
/// 配信は行わない（BattleEngineの設計コメント参照）。そのためピングは
/// 現状「自分の操作に対する即時フィードバック（視覚+ハプティクス）」としてのみ
/// 機能し、実際の味方（ボット）には配信されない。将来マルチプレイ化した際に
/// 配信経路を追加する拡張ポイントとして型だけ先に用意している。
enum PingType { help, attacking, retreat }

extension PingTypeInfo on PingType {
  String get emoji {
    switch (this) {
      case PingType.help:
        return '🆘';
      case PingType.attacking:
        return '⚔️';
      case PingType.retreat:
        return '🏃';
    }
  }

  String get label {
    switch (this) {
      case PingType.help:
        return '助けて！';
      case PingType.attacking:
        return '攻撃中！';
      case PingType.retreat:
        return '撤退！';
    }
  }
}

/// ミニマップ上に一時的に表示するピングマーカー（-1.0〜1.0正規化座標）。
class MinimapPing {
  final PingType type;
  final double x;
  final double y;

  const MinimapPing({required this.type, required this.x, required this.y});
}

/// ミニマップに表示する1エントリ（-1.0〜1.0に正規化した座標）
class MinimapEntry {
  final String id;
  final double x;
  final double y;
  final MinimapEntryType type;
  final bool isAlive;

  const MinimapEntry({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.isAlive,
  });
}

/// 戦場全体を俯瞰するミニマップ。自分・味方・敵・中立モンスターの位置を
/// リアルタイムに表示し、マップ全体を歩き回れるようになった戦況把握を助ける。
class Minimap extends StatelessWidget {
  const Minimap({
    super.key,
    required this.entries,
    this.size = 120,
    this.activePing,
  });

  final List<MinimapEntry> entries;
  final double size;

  /// 現在表示中のピングマーカー（期限切れ/未送信ならnull）。
  final MinimapPing? activePing;

  Color _colorFor(MinimapEntryType type, bool isAlive) {
    if (!isAlive) return Colors.grey.withValues(alpha: 0.4);
    switch (type) {
      case MinimapEntryType.self:
        return Colors.amberAccent;
      case MinimapEntryType.ally:
        return const Color(0xFF3B82F6);
      case MinimapEntryType.enemy:
        return const Color(0xFFEF4444);
      case MinimapEntryType.monster:
        return const Color(0xFF4ADE80);
    }
  }

  double _radiusFor(MinimapEntryType type) {
    switch (type) {
      case MinimapEntryType.self:
        return 5.0;
      case MinimapEntryType.monster:
        return 4.0;
      default:
        return 3.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _MinimapPainter(
              entries: entries,
              colorFor: _colorFor,
              radiusFor: _radiusFor,
            ),
          ),
          if (activePing != null) _PingBadge(ping: activePing!, mapSize: size),
        ],
      ),
    );
  }
}

/// ピングの絵文字+ラベルを吹き出しとして一時表示する。
class _PingBadge extends StatelessWidget {
  const _PingBadge({required this.ping, required this.mapSize});

  final MinimapPing ping;
  final double mapSize;

  @override
  Widget build(BuildContext context) {
    final dx = (ping.x.clamp(-1.0, 1.0) + 1) / 2 * mapSize;
    final dy = (ping.y.clamp(-1.0, 1.0) + 1) / 2 * mapSize;

    return Positioned(
      left: (dx - 28).clamp(0.0, mapSize - 56),
      top: (dy - 34).clamp(0.0, mapSize - 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amberAccent, width: 1),
        ),
        child: Text(
          '${ping.type.emoji} ${ping.type.label}',
          style: const TextStyle(fontSize: 9, color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.entries,
    required this.colorFor,
    required this.radiusFor,
  });

  final List<MinimapEntry> entries;
  final Color Function(MinimapEntryType, bool) colorFor;
  final double Function(MinimapEntryType) radiusFor;

  @override
  void paint(Canvas canvas, Size size) {
    // 中央のレーン区切り線（2レーン構成を表現）
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), linePaint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), linePaint);

    for (final entry in entries) {
      final dx = (entry.x.clamp(-1.0, 1.0) + 1) / 2 * size.width;
      final dy = (entry.y.clamp(-1.0, 1.0) + 1) / 2 * size.height;
      final color = colorFor(entry.type, entry.isAlive);
      final radius = radiusFor(entry.type);

      final paint = Paint()..color = color;
      canvas.drawCircle(Offset(dx, dy), radius, paint);

      if (entry.type == MinimapEntryType.self) {
        final ringPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(dx, dy), radius + 2, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}
