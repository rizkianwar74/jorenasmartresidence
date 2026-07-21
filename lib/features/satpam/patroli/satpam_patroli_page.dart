import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/onesignal_service.dart';
import '../widgets/satpam_bottom_nav.dart';
import '../../security/data/security_repository.dart';
import 'widgets/patroli_top_bar.dart';
import 'widgets/patroli_idle_view.dart';
import 'widgets/patroli_active_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Halaman Patroli Satpam — mulai/selesai patroli.
//
// View untuk masing-masing state (idle/active) serta widget pendukung
// (top bar, section card, card header) dipecah ke widgets/ agar file ini
// fokus pada state management saja.
// ─────────────────────────────────────────────────────────────────────────────

enum _PatroliState { loading, idle, active }

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
      OneSignalService.instance.sendPatroliUpdate(docId: docRef.id);
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
      // Ditangkap sebelum state di-reset di bawah — _activeDocId jadi null
      // sesudah setState, padahal masih dibutuhkan untuk mengirim notifikasi.
      final patroliId  = _activeDocId!;

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
      OneSignalService.instance.sendPatroliUpdate(docId: patroliId);
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

  void _toggleTag(String tag) => setState(() {
        if (_selectedTags.contains(tag)) {
          _selectedTags.remove(tag);
        } else {
          _selectedTags.add(tag);
        }
      });

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
                    const PatroliTopBar(),
                    Expanded(
                      child: switch (_state) {
                        _PatroliState.loading => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        _PatroliState.idle => PatroliIdleView(
                            blokMulaiController: _blokMulaiController,
                            saving: _saving,
                            onMulai: _mulaiPatroli,
                          ),
                        _PatroliState.active => PatroliActiveView(
                            activeJamMulai: _activeJamMulai,
                            activeBlok: _activeBlok,
                            keteranganController: _keteranganController,
                            fotos: _fotos,
                            maxFotos: _maxFotos,
                            quickTags: _quickTags,
                            selectedTags: _selectedTags,
                            saving: _saving,
                            onPickFoto: _pickFoto,
                            onRemoveFoto: _removeFoto,
                            onToggleTag: _toggleTag,
                            onSelesai: _selesaiPatroli,
                          ),
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
}
