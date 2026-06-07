import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import 'tagihan_model.dart';

enum PaymentResult { success, failed, pending }

class PaymentStatusPage extends StatelessWidget {
  const PaymentStatusPage({
    super.key,
    required this.tagihan,
    required this.result,
  });

  final TagihanModel tagihan;
  final PaymentResult result;

  String get _title => switch (result) {
        PaymentResult.success => 'Pembayaran Berhasil!',
        PaymentResult.failed  => 'Pembayaran Gagal',
        PaymentResult.pending => 'Menunggu Konfirmasi',
      };

  String get _description => switch (result) {
        PaymentResult.success =>
          'Iuran ${tagihan.periodeLabel} telah berhasil dibayar. Terima kasih!',
        PaymentResult.failed =>
          'Transaksi tidak dapat diproses. Silakan coba lagi atau gunakan metode lain.',
        PaymentResult.pending =>
          'Pembayaran sedang diverifikasi. Konfirmasi akan dikirim setelah pembayaran dikonfirmasi.',
      };

  @override
  Widget build(BuildContext context) {
    final Color iconBg = switch (result) {
      PaymentResult.success => Colors.green.shade50,
      PaymentResult.failed  => Colors.red.shade50,
      PaymentResult.pending => Colors.orange.shade50,
    };
    final Color iconColor = switch (result) {
      PaymentResult.success => Colors.green.shade600,
      PaymentResult.failed  => Colors.red.shade600,
      PaymentResult.pending => Colors.orange.shade600,
    };
    final IconData icon = switch (result) {
      PaymentResult.success => Icons.check_circle_rounded,
      PaymentResult.failed  => Icons.cancel_rounded,
      PaymentResult.pending => Icons.access_time_rounded,
    };
    final String statusLabel = switch (result) {
      PaymentResult.success => 'Berhasil',
      PaymentResult.failed  => 'Gagal',
      PaymentResult.pending => 'Pending',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(),

                  // Ikon status
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                        color: iconBg, shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 64),
                  ),

                  const SizedBox(height: 28),

                  Text(_title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),

                  const SizedBox(height: 10),

                  Text(_description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textGrey,
                          height: 1.6)),

                  const SizedBox(height: 28),

                  // Info transaksi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Periode', value: tagihan.periodeLabel),
                        const SizedBox(height: 10),
                        _InfoRow(label: 'Unit', value: tagihan.unitLabel),
                        const SizedBox(height: 10),
                        _InfoRow(label: 'Jumlah', value: tagihan.jumlahFormatted),
                        const SizedBox(height: 10),
                        _InfoRow(
                            label: 'Status',
                            value: statusLabel,
                            valueColor: iconColor),
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, AppRouter.home, (_) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Kembali ke Beranda',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  if (result == PaymentResult.failed) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Coba Lagi',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textGrey)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textDark)),
      ],
    );
  }
}