import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/delivery_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'driver_delivery_details_screen.dart';

class DriverDeliveryListScreen extends ConsumerWidget {
  const DriverDeliveryListScreen({Key? key}) : super(key: key);

  Color _getStatusColor(String status) {
    if (status == 'DELIVERED') return const Color(0xFF059669); // Green
    if (status == 'DELIVERY_FAILED') return Colors.red;
    if (status == 'IN_TRANSIT') return const Color(0xFFD97706); // Orange
    if (status == 'PICKED_UP') return const Color(0xFF2563EB); // Blue
    return const Color(0xFF4F46E5); // Indigo
  }

  String _getStatusLabel(String status) {
    return status.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(deliveriesProvider);
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Driver Dashboard', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 20)),
            Text('Welcome, ${user?.name ?? 'Driver'}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.black87, size: 20),
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ),
        ],
      ),
      body: deliveriesAsync.when(
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.check_circle_outline, size: 48, color: Colors.blue.shade300),
                  ),
                  const SizedBox(height: 24),
                  const Text('All caught up!', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('No deliveries assigned currently', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(deliveriesProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: deliveries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final delivery = deliveries[index];
                final statusColor = _getStatusColor(delivery.status);
                
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverDeliveryDetailsScreen(deliveryId: delivery.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F4FA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Order #${delivery.id}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusLabel(delivery.status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Column(
                                children: [
                                  Icon(Icons.storefront, size: 16, color: Colors.grey.shade400),
                                  Container(width: 2, height: 16, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(vertical: 4)),
                                  Icon(Icons.home, size: 16, color: const Color(0xFF2563EB)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      delivery.pickupAddress,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      delivery.deliveryAddress,
                                      style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                          const Divider(height: 32, color: Color(0xFFF3F4F6)),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFF0F4FA),
                                child: const Icon(Icons.person_outline, size: 16, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                delivery.customer != null ? 'Customer: ${delivery.customer!.name}' : 'Unknown Customer',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
