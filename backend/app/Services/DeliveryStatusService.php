<?php

namespace App\Services;

use App\Models\Delivery;
use App\Models\DeliveryStatusHistory;
use Exception;
use Illuminate\Support\Facades\DB;

class DeliveryStatusService
{
    private const ALLOWED_TRANSITIONS = [
        'ASSIGNED' => ['PICKED_UP', 'DELIVERY_FAILED'],
        'PICKED_UP' => ['IN_TRANSIT', 'DELIVERY_FAILED'],
        'IN_TRANSIT' => ['ARRIVING', 'DELIVERY_FAILED'],
        'ARRIVING' => ['DELIVERED', 'DELIVERY_FAILED'],
        'DELIVERED' => [],
        'DELIVERY_FAILED' => [],
    ];

    /**
     * @throws Exception
     */
    public function updateStatus(Delivery $delivery, string $newStatus, int $changedByUserId, ?float $latitude = null, ?float $longitude = null): Delivery
    {
        $currentStatus = $delivery->status;

        if (!isset(self::ALLOWED_TRANSITIONS[$currentStatus])) {
            throw new Exception("Invalid current status: {$currentStatus}");
        }

        if (!in_array($newStatus, self::ALLOWED_TRANSITIONS[$currentStatus])) {
            throw new Exception("Invalid status transition from {$currentStatus} to {$newStatus}");
        }

        DB::transaction(function () use ($delivery, $newStatus, $changedByUserId, $latitude, $longitude) {
            $delivery->status = $newStatus;
            
            if ($newStatus === 'PICKED_UP') {
                $delivery->started_at = now();
            } elseif ($newStatus === 'DELIVERED') {
                $delivery->delivered_at = now();
            }

            $delivery->save();

            DeliveryStatusHistory::create([
                'delivery_id' => $delivery->id,
                'status' => $newStatus,
                'changed_by' => $changedByUserId,
                'latitude' => $latitude,
                'longitude' => $longitude,
            ]);
        });

        return $delivery->fresh();
    }
}
