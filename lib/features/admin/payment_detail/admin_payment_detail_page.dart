import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../pembayaran/data/payment_repository.dart';
import '../../pembayaran/models/tagihan_model.dart';
import 'models/tx_group.dart';
import 'widgets/payment_detail_shared_widgets.dart';
import 'widgets/summary_header_card.dart';
import 'widgets/timeline_widgets.dart';
import 'widgets/detail_table_section.dart';
import 'widgets/info_card_section.dart';
import 'widgets/history_table_section.dart';

class AdminPaymentDetailPage extends StatefulWidget {
  const AdminPaymentDetailPage({
    super.key,
    required this.userId,
    required this.namaResiden,
    required this.blok,
    required this.nomorUnit,
    this.nomorHp,
  });

  final String userId;
  final String namaResiden;
  final String blok;
  final String nomorUnit;
  final String? nomorHp;

  @override
  State<AdminPaymentDetailPage> createState() => _AdminPaymentDetailPageState();
}

class _AdminPaymentDetailPageState extends State<AdminPaymentDetailPage> {
  List<TxGroup> _buildGroups(List<TagihanModel> all) {
    final byOrderId = <String, List<TagihanModel>>{};
    final manual    = <TagihanModel>[];

    for (final t in all) {
      if (t.status != StatusTagihan.lunas) continue;
      if (t.orderId?.isNotEmpty == true) {
        byOrderId.putIfAbsent(t.orderId!, () => []).add(t);
      } else {
        manual.add(t);
      }
    }

    final groups = <TxGroup>[
      for (final e in byOrderId.entries)
        TxGroup.fromTagihan(e.value, orderId: e.key),
      for (final t in manual)
        TxGroup.fromTagihan([t], orderId: null),
    ];
    groups.sort((a, b) => b.maxKey.compareTo(a.maxKey));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: StreamBuilder<List<TagihanModel>>(
              stream: PaymentRepository.watchUserTagihan(widget.userId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }
                final allTagihan = List<TagihanModel>.from(snap.data ?? []);
                allTagihan.sort((a, b) =>
                    (a.tahun * 12 + a.bulanIndex)
                        .compareTo(b.tahun * 12 + b.bulanIndex));

                final groups  = _buildGroups(allTagihan);
                final latestG = groups.isNotEmpty ? groups.first : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SummaryHeaderCard(
                        namaResiden: widget.namaResiden,
                        blok: widget.blok,
                        nomorUnit: widget.nomorUnit,
                        nomorHp: widget.nomorHp,
                        allTagihan: allTagihan,
                        latestG: latestG,
                      ),
                      const SizedBox(height: 20),
                      TimelineSection(allTagihan: allTagihan),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: DetailTableSection(allTagihan: allTagihan),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 300,
                            child: InfoCardSection(
                              latestG: latestG,
                              allTagihan: allTagihan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      HistoryTableSection(groups: groups),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 13),
            label: Text('Kembali',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detail Pembayaran',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Pembayaran',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textGrey)),
                    Chevron(),
                    Text('Billing',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textGrey)),
                    Chevron(),
                    Text('Detail Pembayaran',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
