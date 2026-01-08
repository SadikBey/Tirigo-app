import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:intl/intl.dart';



class NotificationsScreen extends StatelessWidget {

  const NotificationsScreen({super.key});



  @override

  Widget build(BuildContext context) {

    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";



    return Scaffold(

      backgroundColor: const Color(0xFFF8F9FD),

      appBar: AppBar(

        title: const Text("Bildirimler", style: TextStyle(color: Colors.white, fontSize: 18)),

        backgroundColor: const Color(0xFF1B263B),

        iconTheme: const IconThemeData(color: Colors.white),

      ),

      body: StreamBuilder<QuerySnapshot>(

        // Sadece giriş yapan kullanıcıya (receiverId) ait bildirimleri çekiyoruz

        stream: FirebaseFirestore.instance

    .collection('notifications')

    .where('receiverId', isEqualTo: currentUid) // Önce filtre

    .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));

          if (snapshot.connectionState == ConnectionState.waiting) {

            return const Center(child: CircularProgressIndicator());

          }

          if (snapshot.data!.docs.isEmpty) {

            return _buildEmptyState();

          }



          return ListView.builder(

            padding: const EdgeInsets.all(10),

            itemCount: snapshot.data!.docs.length,

            itemBuilder: (context, index) {

              var notification = snapshot.data!.docs[index];

              var data = notification.data() as Map<String, dynamic>;

             

              return _buildNotificationCard(data);

            },

          );

        },

      ),

    );

  }



  Widget _buildNotificationCard(Map<String, dynamic> data) {

    DateTime? date = (data['createdAt'] as Timestamp?)?.toDate();

    String formattedTime = date != null ? DateFormat('HH:mm').format(date) : "";



    return Container(

      margin: const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(15),

        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],

      ),

      child: ListTile(

        leading: CircleAvatar(

          backgroundColor: const Color(0xFFF3722C).withValues(alpha: 0.1),

          child: const Icon(Icons.notifications_active, color: Color(0xFFF3722C)),

        ),

        title: Text(data['title'] ?? "Bildirim", style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Text(data['message'] ?? ""),

        trailing: Text(formattedTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),

      ),

    );

  }



  Widget _buildEmptyState() {

    return Center(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),

          const SizedBox(height: 20),

          const Text("Henüz bir bildiriminiz yok", style: TextStyle(color: Colors.grey)),

        ],

      ),

    );

  }

}