import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_repository.dart';
import '../../pembayaran/data/payment_repository.dart';
import '../../pembayaran/models/tagihan_model.dart';
import '../../../tool/seed_tagihan.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_top_bar.dart';
import '../payment_detail/admin_payment_detail_page.dart';
import 'billing_content.dart';
import 'billing_dialogs.dart';
import 'widgets/billing_shared_widgets.dart';

class AdminBillingPage extends StatefulWidget {
  const AdminBillingPage({super.key});

  @override
  State<AdminBillingPage> createState() => _AdminBillingPageState();
}

class _AdminBillingPageState extends State<AdminBillingPage> {
  String _filter = 'Semua'; // Semua | Lunas | Belum Bayar | Jatuh Tempo
  int? _filterBulan; // 1-12, null = semua bulan
  int? _filterTahun; // null = semua tahun

  // UID satpam — diambil sekali saat halaman dibuka; dipakai untuk
  // menyaring tagihan agar hanya warga (role: user) yang tampil di billing.
  Set<String> _satpamUids = {};

  // Snapshot tagihan terakhir dari stream — dipakai oleh dialog Buat Tagihan
  // untuk mendeteksi tagihan terakhir milik user yang dipilih.
  // ignore: unused_field
  List<TagihanModel> _allTagihan = [];

  @override
  void initState() {
    super.initState();
    SeedTagihan.autoSeedIfNeeded();
    _loadSatpamUids();
  }

  Future<void> _loadSatpamUids() async {
    final uids = await AdminRepository.instance.fetchSatpamUids();
    if (!mounted) return;
    setState(() => _satpamUids = uids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activePage: AdminPage.billing),
          Expanded(
            child: Column(
              children: [
                const AdminTopBar(
                  searchHint: 'Cari nama warga atau unit...',
                ),
                Expanded(
                  child: StreamBuilder<List<TagihanModel>>(
                    stream: PaymentRepository.watchAllTagihan(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary));
                      }
                      if (snap.hasError) {
                        return CenterMessage(
                            icon: Icons.error_outline,
                            text: 'Gagal memuat: ${snap.error}');
                      }
                      // Tampilkan hanya tagihan warga (role: user).
                      final all = (snap.data ?? const <TagihanModel>[])
                          .where((t) => !_satpamUids.contains(t.userId))
                          .toList();
                      // Simpan snapshot untuk dipakai dialog Buat Tagihan.
                      _allTagihan = all;
                      return BillingContent(
                        all: all,
                        filter: _filter,
                        filterBulan: _filterBulan,
                        filterTahun: _filterTahun,
                        onFilter: (f) => setState(() => _filter = f),
                        onFilterBulan: (b) => setState(() => _filterBulan = b),
                        onFilterTahun: (t) => setState(() => _filterTahun = t),
                        onHubungi: (t) => showHubungiMenu(context, t),
                        onEditStatus: (t) => showEditStatusDialog(context, t),
                        onDetail: _showDetailPage,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Navigasi ke halaman detail pembayaran penghuni.
  void _showDetailPage(TagihanModel t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdminPaymentDetailPage(
        userId      : t.userId ?? '',
        namaResiden : t.namaResiden,
        blok        : t.blok,
        nomorUnit   : t.nomorUnit,
        nomorHp     : t.nomorHp,
      ),
    ));
  }
}
