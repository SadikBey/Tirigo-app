class JobModel {
  final String id;
  final String origin;
  final String destination;
  final double price;
  final String loadType;
  final String weight;
  final String truckType;
  final String companyName;
  final String status;

  JobModel({
    required this.id,
    required this.origin,
    required this.destination,
    required this.price,
    required this.loadType,
    required this.weight,
    required this.truckType,
    required this.companyName,
    required this.status,
  });

  // --- Hatanın Çözümü Olan Kısım ---
  factory JobModel.fromMap(Map<String, dynamic> map, String documentId) {
    return JobModel(
      id: documentId,
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      // Firebase'den gelen sayı double veya int olabilir, bu yüzden .toDouble() güvenlidir
      price: (map['price'] ?? 0).toDouble(), 
      loadType: map['loadType'] ?? '',
      weight: map['weight'] ?? '',
      truckType: map['truckType'] ?? '',
      companyName: map['companyName'] ?? 'Anonim Firma',
      status: map['status'] ?? 'open',
    );
  }

  // Veritabanına veri gönderirken kolaylık sağlar (Opsiyonel)
  Map<String, dynamic> toMap() {
    return {
      'origin': origin,
      'destination': destination,
      'price': price,
      'loadType': loadType,
      'weight': weight,
      'truckType': truckType,
      'companyName': companyName,
      'status': status,
    };
  }
}