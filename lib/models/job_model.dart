class JobModel {
  final String id;
  final String origin;
  final String destination;
  final double price;
  final String loadType;
  final String weight;
  final String truckType;
  final String companyName;
  final double companyRate; // Eklendi
  final DateTime date;      // Eklendi
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
    required this.companyRate, // Eklendi
    required this.date,        // Eklendi
    required this.status,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String documentId) {
    return JobModel(
      id: documentId,
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      loadType: map['loadType'] ?? '',
      weight: map['weight'] ?? '',
      truckType: map['truckType'] ?? '',
      companyName: map['companyName'] ?? 'Anonim Firma',
      companyRate: (map['companyRate'] ?? 0.0).toDouble(), // Eklendi
      date: map['date'] != null 
          ? (map['date'] as dynamic).toDate() // Firebase Timestamp'i DateTime'a çevirir
          : DateTime.now(), 
      status: map['status'] ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'origin': origin,
      'destination': destination,
      'price': price,
      'loadType': loadType,
      'weight': weight,
      'truckType': truckType,
      'companyName': companyName,
      'companyRate': companyRate, // Eklendi
      'date': date,               // Eklendi
      'status': status,
    };
  }
}