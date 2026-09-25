import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/delivery_provider.dart';

class DriverDeliveryDetailsScreen extends ConsumerWidget {
  final int deliveryId;

  const DriverDeliveryDetailsScreen({Key? key, required this.deliveryId}) : super(key: key);

  int _getStatusIndex(String status) {
    const list = ['ASSIGNED', 'PICKED_UP', 'IN_TRANSIT', 'ARRIVING', 'DELIVERED'];
    return list.indexOf(status);
  }

  void _showUpdateStatusDialog(BuildContext context, WidgetRef ref, String currentStatus) {
    final statuses = ['ASSIGNED', 'PICKED_UP', 'IN_TRANSIT', 'ARRIVING', 'DELIVERED', 'DELIVERY_FAILED'];
    final currentIndex = _getStatusIndex(currentStatus);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...statuses.map((s) {
                final isCurrent = s == currentStatus;
                
                // Determine if this status option should be enabled
                bool isEnabled = false;
                if (s == 'DELIVERY_FAILED') {
                   isEnabled = currentStatus != 'DELIVERED' && currentStatus != 'DELIVERY_FAILED';
                } else {
                   final targetIndex = _getStatusIndex(s);
                   isEnabled = targetIndex > currentIndex && currentIndex != -1;
                }

                return ListTile(
                  title: Text(
                    s.replaceAll('_', ' '), 
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isEnabled || isCurrent ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                  trailing: isCurrent ? const Icon(Icons.check, color: Color(0xFF6C63FF)) : null,
                  enabled: isEnabled,
                  onTap: () {
                    // Automatically pass the driver's current coordinates when updating status
                    ref.read(deliveryNotifierProvider.notifier).updateStatus(deliveryId, s, lat: 15.1234, lng: 73.5678);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showReportIssueDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Report Issue', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (e.g. Traffic, Accident)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(deliveryNotifierProvider.notifier).reportIssue(
                    deliveryId,
                    reasonController.text,
                    descController.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return Colors.green;
      case 'DELIVERY_FAILED':
        return Colors.red;
      case 'ARRIVING':
        return Colors.teal;
      case 'IN_TRANSIT':
        return Colors.orange;
      case 'PICKED_UP':
        return Colors.blue;
      default:
        return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for any backend errors during state changes and show a Snackar
    ref.listen(deliveryNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final detailsAsync = ref.watch(deliveryDetailsProvider(deliveryId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Order #$deliveryId Details', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: detailsAsync.when(
        data: (delivery) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Current Status', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(delivery.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                delivery.status.replaceAll('_', ' '),
                                style: TextStyle(
                                  color: _getStatusColor(delivery.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        const Text('Customer Info & Destination', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFF0F4FA), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.person_outline, color: Color(0xFF2563EB), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(delivery.customer?.name ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                if (delivery.customer?.email != null)
                                  Text(delivery.customer!.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFF0F4FA), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.storefront, color: Color(0xFF2563EB), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pickup Address', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(delivery.pickupAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFF0F4FA), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.home_outlined, color: Color(0xFF2563EB), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Delivery Address', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(delivery.deliveryAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showUpdateStatusDialog(context, ref, delivery.status),
                  icon: const Icon(Icons.edit_note, color: Colors.white),
                  label: const Text('Update Status', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                  ),
                  onPressed: () {
                    ref.read(deliveryNotifierProvider.notifier).updateLocation(deliveryId, 15.1234, 73.5678);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location updated!')));
                  },
                  icon: const Icon(Icons.my_location, color: Color(0xFF6C63FF)),
                  label: const Text('Send Current Location', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: () => _showReportIssueDialog(context, ref),
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  label: const Text('Report an Issue', style: TextStyle(color: Colors.red, fontSize: 16)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
