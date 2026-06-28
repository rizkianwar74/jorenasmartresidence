import 'package:flutter/material.dart';

class FeedItem {
  const FeedItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.dt,
    this.badgeLabel,
    this.badgeColor,
  });

  final IconData icon;
  final Color    iconBg;
  final Color    iconColor;
  final String   label;
  final String   sublabel;
  final DateTime dt;
  final String?  badgeLabel;
  final Color?   badgeColor;

  String get waktu {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours   < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
