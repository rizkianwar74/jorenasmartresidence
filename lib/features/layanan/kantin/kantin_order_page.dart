// lib/features/layanan/kantin/kantin_order_page.dart
//
// Halaman pemesanan kantin — digunakan saat kantin sudah beroperasi.
// Halaman kantin_page.dart (under construction) tetap ada dan masih digunakan
// dari layanan_page.dart. Ganti import di layanan_page.dart ke KantinOrderPage
// ketika kantin sudah siap dibuka.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model & konstanta
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem {
  const _MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.emoji,
  });
  final String id;
  final String name;
  final String category;
  final String description;
  final String emoji;
  final int price;
}

const _kCategories = ['Semua', 'Makanan', 'Minuman', 'Snack'];

const _kMenu = <_MenuItem>[
  // Makanan
  _MenuItem(id: 'm1', name: 'Nasi Goreng',   category: 'Makanan', price: 18000, description: 'Nasi goreng spesial telur & ayam',     emoji: '🍳'),
  _MenuItem(id: 'm2', name: 'Mie Goreng',    category: 'Makanan', price: 15000, description: 'Mie goreng dengan sayuran segar',       emoji: '🍜'),
  _MenuItem(id: 'm3', name: 'Nasi Uduk',     category: 'Makanan', price: 20000, description: 'Nasi uduk lengkap dengan lauk pauk',    emoji: '🍚'),
  _MenuItem(id: 'm4', name: 'Ayam Bakar',    category: 'Makanan', price: 25000, description: 'Ayam bakar bumbu kecap manis',          emoji: '🍗'),
  _MenuItem(id: 'm5', name: 'Gado-Gado',     category: 'Makanan', price: 15000, description: 'Gado-gado bumbu kacang spesial',        emoji: '🥗'),
  _MenuItem(id: 'm6', name: 'Soto Ayam',     category: 'Makanan', price: 18000, description: 'Soto ayam bening dengan perkedel',      emoji: '🍲'),
  // Minuman
  _MenuItem(id: 'd1', name: 'Es Teh Manis',  category: 'Minuman', price:  5000, description: 'Teh manis segar dingin',                emoji: '🧋'),
  _MenuItem(id: 'd2', name: 'Es Jeruk',      category: 'Minuman', price:  7000, description: 'Perasan jeruk asli segar',              emoji: '🍊'),
  _MenuItem(id: 'd3', name: 'Kopi Hitam',    category: 'Minuman', price:  6000, description: 'Kopi robusta pilihan',                  emoji: '☕'),
  _MenuItem(id: 'd4', name: 'Jus Alpukat',   category: 'Minuman', price: 12000, description: 'Jus alpukat creamy dengan susu',        emoji: '🥤'),
  _MenuItem(id: 'd5', name: 'Air Mineral',   category: 'Minuman', price:  3000, description: 'Air mineral 600ml',                     emoji: '💧'),
  _MenuItem(id: 'd6', name: 'Kopi Susu',     category: 'Minuman', price:  8000, description: 'Kopi susu gula aren',                   emoji: '🥛'),
  // Snack
  _MenuItem(id: 's1', name: 'Pisang Goreng', category: 'Snack',   price:  8000, description: 'Pisang goreng crispy isi 3',            emoji: '🍌'),
  _MenuItem(id: 's2', name: 'Mendoan',       category: 'Snack',   price:  6000, description: 'Tempe mendoan bumbu kencur',            emoji: '🥙'),
  _MenuItem(id: 's3', name: 'Singkong Goreng', category: 'Snack', price:  7000, description: 'Singkong goreng tabur garam',           emoji: '🍟'),
  _MenuItem(id: 's4', name: 'Bakwan Sayur',  category: 'Snack',   price:  5000, description: 'Bakwan sayur crispy isi 3',             emoji: '🥦'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _rupiah(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp ${buf.toString()}';
}

String _generateOrderId() {
  final now = DateTime.now();
  final rand = (Random().nextInt(9000) + 1000).toString();
  final ymd = '${now.year}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  return 'KNT$ymd$rand';
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

enum _Step { browse, checkout, confirmed }

class KantinOrderPage extends StatefulWidget {
  const KantinOrderPage({super.key});

  @override
  State<KantinOrderPage> createState() => _KantinOrderPageState();
}

class _KantinOrderPageState extends State<KantinOrderPage> {
  _Step _step = _Step.browse;
  String _selectedCategory = 'Semua';
  final Map<String, int> _cart = {}; // menuId → qty

  late final TextEditingController _namaCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _catatanCtrl;

  bool _isSubmitting = false;
  String _orderId = '';

  @override
  void initState() {
    super.initState();
    final user = AuthRepository.currentUser;
    final unit = [user?.blok, user?.nomorUnit]
        .where((e) => e != null && e.isNotEmpty)
        .join('-');
    _namaCtrl   = TextEditingController(text: user?.namaLengkap ?? '');
    _unitCtrl   = TextEditingController(text: unit);
    _catatanCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _unitCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  List<_MenuItem> get _filteredMenu => _selectedCategory == 'Semua'
      ? _kMenu
      : _kMenu.where((m) => m.category == _selectedCategory).toList();

  int get _totalItems  => _cart.values.fold(0, (a, b) => a + b);
  int get _totalPrice  => _cart.entries.fold(0, (acc, e) {
    final item = _kMenu.firstWhere((m) => m.id == e.key);
    return acc + item.price * e.value;
  });

  List<Map<String, dynamic>> get _cartItems => _cart.entries.map((e) {
    final item = _kMenu.firstWhere((m) => m.id == e.key);
    return <String, dynamic>{
      'id'   : item.id,
      'nama' : item.name,
      'harga': item.price,
      'qty'  : e.value,
    };
  }).toList();

  // ── Cart actions ───────────────────────────────────────────────────────────

  void _setQty(String id, int delta) {
    setState(() {
      final next = ((_cart[id] ?? 0) + delta).clamp(0, 99);
      if (next == 0) {
        _cart.remove(id);
      } else {
        _cart[id] = next;
      }
    });
  }

  // ── Submit order ───────────────────────────────────────────────────────────

  Future<void> _submitOrder() async {
    if (_namaCtrl.text.trim().isEmpty || _unitCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan blok/unit wajib diisi')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final orderId = _generateOrderId();
      await FirebaseFirestore.instance.collection('pesanankantin').add({
        'orderId'          : orderId,
        'uid'              : AuthRepository.currentUid ?? '',
        'namaUser'         : _namaCtrl.text.trim(),
        'blokUnit'         : _unitCtrl.text.trim(),
        'items'            : _cartItems,
        'totalHarga'       : _totalPrice,
        'metodePembayaran' : 'tunai',
        'catatan'          : _catatanCtrl.text.trim(),
        'status'           : 'pending',
        'createdAt'        : FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _orderId       = orderId;
        _step          = _Step.confirmed;
        _isSubmitting  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesanan: $e')),
      );
    }
  }

  void _resetOrder() => setState(() {
    _cart.clear();
    _catatanCtrl.clear();
    _step = _Step.browse;
  });

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.browse || _step == _Step.confirmed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == _Step.checkout) {
          setState(() => _step = _Step.browse);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildBody(context),
          ),
        ),
        bottomNavigationBar: _step == _Step.browse ? _buildCartBar(context) : null,
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context) {
    final titles = {
      _Step.browse   : 'Kantin',
      _Step.checkout : 'Konfirmasi Pesanan',
      _Step.confirmed: 'Pesanan Diterima',
    };
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppColors.textDark,
        onPressed: () {
          if (_step == _Step.checkout) {
            setState(() => _step = _Step.browse);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        titles[_step]!,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_step == _Step.browse && _totalItems > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.topRight,
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  color: AppColors.primary,
                  onPressed: () => setState(() => _step = _Step.checkout),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_totalItems',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  // ── Body router ─────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    switch (_step) {
      case _Step.browse:
        return _BrowseView(
          categories      : _kCategories,
          selectedCategory: _selectedCategory,
          filteredMenu    : _filteredMenu,
          cart            : _cart,
          onCategoryTap   : (c) => setState(() => _selectedCategory = c),
          onSetQty        : _setQty,
        );
      case _Step.checkout:
        return _CheckoutView(
          cartItems   : _cartItems,
          totalPrice  : _totalPrice,
          namaCtrl    : _namaCtrl,
          unitCtrl    : _unitCtrl,
          catatanCtrl : _catatanCtrl,
          isSubmitting: _isSubmitting,
          onSubmit    : _submitOrder,
        );
      case _Step.confirmed:
        return _ConfirmedView(
          orderId   : _orderId,
          cartItems : _cartItems,
          totalPrice: _totalPrice,
          onReset   : _resetOrder,
          onBack    : () => Navigator.pop(context),
        );
    }
  }

  // ── Cart bottom bar ────────────────────────────────────────────────────────

  Widget? _buildCartBar(BuildContext context) {
    if (_totalItems == 0) return null;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () => setState(() => _step = _Step.checkout),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            children: [
              // Item count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_totalItems item',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Lihat Pesanan',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                _rupiah(_totalPrice),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Browse screen
// ─────────────────────────────────────────────────────────────────────────────

class _BrowseView extends StatelessWidget {
  const _BrowseView({
    required this.categories,
    required this.selectedCategory,
    required this.filteredMenu,
    required this.cart,
    required this.onCategoryTap,
    required this.onSetQty,
  });

  final List<String> categories;
  final String selectedCategory;
  final List<_MenuItem> filteredMenu;
  final Map<String, int> cart;
  final ValueChanged<String> onCategoryTap;
  final void Function(String id, int delta) onSetQty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category chips ────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = categories[i];
              final selected = cat == selectedCategory;
              return GestureDetector(
                onTap: () => onCategoryTap(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.grey.shade200,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Menu grid ─────────────────────────────────────────────────
        Expanded(
          child: filteredMenu.isEmpty
              ? Center(
                  child: Text(
                    'Menu tidak tersedia',
                    style: GoogleFonts.inter(color: AppColors.textGrey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filteredMenu.length,
                  itemBuilder: (_, i) {
                    final item = filteredMenu[i];
                    return _MenuCard(
                      item    : item,
                      qty     : cart[item.id] ?? 0,
                      onSetQty: onSetQty,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Menu card ──────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.item,
    required this.qty,
    required this.onSetQty,
  });

  final _MenuItem item;
  final int qty;
  final void Function(String id, int delta) onSetQty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji illustration
          Container(
            width: double.infinity,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 46)),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      item.description,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textGrey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price + qty control
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _rupiah(item.price),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (qty == 0)
                        _AddButton(onTap: () => onSetQty(item.id, 1))
                      else
                        _QtyControl(
                          qty    : qty,
                          onDec  : () => onSetQty(item.id, -1),
                          onInc  : () => onSetQty(item.id,  1),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.add, size: 16, color: Colors.white),
    ),
  );
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({required this.qty, required this.onDec, required this.onInc});
  final int qty;
  final VoidCallback onDec, onInc;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onDec,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.remove, size: 14, color: AppColors.primary),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '$qty',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      GestureDetector(
        onTap: onInc,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.add, size: 14, color: Colors.white),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkout screen
// ─────────────────────────────────────────────────────────────────────────────

class _CheckoutView extends StatelessWidget {
  const _CheckoutView({
    required this.cartItems,
    required this.totalPrice,
    required this.namaCtrl,
    required this.unitCtrl,
    required this.catatanCtrl,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final List<Map<String, dynamic>> cartItems;
  final int totalPrice;
  final TextEditingController namaCtrl, unitCtrl, catatanCtrl;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order summary ────────────────────────────────────────────
          _SectionTitle('Ringkasan Pesanan'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ...cartItems.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        '${e['qty']}×',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e['nama'] as String,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                        ),
                      ),
                      Text(
                        _rupiah((e['harga'] as int) * (e['qty'] as int)),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                )),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      Text(
                        _rupiah(totalPrice),
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Data pemesan ─────────────────────────────────────────────
          _SectionTitle('Data Pemesan'),
          const SizedBox(height: 8),
          _InputField(ctrl: namaCtrl,    label: 'Nama Lengkap',      icon: Icons.person_outline),
          const SizedBox(height: 10),
          _InputField(ctrl: unitCtrl,    label: 'Blok / Unit',       icon: Icons.home_outlined),
          const SizedBox(height: 10),
          _InputField(ctrl: catatanCtrl, label: 'Catatan (opsional)', icon: Icons.notes_outlined, maxLines: 2),
          const SizedBox(height: 20),

          // ── Metode pembayaran ────────────────────────────────────────
          _SectionTitle('Metode Pembayaran'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payments_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tunai / Cash', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      Text('Bayar saat pengambilan di kasir', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Submit ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      'Konfirmasi Pesanan',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order confirmed screen
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmedView extends StatelessWidget {
  const _ConfirmedView({
    required this.orderId,
    required this.cartItems,
    required this.totalPrice,
    required this.onReset,
    required this.onBack,
  });

  final String orderId;
  final List<Map<String, dynamic>> cartItems;
  final int totalPrice;
  final VoidCallback onReset, onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24, 32, 24, MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        children: [
          // Success icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 54),
          ),
          const SizedBox(height: 16),
          Text(
            'Pesanan Berhasil!',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Pesanan kamu sudah kami terima',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),

          // Order ID card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text('No. Pesanan', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 4),
                Text(
                  orderId,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Payment notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bayar secara tunai saat mengambil pesanan di kasir kantin.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detail pesanan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detail Pesanan', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 10),
                ...cartItems.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        '${e['qty']}×  ',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(e['nama'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark)),
                      ),
                      Text(
                        _rupiah((e['harga'] as int) * (e['qty'] as int)),
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
                      ),
                    ],
                  ),
                )),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Text(_rupiah(totalPrice), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Pesan Lagi', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: AppColors.textDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Kembali ke Layanan', style: GoogleFonts.inter(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
  );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    style: GoogleFonts.inter(fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textGrey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );
}
