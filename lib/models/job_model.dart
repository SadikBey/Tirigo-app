class JobModel {
  final String id;
  final String userId; 
  final String origin;
  final String destination;
  final double price;
  final String loadType;
  final String weight;
  final String truckType;
  final String companyName;
  final double companyRate;
  final DateTime date;
  final String status;
  // --- YENİ ALAN ---
  final String? acceptedDriverId; 

  JobModel({
    required this.id,
    required this.userId,
    required this.origin,
    required this.destination,
    required this.price,
    required this.loadType,
    required this.weight,
    required this.truckType,
    required this.companyName,
    required this.companyRate,
    required this.date,
    required this.status,
    this.acceptedDriverId, // Constructor'a eklendi
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String documentId) {
    return JobModel(
      id: documentId,
      userId: map['userId'] ?? '',
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      loadType: map['loadType'] ?? '',
      weight: map['weight'] ?? '',
      truckType: map['truckType'] ?? '',
      companyName: map['companyName'] ?? 'Tirigo Üyesi',
      companyRate: (map['companyRate'] ?? 0.0).toDouble(),
      date: map['date'] != null ? (map['date'] as dynamic).toDate() : DateTime.now(),
      status: map['status'] ?? 'open',
      // Firestore'daki veriyi modele aktarıyoruz
      acceptedDriverId: map['acceptedDriverId'], 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'origin': origin,
      'destination': destination,
      'price': price,
      'loadType': loadType,
      'weight': weight,
      'truckType': truckType,
      'companyName': companyName,
      'companyRate': companyRate,
      'date': date,
      'status': status,
      'acceptedDriverId': acceptedDriverId, // toMap'e de ekledik
    };
  }
}