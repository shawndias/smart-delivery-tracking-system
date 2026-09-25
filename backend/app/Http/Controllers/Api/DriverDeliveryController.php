<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Delivery;
use App\Models\DeliveryIssue;
use App\Models\DriverLocation;
use App\Services\DeliveryStatusService;

class DriverDeliveryController extends Controller
{
    private DeliveryStatusService $statusService;

    public function __construct(DeliveryStatusService $statusService)
    {
        $this->statusService = $statusService;
    }

    public function index(Request $request)
    {
        $deliveries = $request->user()->deliveriesAsDriver()->with('customer')->orderBy('created_at', 'desc')->get();
        return response()->json($deliveries);
    }

    public function show(Request $request, Delivery $delivery)
    {
        if ($delivery->driver_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        $delivery->load(['customer']);
        return response()->json($delivery);
    }

    public function updateStatus(Request $request, Delivery $delivery)
    {
        if ($delivery->driver_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'status' => 'required|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        try {
            $updatedDelivery = $this->statusService->updateStatus($delivery, $request->status, $request->user()->id, $request->latitude, $request->longitude);
            return response()->json($updatedDelivery);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function updateLocation(Request $request, Delivery $delivery)
    {
        if ($delivery->driver_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        $location = DriverLocation::create([
            'delivery_id' => $delivery->id,
            'driver_id' => $request->user()->id,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'recorded_at' => now(),
        ]);

        return response()->json($location);
    }

    public function reportIssue(Request $request, Delivery $delivery)
    {
        if ($delivery->driver_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'reason' => 'required|string',
            'description' => 'nullable|string',
        ]);

        $issue = DeliveryIssue::create([
            'delivery_id' => $delivery->id,
            'reported_by' => $request->user()->id,
            'reason' => $request->reason,
            'description' => $request->description,
        ]);

        // Automatically mark as failed if there's an issue
        try {
            $this->statusService->updateStatus($delivery, 'DELIVERY_FAILED', $request->user()->id);
        } catch (\Exception $e) {
            // Ignore error if it's already failed or delivered
        }

        return response()->json($issue);
    }
}
