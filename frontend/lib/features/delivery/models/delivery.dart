import '../../auth/models/user.dart';

class Delivery {
  final int id;
  final String status;
  final String pickupAddress;
  final String deliveryAddress;
  final DateTime? estimatedArrivalAt;
  final User? driver;
  final User? customer;

  Delivery({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.estimatedArrivalAt,
    this.driver,
    this.customer,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'],
      status: json['status'],
      pickupAddress: json['pickup_address'],
      deliveryAddress: json['delivery_address'],
      estimatedArrivalAt: json['estimated_arrival_at'] != null 
          ? DateTime.parse(json['estimated_arrival_at']) 
          : null,
      driver: json['driver'] != null ? User.fromJson(json['driver']) : null,
      customer: json['customer'] != null ? User.fromJson(json['customer']) : null,
    );
  }
}
