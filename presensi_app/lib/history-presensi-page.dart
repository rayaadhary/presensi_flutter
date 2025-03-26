import 'package:flutter/material.dart';
import 'package:presensi_app/models/home-response.dart';

class HistoryPresensiPage extends StatelessWidget {
  final List<Datum> riwayat;

  const HistoryPresensiPage({Key? key, required this.riwayat})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Presensi"),
        automaticallyImplyLeading: false, // Menghilangkan tombol back
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              riwayat.isEmpty
                  ? const Center(
                    child: Text(
                      "Belum ada riwayat presensi",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  : ListView.builder(
                    itemCount: riwayat.length,
                    itemBuilder:
                        (context, index) => Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  riwayat[index].tanggal.isNotEmpty
                                      ? riwayat[index].tanggal
                                      : '-',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildPresensiColumn(
                                      "MASUK",
                                      riwayat[index].masuk,
                                    ),
                                    _buildPresensiColumn(
                                      "PULANG",
                                      riwayat[index].pulang,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
        ),
      ),
    );
  }

  Widget _buildPresensiColumn(String label, String waktu) {
    return Column(
      children: [
        Text(
          waktu.isNotEmpty ? waktu : '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
