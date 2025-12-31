import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        title: const Text('Mesajlarım', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.separated(
        itemCount: 5, // Örnek olması için 5 konuşma
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Stack(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.business, color: Colors.white),
                ),
                if (index == 0) // İlk mesaj okunmamış gibi gösterelim
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3722C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              'Lojistik Firması ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Teklifiniz hakkında bir sorum var...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('14:20', style: TextStyle(fontSize: 12, color: Colors.grey)),
                if (index == 0)
                  const Icon(Icons.push_pin, size: 16, color: Colors.grey),
              ],
            ),
            onTap: () {
              // Sohbet detayına gitme işlevi buraya gelecek
            },
          );
        },
      ),
    );
  }
}