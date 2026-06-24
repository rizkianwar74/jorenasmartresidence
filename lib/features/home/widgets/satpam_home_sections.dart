part of '../satpam_home_page.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid: 2x2
// ─────────────────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.activePatrols,
    required this.tamuHariIni,
    required this.insidenAktif,
    required this.onTamuTap,
    required this.onInsidenTap,
  });
  final int activePatrols;
  final int tamuHariIni;
  final int insidenAktif;
  final VoidCallback onTamuTap;
  final VoidCallback onInsidenTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Patroli + Tamu
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.route_outlined,
                iconColor: AppColors.primary,
                iconBg: const Color(0xFFE3F0FF),
                label: 'PATROLI AKTIF',
                value: '$activePatrols',
                valueLabel: 'Online',
                valueColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline,
                iconColor: const Color(0xFF512DA8),
                iconBg: const Color(0xFFEDE7F6),
                label: 'TAMU HARI INI',
                value: '$tamuHariIni',
                valueLabel: 'Orang',
                valueColor: const Color(0xFF0D1B2A),
                onTap: onTamuTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Row 2: Insiden full-width
        _StatCard(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFD32F2F),
          iconBg: const Color(0xFFFFEBEE),
          label: 'INSIDEN AKTIF',
          value: '$insidenAktif',
          valueLabel: 'Kasus',
          valueColor: insidenAktif > 0
              ? const Color(0xFFD32F2F)
              : const Color(0xFF2E7D32),
          onTap: onInsidenTap,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.valueColor,
    this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String valueLabel;
  final Color valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      valueLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: Color(0xFFB0BEC5)),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onMulaiPatroli,
    required this.onCatatTamu,
    required this.onLaporInsiden,
  });
  final VoidCallback onMulaiPatroli;
  final VoidCallback onCatatTamu;
  final VoidCallback onLaporInsiden;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Mulai Patroli — primary, lebih besar
            Expanded(
              flex: 5,
              child: _QuickActionPrimary(
                icon: Icons.shield_outlined,
                label: 'Mulai\nPatroli',
                colors: const [Color(0xFF1E6FD9), Color(0xFF1173D4)],
                shadowColor: AppColors.primary,
                onTap: onMulaiPatroli,
              ),
            ),
            const SizedBox(width: 12),
            // Kolom kanan: 2 tombol kecil
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _QuickActionSecondary(
                    icon: Icons.person_add_outlined,
                    label: 'Catat Tamu',
                    iconBg: const Color(0xFFEDE7F6),
                    iconColor: const Color(0xFF512DA8),
                    onTap: onCatatTamu,
                  ),
                  const SizedBox(height: 10),
                  _QuickActionSecondary(
                    icon: Icons.report_problem_outlined,
                    label: 'Lapor Insiden',
                    iconBg: const Color(0xFFFFEBEE),
                    iconColor: const Color(0xFFD32F2F),
                    onTap: onLaporInsiden,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionPrimary extends StatelessWidget {
  const _QuickActionPrimary({
    required this.icon,
    required this.label,
    required this.colors,
    required this.shadowColor,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final List<Color> colors;
  final Color shadowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Lingkaran dekoratif
            Positioned(
              right: -16,
              top: -16,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Konten
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionSecondary extends StatelessWidget {
  const _QuickActionSecondary({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFFB0BEC5),
            ),
          ],
        ),
      ),
    );
  }
}
