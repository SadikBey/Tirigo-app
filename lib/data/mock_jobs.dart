import '../models/job_model.dart';

List<JobModel> dummyJobs = [
  JobModel(
    id: '1',
    origin: 'İSTANBUL',
    destination: 'İZMİR',
    loadType: 'Paletli Gıda Malzemesi',
    weight: '15 Ton',
    truckType: 'Tenteli Tır (13.6m)',
    price: 5500.0,
    companyName: 'ABC Lojistik',
    companyRate: 4.6,
    date: DateTime.now().add(Duration(days: 1)),
  ),
  JobModel(
    id: '2',
    origin: 'ANKARA',
    destination: 'ADANA',
    loadType: 'Dondurulmuş Gıda',
    weight: '10 Ton',
    truckType: 'Frigo Kamyon',
    price: 4200.0,
    companyName: 'Mega Nakliyat',
    companyRate: 4.9,
    date: DateTime.now().add(Duration(days: 2)),
  ),
];