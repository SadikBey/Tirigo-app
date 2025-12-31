import 'package:flutter/material.dart';
import '../data/mock_jobs.dart'; // Verileri buradan çekiyoruz

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Üç sekme: Aktif, Devam Eden, Tamamlanan
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B263B),
          title: const Text(
            'İşlerim / Tekliflerim',
            style: TextStyle(color: Colors.white),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFFF3722C), // Tirigo Turuncusu
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Tekliflerim'),
              Tab(text: 'Yoldakiler'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildJobTabList('Teklif'), // Henüz onay bekleyen teklifler
            _buildJobTabList('Yolda'), // Taşıma aşamasında olanlar
            _buildJobTabList('Geçmiş'), // Tamamlanan işler
          ],
        ),
      ),
    );
  }

  Widget _buildJobTabList(String type) {
    // Şimdilik mock veriyi kullanıyoruz, gerçekte burası filtrelenecek
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: dummyJobs.length,
      itemBuilder: (context, index) {
        final job = dummyJobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${job.origin} ➔ ${job.destination}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _statusBadge(type),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(job.loadType),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Teklif: ${job.price.toInt()} ₺',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    if (type == 'Teklif')
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Geri Çek',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (type == 'Yolda')
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Teslim Et',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Durum etiketleri için küçük yardımcı fonksiyon
  Widget _statusBadge(String type) {
    Color color;
    String text;
    if (type == 'Teklif') {
      color = Colors.orange;
      text = 'Beklemede';
    } else if (type == 'Yolda') {
      color = Colors.blue;
      text = 'Yük Taşıyor';
    } else {
      color = Colors.green;
      text = 'Tamamlandı';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
