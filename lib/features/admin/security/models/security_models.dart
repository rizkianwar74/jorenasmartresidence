import 'package:cloud_firestore/cloud_firestore.dart';

enum LogType { sos, bantuan, patroli }

class LogItem {
  const LogItem({
    required this.id,
    required this.type,
    required this.judul,
    required this.sub,
    required this.status,
    required this.waktu,
    this.rawData = const {},
  });

  final String               id;
  final LogType             type;
  final String               judul;
  final String               sub;
  final String               status;
  final DateTime             waktu;
  final Map<String, dynamic> rawData;

  List<String> get fotoUrls {
    // Coba fotoUrls (list) dulu
    final list = rawData['fotoUrls'];
    if (list is List) {
      final urls = list.whereType<String>().where((u) => u.isNotEmpty).toList();
      if (urls.isNotEmpty) return urls;
    }
    // Fallback ke fotoUrl (single string)
    final single = rawData['fotoUrl'] as String?;
    if (single != null && single.isNotEmpty) return [single];
    return [];
  }
}

class SatpamData {
  const SatpamData({
    required this.uid,
    required this.nama,
    this.lokasi = '-',
    this.isOnDuty = false,
  });

  final String uid;
  final String nama;
  final String lokasi;
  final bool isOnDuty;
}

class PatroliItem {
  const PatroliItem({
    required this.id,
    required this.waktu,
    required this.petugas,
    required this.lokasi,
    required this.catatan,
    required this.selesai,
    required this.rawData,
  });

  final String               id;
  final String               waktu;
  final String               petugas;
  final String               lokasi;
  final String               catatan;
  final bool                 selesai;
  final Map<String, dynamic> rawData;

  List<String> get fotoUrls {
    final single = rawData['fotoUrl'] as String?;
    if (single != null && single.isNotEmpty) return [single];
    final list = rawData['fotoUrls'];
    if (list is List) return list.whereType<String>().where((u) => u.isNotEmpty).toList();
    return [];
  }

  List<String> get quickTags {
    final tags = rawData['quickTags'];
    if (tags is List) return tags.whereType<String>().where((t) => t.isNotEmpty).toList();
    return [];
  }

  String get jamMulai   => rawData['jamMulai']   as String? ?? '-';
  String get jamSelesai => rawData['jamSelesai'] as String? ?? '-';

  factory PatroliItem.fromDoc(DocumentSnapshot doc) {
    final d          = doc.data() as Map<String, dynamic>;
    final jamMulai   = d['jamMulai']   as String? ?? '';
    final jamSelesai = d['jamSelesai'] as String? ?? '';
    final status     = d['status']     as String? ?? '';
    final selesai    = status == 'SELESAI' || jamSelesai.isNotEmpty;

    String waktu = jamMulai.isNotEmpty ? jamMulai : '--:--';
    if (jamSelesai.isNotEmpty) waktu = '$jamMulai – $jamSelesai';

    final keteranganRaw = d['keterangan'] as String? ?? '';
    final keterangan = keteranganRaw.isNotEmpty
        ? keteranganRaw
        : (() {
            final tags = d['quickTags'];
            if (tags is List) {
              final filled = tags.whereType<String>().where((t) => t.isNotEmpty).join(', ');
              return filled.isNotEmpty ? filled : '-';
            }
            return '-';
          })();

    return PatroliItem(
      id      : doc.id,
      waktu   : waktu,
      petugas : (d['namaSatpam']  as String? ?? '').isNotEmpty ? d['namaSatpam'] as String : '-',
      lokasi  : (d['blokPatroli'] as String? ?? '').isNotEmpty ? d['blokPatroli'] as String : '-',
      catatan : keterangan,
      selesai : selesai,
      rawData : d,
    );
  }
}
