<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Delivery;

class CustomerDeliveryController extends Controller
{
    public function index(Request $request)
    {
        $deliveries = $request->user()->deliveriesAsCustomer()->with('driver')->orderBy('created_at', 'desc')->get();
        return response()->json($deliveries);
    }

    public function store(Request $request)
    {
        $request->validate([
            'pickup_address' => 'required|string',
            'delivery_address' => 'required|string',
        ]);

        // Find the driver with the fewest active assigned deliveries (Load-balanced Round-Robin)
        $driver = \App\Models\User::where('role', 'DRIVER')
            ->withCount(['deliveriesAsDriver' => function ($query) {
                $query->whereIn('status', ['ASSIGNED', 'PICKED_UP', 'IN_TRANSIT']);
            }])
            ->orderBy('deliveries_as_driver_count', 'asc')
            ->first();

        $delivery = Delivery::create([
            'customer_id' => $request->user()->id,
            'driver_id' => $driver ? $driver->id : null,
            'status' => 'ASSIGNED',
            'pickup_address' => $request->pickup_address,
            'delivery_address' => $request->delivery_address,
        ]);

        \App\Models\DeliveryStatusHistory::create([
            'delivery_id' => $delivery->id,
            'status' => 'ASSIGNED',
            'changed_by' => $request->user()->id,
        ]);

        return response()->json($delivery, 201);
    }

    public function show(Request $request, Delivery $delivery)
    {
        if ($delivery->customer_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        $delivery->load(['driver']);
        return response()->json($delivery);
    }

    public function timeline(Request $request, Delivery $delivery)
    {
        if ($delivery->customer_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        return response()->json($delivery->statusHistories()->orderBy('created_at', 'asc')->get());
    }

    public function location(Request $request, Delivery $delivery)
    {
        if ($delivery->customer_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        $location = $delivery->driverLocations()->orderBy('recorded_at', 'desc')->first();
        return response()->json($location);
    }
}
