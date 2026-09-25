import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/delivery_provider.dart';
import '../models/timeline.dart';

class CustomerDeliveryTrackingScreen extends ConsumerStatefulWidget {
  final int deliveryId;

  const CustomerDeliveryTrackingScreen({Key? key, required this.deliveryId}) : super(key: key);

  @override
  ConsumerState<CustomerDeliveryTrackingScreen> createState() => _CustomerDeliveryTrackingScreenState();
}

class _CustomerDeliveryTrackingScreenState extends ConsumerState<CustomerDeliveryTrackingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      ref.invalidate(deliveryDetailsProvider(widget.deliveryId));
      ref.invalidate(deliveryTimelineProvider(widget.deliveryId));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    if (status == 'DELIVERED') return Colors.green;
    if (status == 'DELIVERY_FAILED') return Colors.red;
    if (status == 'ARRIVING') return Colors.teal;
    if (status == 'IN_TRANSIT') return Colors.orange;
    return Colors.blue.shade700;
  }

  String _getStatusLabel(String status) {
    if (status == 'ASSIGNED') return 'Order assigned';
    if (status == 'PICKED_UP') return 'Package picked up';
    if (status == 'IN_TRANSIT') return 'Driver started delivery';
    if (status == 'ARRIVING') return 'Arriving nearby';
    if (status == 'DELIVERED') return 'Delivered';
    return status.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(deliveryDetailsProvider(widget.deliveryId));
    final timelineAsync = ref.watch(deliveryTimelineProvider(widget.deliveryId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Delivery Timeline', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('Live', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
      body: detailsAsync.when(
        data: (delivery) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(deliveryDetailsProvider(widget.deliveryId));
              ref.invalidate(deliveryTimelineProvider(widget.deliveryId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderInfo(delivery),
                  const SizedBox(height: 16),
                  if (delivery.status != 'DELIVERED' && delivery.status != 'DELIVERY_FAILED') ...[
                    _buildETASection(delivery),
                    const SizedBox(height: 24),
                  ],
                  _buildTimelineCard(timelineAsync, delivery.status),
                  const SizedBox(height: 24),
                  _buildDestinationCard(delivery, ref.watch(authProvider).value),
                  const SizedBox(height: 24),
                  _buildSupportActionBox(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeaderInfo(delivery) {
    final statusColor = _getStatusColor(delivery.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2, color: Color(0xFF1E3A8A), size: 20),
            const SizedBox(width: 8),
            Text(
              'ORDER #${delivery.id}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.copy, color: Colors.grey, size: 16),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                _getStatusLabel(delivery.status),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('CARRIER SERVICE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        const Text('Standard Delivery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  Widget _buildETASection(delivery) {
    // For the demo, we estimate arrival 2 hours from now.
    // In a real app, this would be returned from a routing engine.
    final eta = DateTime.now().add(const Duration(hours: 2)).toLocal();
    final timeString = '${eta.hour > 12 ? eta.hour - 12 : (eta.hour == 0 ? 12 : eta.hour)}:${eta.minute.toString().padLeft(2, '0')} ${eta.hour >= 12 ? 'PM' : 'AM'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.shade100.withOpacity(0.5), shape: BoxShape.circle),
            child: const Icon(Icons.access_time_filled, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estimated Arrival', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(timeString, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(AsyncValue<List<Timeline>> timelineAsync, String currentStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.timeline, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text('Delivery Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(12)),
              child: timelineAsync.when(
                data: (t) => Text('${t.length} Events', style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.bold)),
                loading: () => const SizedBox(width: 20, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Text('Error', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        timelineAsync.when(
          data: (timeline) {
            if (timeline.isEmpty) return const Text('No updates yet.');
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeline.length,
              itemBuilder: (context, index) {
                final t = timeline[index];
                final isLast = index == timeline.length - 1;
                
                // Completed step styling
                Color dotColor = const Color(0xFF059669); // Green
                IconData? dotIcon = Icons.check;
                
                // Current step styling
                if (isLast && currentStatus != 'DELIVERED') {
                  dotColor = const Color(0xFF2563EB); // Blue
                  dotIcon = Icons.near_me;
                }
                
                // If delivered, the last step is also green check
                if (isLast && currentStatus == 'DELIVERED') {
                  dotColor = const Color(0xFF059669);
                  dotIcon = Icons.check;
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(dotIcon, color: Colors.white, size: 14),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 60,
                            color: const Color(0xFF059669), // Solid green line for completed
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: isLast && currentStatus != 'DELIVERED' ? const EdgeInsets.all(12) : null,
                        decoration: isLast && currentStatus != 'DELIVERED' 
                          ? BoxDecoration(color: const Color(0xFFF0F4FA), borderRadius: BorderRadius.circular(12))
                          : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getStatusLabel(t.status),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: isLast && currentStatus != 'DELIVERED' ? const Color(0xFF2563EB) : Colors.black87,
                                      ),
                                    ),
                                    if (isLast && currentStatus != 'DELIVERED') ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('CURRENT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ]
                                  ],
                                ),
                                Text(
                                  t.createdAt.toLocal().toString().split(' ')[1].substring(0, 5),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLast ? 'Driver is updating tracking information.' : 'Courier en route for regional delivery cycle.',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                            if (t.latitude != null && t.longitude != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${t.latitude}, ${t.longitude}',
                                    style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }

  Widget _buildDestinationCard(delivery, user) {
    final customerName = user?.name ?? 'Customer';
    final customerEmail = user?.email ?? 'Contact available on pickup';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_on_outlined, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('Destination & Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.verified_user, color: Colors.teal, size: 14),
                  SizedBox(width: 4),
                  Text('Verified', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                  child: const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recipient Contact', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(customerEmail, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                  child: const Icon(Icons.local_shipping_outlined, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Driver Assigned', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(delivery.driver?.name ?? 'Assigning driver...', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (delivery.driver?.email != null) 
                      Text(delivery.driver!.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                  child: const Icon(Icons.home_outlined, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Drop-off Address', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(delivery.deliveryAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportActionBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.support_agent, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF0F4FA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.black87),
              label: const Text('Report Delivery Issue', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
