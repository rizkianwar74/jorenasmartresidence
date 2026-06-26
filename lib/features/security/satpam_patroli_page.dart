import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/onesignal_service.dart';
import '../../shared/widgets/satpam_bottom_nav.dart';
import 'data/security_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State enum
// ─────────────────────────────────────────────────────────────────────────────

enum _PatroliState { loading, idle, active }

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class SatpamPatroliPage extends StatefulWidget {
  const SatpamPatroliPage({super.key});

  @override
  State<SatpamPatroliPage> createState() => _SatpamPatroliPageState();
}

class _SatpamPatroliPageState extends State<SatpamPatroliPage> {
  static const double _contentMaxWidth = 600.0;
  static const int _maxFotos = 4;

  static const _quickTags = [
    'Aman & Terkendali',
    'Pengecekan Rutin',
    'Insiden Terdeteksi',
  ];

  // ── State ──────────────────────────────────────────────────────────────────
  _PatroliState _state = _PatroliState.loading;

  // Data patroli aktif
  String? _activeDocId;
  String  _activeJamMulai = '';
  String  _activeBlok     = '';

  // Form: mulai patroli
  final _blokMulaiController = TextEditingController();

  // Form: selesai patroli
  final _keteranganController = TextEditingController();
  final Set<String>   _selectedTags = {};
  final List<Uint8List> _fotos      = [];
  final _picker = ImagePicker();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _checkActivePatroli();
  }

  @override
  void dispose() {
    _blokMulaiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  // ── Cek apakah satpam ini punya patroli AKTIF ─────────────────────────────
  Future<void> _checkActivePatroli() async {
    final uid = SecurityRepository.instance.currentSatpamUid;
    try {
      final snap = await SecurityRepository.instance.patroliAktifByUid(uid);

      if (!mounted) return;

      if (snap.docs.isEmpty) {
        setState(() => _state = _PatroliState.idle);
      } else {
        final doc = snap.docs.first;
        final d   = doc.data();
        setState(() {
          _state          = _PatroliState.active;
          _activeDocId    = doc.id;
          _activeJamMulai = d['jamMulai']   as String? ?? '';
          _activeBlok     = d['blokPatroli'] as String? ?? '';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = _PatroliState.idle);
    }
  }

  // ── Jam sekarang sebagai string HH:mm ─────────────────────────────────────
  String _nowHHmm() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ── MULAI PATROLI — buat dokumen AKTIF ────────────────────────────────────
  Future<void> _mulaiPatroli() async {
    final blok = _blokMulaiController.text.trim();
    if (blok.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
        'Isi blok / area patroli terlebih dahulu.', isError: true));
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo       = SecurityRepository.instance;
      final satpamUid  = repo.currentSatpamUid;
      final namaSatpam = repo.satpamDisplayName;
      final jamMulai   = _nowHHmm();

      final docRef = await repo.mulaiPatroli({
        'satpamUid'   : satpamUid,
        'namaSatpam'  : namaSatpam,
        'blokPatroli' : blok,
        'jamMulai'    : jamMulai,
        'jamSelesai'  : '',
        'keterangan'  : '',
        'quickTags'   : <String>[],
        'fotoUrls'    : <String>[],
        'status'      : 'AKTIF',
        'createdAt'   : FieldValue.serverTimestamp(),
        'updatedAt'   : FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _state          = _PatroliState.active;
        _activeDocId    = docRef.id;
        _activeJamMulai = jamMulai;
        _activeBlok     = blok;
        _saving         = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('Patroli dimulai pukul $jamMulai. Tetap waspada!'));

      // Kirim push ke semua warga (fire-and-forget).
      OneSignalService.instance.sendPatroliUpdate(
        mulai      : true,
        blok       : blok,
        namaSatpam : namaSatpam,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('Gagal memulai patroli: $e', isError: true));
    }
  }

  // ── SELESAI PATROLI — update dokumen ke SELESAI ───────────────────────────
  Future<void> _selesaiPatroli() async {
    if (_activeDocId == null) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final jamSelesai = _nowHHmm();
      final repo       = SecurityRepository.instance;
      final satpamUid  = repo.currentSatpamUid;

      // Upload foto jika ada
      List<String> fotoUrls = [];
      if (_fotos.isNotEmpty) {
        fotoUrls = await repo.uploadFotoPatroli(satpamUid, _activeDocId!, _fotos);
      }

      await repo.selesaiPatroli(_activeDocId!, {
        'status'     : 'SELESAI',
        'jamSelesai' : jamSelesai,
        'keterangan' : _keteranganController.text.trim(),
        'quickTags'  : _selectedTags.toList(),
        if (fotoUrls.isNotEmpty) 'fotoUrls': fotoUrls,
        'updatedAt'  : FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Reset semua state
      _keteranganController.clear();
      _blokMulaiController.clear();
      setState(() {
        _state          = _PatroliState.idle;
        _activeDocId    = null;
        _activeJamMulai = '';
        _activeBlok     = '';
        _selectedTags.clear();
        _fotos.clear();
        _saving         = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('Patroli selesai pukul $jamSelesai. Laporan tersimpan.'));

      // Kirim push ke semua warga (fire-and-forget).
      final namaSatpam = SecurityRepository.instance.satpamDisplayName;
      OneSignalService.instance.sendPatroliUpdate(
        mulai      : false,
        blok       : _activeBlok.isNotEmpty ? _activeBlok : '-',
        namaSatpam : namaSatpam,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('Gagal menyimpan laporan: $e', isError: true));
    }
  }

  // Catatan: unggah foto patroli kini ditangani oleh
  // SecurityRepository.uploadFotoPatroli().

  // ── Pilih foto dari galeri ─────────────────────────────────────────────────
  Future<void> _pickFoto() async {
    if (_fotos.length >= _maxFotos) return;
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() => _fotos.add(bytes));
  }

  void _removeFoto(int i) => setState(() => _fotos.removeAt(i));

  // ── Helper snackbar ────────────────────────────────────────────────────────
  SnackBar _snackBar(String msg, {bool isError = false}) => SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor:
            isError ? Colors.red.shade600 : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Column(
                  children: [
                    _TopBar(),
                    Expanded(
                      child: switch (_state) {
                        _PatroliState.loading => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        _PatroliState.idle   => _buildIdle(),
                        _PatroliState.active => _buildActive(),
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Nav selalu tampil
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SatpamBottomNav(currentIndex: 1),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATE: IDLE — belum ada patroli aktif
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildIdle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Tidak Ada Patroli Aktif', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              )),
            ]),
          ),

          const SizedBox(height: 20),

          Text('Mulai Patroli Baru', style: GoogleFonts.inter(
            fontSize: 26, fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          )),
          const SizedBox(height: 4),
          Text('Tentukan area patroli, lalu tekan mulai.', style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF94A3B8),
          )),

          const SizedBox(height: 28),

          // Ilustrasi
          Center(
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined, size: 56, color: AppColors.primary),
            ),
          ),

          const SizedBox(height: 28),

          // Card: input blok
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(icon: Icons.grid_view_outlined, label: 'AREA / BLOK PATROLI'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _blokMulaiController,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF0D1B2A)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      hintText: 'Contoh: Blok A, B, C',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFFB0BEC5)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Waktu mulai akan dicatat otomatis saat tombol ditekan.',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Tombol mulai
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _mulaiPatroli,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
              label: Text(
                _saving ? 'Memulai...' : 'MULAI PATROLI',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATE: ACTIVE — patroli sedang berjalan
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildActive() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner patroli aktif
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patroli Sedang Berjalan', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
                  const SizedBox(height: 2),
                  Text('Mulai pukul $_activeJamMulai  ·  $_activeBlok',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white70)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('AKTIF', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 0.5,
                )),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          Text('Laporan Patroli', style: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          )),
          const SizedBox(height: 4),
          Text('Isi keterangan dan temuan selama patroli berlangsung.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF94A3B8))),

          const SizedBox(height: 20),

          // Card keterangan + foto
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + tombol foto
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CardHeader(icon: Icons.menu, label: 'KETERANGAN PATROLI'),
                    GestureDetector(
                      onTap: _fotos.length >= _maxFotos ? null : _pickFoto,
                      child: Row(children: [
                        Icon(Icons.camera_alt_outlined, size: 16,
                            color: _fotos.length >= _maxFotos
                                ? Colors.grey
                                : AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _fotos.length >= _maxFotos
                              ? 'Maks $_maxFotos foto'
                              : 'Foto (${_fotos.length}/$_maxFotos)',
                          style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: _fotos.length >= _maxFotos
                                ? Colors.grey
                                : AppColors.primary,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Text area
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _keteranganController,
                    maxLines: 5,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF0D1B2A)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      hintText:
                          'Tuliskan temuan atau rutinitas patroli... '
                          '(Contoh: Tidak ada aktivitas mencurigakan, '
                          'lampu lorong menyala normal)',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFFB0BEC5),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                // Preview foto
                if (_fotos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _fotos.length +
                          (_fotos.length < _maxFotos ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        if (i == _fotos.length) {
                          return GestureDetector(
                            onTap: _pickFoto,
                            child: Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.grey.shade300),
                              ),
                              child: Icon(Icons.add_photo_alternate_outlined,
                                  size: 28, color: AppColors.primary),
                            ),
                          );
                        }
                        return Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(_fotos[i],
                                width: 90, height: 90, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => _removeFoto(i),
                              child: Container(
                                width: 22, height: 22,
                                decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ]);
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Quick tags
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _quickTags.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () => setState(() =>
                          selected ? _selectedTags.remove(tag)
                                   : _selectedTags.add(tag)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(tag, style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF0D1B2A),
                        )),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tombol selesai
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _selesaiPatroli,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 22),
              label: Text(
                _saving ? 'Menyimpan...' : 'SELESAI PATROLI',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Text(
              'Waktu selesai akan dicatat otomatis saat tombol ditekan.',
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20, right: 20, bottom: 12,
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(width: 12),
        Icon(Icons.security, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text('SECURITY OPS', style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.bold,
          color: AppColors.primary, letterSpacing: 0.5,
        )),
        const Spacer(),
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200)),
          child: const Icon(Icons.person_outline,
              size: 20, color: Color(0xFF0D1B2A)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8), letterSpacing: 0.5,
      )),
    ]);
  }
}
