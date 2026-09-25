import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/delivery.dart';
import '../models/location.dart';
import '../models/timeline.dart';
import '../repositories/delivery_repository.dart';

final deliveryRepositoryProvider = Provider((ref) {
  final user = ref.watch(authProvider).value;
  return DeliveryRepository(user?.role ?? 'CUSTOMER');
});

final deliveriesProvider = FutureProvider<List<Delivery>>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return repository.getDeliveries();
});

final deliveryDetailsProvider = FutureProvider.family<Delivery, int>((ref, id) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return repository.getDelivery(id);
});

final deliveryTimelineProvider = FutureProvider.family<List<Timeline>, int>((ref, id) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return repository.getTimeline(id);
});

final deliveryLocationProvider = FutureProvider.family<Location?, int>((ref, id) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return repository.getLocation(id);
});

final deliveryNotifierProvider = AsyncNotifierProvider<DeliveryNotifier, void>(() {
  return DeliveryNotifier();
});

class DeliveryNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createDelivery(String pickup, String dropoff) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(deliveryRepositoryProvider).createDelivery(pickup, dropoff);
      ref.invalidate(deliveriesProvider);
    });
  }

  Future<void> updateStatus(int id, String status, {double? lat, double? lng}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(deliveryRepositoryProvider).updateStatus(id, status, lat: lat, lng: lng);
      ref.invalidate(deliveriesProvider);
      ref.invalidate(deliveryDetailsProvider(id));
      ref.invalidate(deliveryTimelineProvider(id));
    });
  }

  Future<void> updateLocation(int id, double lat, double lng) async {
    try {
      await ref.read(deliveryRepositoryProvider).updateLocation(id, lat, lng);
    } catch (e) {
      print('Location update failed: $e');
    }
  }

  Future<void> reportIssue(int id, String reason, String description) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(deliveryRepositoryProvider).reportIssue(id, reason, description);
      ref.invalidate(deliveriesProvider);
      ref.invalidate(deliveryDetailsProvider(id));
    });
  }
}
