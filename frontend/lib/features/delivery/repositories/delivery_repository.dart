import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../models/delivery.dart';
import '../models/location.dart';
import '../models/timeline.dart';

class DeliveryRepository {
  final ApiClient _apiClient = ApiClient();
  final String role;

  DeliveryRepository(this.role);

  String get _basePath => role == 'DRIVER' ? '/driver/deliveries' : '/deliveries';

  Future<List<Delivery>> getDeliveries() async {
    final response = await _apiClient.get(_basePath);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Delivery.fromJson(json)).toList();
    }
    throw Exception('Failed to load deliveries');
  }

  Future<Delivery> createDelivery(String pickup, String dropoff) async {
    final response = await _apiClient.post('/deliveries', body: {
      'pickup_address': pickup,
      'delivery_address': dropoff,
    });
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Delivery.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create delivery: ${response.body}');
  }

  Future<Delivery> getDelivery(int id) async {
    final response = await _apiClient.get('$_basePath/$id');
    if (response.statusCode == 200) {
      return Delivery.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load delivery');
  }

  Future<List<Timeline>> getTimeline(int deliveryId) async {
    final response = await _apiClient.get('/deliveries/$deliveryId/timeline');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Timeline.fromJson(json)).toList();
    }
    throw Exception('Failed to load timeline');
  }

  Future<Location?> getLocation(int deliveryId) async {
    final response = await _apiClient.get('/deliveries/$deliveryId/location');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null || data.isEmpty) return null;
      return Location.fromJson(data);
    }
    throw Exception('Failed to load location');
  }

  Future<Delivery> updateStatus(int deliveryId, String status, {double? lat, double? lng}) async {
    final Map<String, dynamic> body = {'status': status};
    if (lat != null) body['latitude'] = lat;
    if (lng != null) body['longitude'] = lng;
    final response = await _apiClient.post('/driver/deliveries/$deliveryId/status', body: body);
    if (response.statusCode == 200) {
      return Delivery.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update status: ${response.body}');
  }

  Future<void> updateLocation(int deliveryId, double lat, double lng) async {
    final response = await _apiClient.post('/driver/deliveries/$deliveryId/location', body: {'latitude': lat, 'longitude': lng});
    if (response.statusCode != 200) {
      throw Exception('Failed to update location: ${response.body}');
    }
  }

  Future<void> reportIssue(int deliveryId, String reason, String description) async {
    final response = await _apiClient.post('/driver/deliveries/$deliveryId/issues', body: {'reason': reason, 'description': description});
    if (response.statusCode != 200) {
      throw Exception('Failed to report issue: ${response.body}');
    }
  }
}
