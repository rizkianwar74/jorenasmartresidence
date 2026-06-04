import 'package:flutter/material.dart';

class SecurityActivity {
  const SecurityActivity({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

const List<SecurityActivity> mockSecurityActivities = [
  SecurityActivity(
    icon: Icons.wifi_tethering,
    title: 'Gerbang Blok A Dibuka',
    subtitle: 'Baru saja • Via RFID',
  ),
  SecurityActivity(
    icon: Icons.security,
    title: 'Patroli Rutin Selesai',
    subtitle: 'Pukul 07:00 • Area Barat',
  ),
  SecurityActivity(
    icon: Icons.local_shipping_outlined,
    title: 'Tamu Datang: Kurir',
    subtitle: 'Kemarin, 19:15 • Gerbang Utama',
  ),
  SecurityActivity(
    icon: Icons.lock_outline,
    title: 'Pintu Fasilitas Terkunci',
    subtitle: 'Kemarin, 22:00 • Clubhouse',
  ),
  SecurityActivity(
    icon: Icons.notifications_outlined,
    title: 'Uji Coba Alarm Selesai',
    subtitle: '12 Jan • Seluruh Area',
  ),
];