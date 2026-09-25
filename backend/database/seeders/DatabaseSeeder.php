<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        $customer = \App\Models\User::factory()->create([
            'name' => 'Customer User',
            'email' => 'customer@example.com',
            'password' => bcrypt('password'),
            'role' => 'CUSTOMER',
        ]);

        $driver = \App\Models\User::factory()->create([
            'name' => 'Driver User',
            'email' => 'driver@example.com',
            'password' => bcrypt('password'),
            'role' => 'DRIVER',
        ]);

        $delivery = \App\Models\Delivery::create([
            'customer_id' => $customer->id,
            'driver_id' => $driver->id,
            'status' => 'DELIVERED',
            'pickup_address' => '123 Pickup St',
            'delivery_address' => '456 Dropoff Ave',
            'started_at' => now()->subHours(2),
            'delivered_at' => now(),
        ]);

        \App\Models\DeliveryStatusHistory::create(['delivery_id' => $delivery->id, 'status' => 'ASSIGNED', 'changed_by' => $driver->id, 'created_at' => now()->subHours(3)]);
        \App\Models\DeliveryStatusHistory::create(['delivery_id' => $delivery->id, 'status' => 'PICKED_UP', 'changed_by' => $driver->id, 'created_at' => now()->subHours(2)]);
        \App\Models\DeliveryStatusHistory::create(['delivery_id' => $delivery->id, 'status' => 'IN_TRANSIT', 'changed_by' => $driver->id, 'created_at' => now()->subHours(1)]);
        \App\Models\DeliveryStatusHistory::create(['delivery_id' => $delivery->id, 'status' => 'ARRIVING', 'changed_by' => $driver->id, 'created_at' => now()->subMinutes(10)]);
        \App\Models\DeliveryStatusHistory::create(['delivery_id' => $delivery->id, 'status' => 'DELIVERED', 'changed_by' => $driver->id, 'created_at' => now()]);

        \App\Models\DriverLocation::create(['delivery_id' => $delivery->id, 'driver_id' => $driver->id, 'latitude' => 15.123, 'longitude' => 73.123, 'recorded_at' => now()]);

        \App\Models\Delivery::create([
            'customer_id' => $customer->id,
            'driver_id' => $driver->id,
            'status' => 'ASSIGNED',
            'pickup_address' => '789 Another St',
            'delivery_address' => '321 Somewhere Else',
        ]);
    }
}
