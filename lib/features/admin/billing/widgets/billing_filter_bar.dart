import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';

// ── Filter chips (status) + filter periode (Bulan & Tahun) — satu baris ─────
class BillingFilterBar extends StatelessWidget {
  const BillingFilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.filterBulan,
    required this.filterTahun,
    required this.availableYears,
    required this.onFilterBulan,
    required this.onFilterTahun,
    required this.viewMode,
    required this.onViewMode,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final int? filterBulan;
  final int? filterTahun;
  final List<int> availableYears;
  final ValueChanged<int?> onFilterBulan;
  final ValueChanged<int?> onFilterTahun;
  final String viewMode;
  final ValueChanged<String> onViewMode;

  static const _options = ['Semua', 'Lunas', 'Belum Bayar', 'Jatuh Tempo'];

  bool get _periodeActive => filterBulan != null || filterTahun != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // ── View mode toggle (Per Warga / Per Tagihan) ──────────────────
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleBtn(
                  icon  : Icons.people_outline,
                  label : 'Per Warga',
                  active: viewMode == 'warga',
                  onTap : () => onViewMode('warga'),
                ),
                _ToggleBtn(
                  icon  : Icons.receipt_long_outlined,
                  label : 'Per Tagihan',
                  active: viewMode == 'tagihan',
                  onTap : () => onViewMode('tagihan'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Status chips ────────────────────────────────────────────────
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options.map((o) {
                final active = o == selected;
                return InkWell(
                  onTap: () => onSelect(o),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: active
                              ? AppColors.primary
                              : Colors.grey.shade300),
                    ),
                    child: Text(
                      o,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.textGrey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Filter periode — hanya tampil di mode Per Tagihan ───────────
          if (viewMode == 'tagihan') ...[
            const SizedBox(width: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _PeriodeDropdown(
                  value       : filterBulan,
                  hint        : 'Semua Bulan',
                  options     : List<int>.generate(12, (i) => i + 1),
                  labelBuilder: (m) => bulanPanjangList[m - 1],
                  onChanged   : onFilterBulan,
                ),
                _PeriodeDropdown(
                  value       : filterTahun,
                  hint        : 'Semua Tahun',
                  options     : availableYears,
                  labelBuilder: (y) => '$y',
                  onChanged   : onFilterTahun,
                ),
                if (_periodeActive)
                  TextButton.icon(
                    onPressed: () {
                      onFilterBulan(null);
                      onFilterTahun(null);
                    },
                    icon : const Icon(Icons.close, size: 14),
                    label: Text('Reset',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding    : const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Toggle button kecil di dalam BillingFilterBar
class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String   label;
  final bool     active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active
              ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: active ? AppColors.primary : AppColors.textGrey),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.primary : AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _PeriodeDropdown extends StatelessWidget {
  const _PeriodeDropdown({
    required this.value,
    required this.hint,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final int? value;
  final String hint;
  final List<int> options;
  final String Function(int) labelBuilder;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          hint: Text(hint,
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: AppColors.textGrey),
          isDense: true,
          style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(hint,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey)),
            ),
            ...options.map((o) => DropdownMenuItem<int?>(
                  value: o,
                  child: Text(labelBuilder(o),
                      style: GoogleFonts.inter(fontSize: 12)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
