<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

use App\Models\User;
use App\Models\Delivery;
use App\Models\DeliveryStatusHistory;
use Illuminate\Foundation\Testing\RefreshDatabase;

class DeliveryApiTest extends TestCase
{
    use RefreshDatabase;

    private $customer1, $customer2, $driver1, $driver2, $delivery1, $delivery2;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->customer1 = User::factory()->create(['role' => 'CUSTOMER']);
        $this->customer2 = User::factory()->create(['role' => 'CUSTOMER']);
        $this->driver1 = User::factory()->create(['role' => 'DRIVER']);
        $this->driver2 = User::factory()->create(['role' => 'DRIVER']);

        $this->delivery1 = Delivery::create([
            'customer_id' => $this->customer1->id,
            'driver_id' => $this->driver1->id,
            'status' => 'ASSIGNED',
            'pickup_address' => 'A',
            'delivery_address' => 'B',
        ]);

        $this->delivery2 = Delivery::create([
            'customer_id' => $this->customer2->id,
            'driver_id' => $this->driver2->id,
            'status' => 'ASSIGNED',
            'pickup_address' => 'C',
            'delivery_address' => 'D',
        ]);
    }

    public function test_customer_can_view_their_deliveries()
    {
        $response = $this->actingAs($this->customer1)->getJson('/api/deliveries');
        $response->assertStatus(200);
        $response->assertJsonCount(1);
        $response->assertJsonFragment(['id' => $this->delivery1->id]);
    }

    public function test_customer_cannot_view_another_customers_delivery()
    {
        $response = $this->actingAs($this->customer1)->getJson("/api/deliveries/{$this->delivery2->id}");
        $response->assertStatus(403);
    }

    public function test_driver_can_view_assigned_deliveries()
    {
        $response = $this->actingAs($this->driver1)->getJson('/api/driver/deliveries');
        $response->assertStatus(200);
        $response->assertJsonCount(1);
    }

    public function test_driver_cannot_modify_another_drivers_delivery()
    {
        $response = $this->actingAs($this->driver1)->postJson("/api/driver/deliveries/{$this->delivery2->id}/status", [
            'status' => 'PICKED_UP'
        ]);
        $response->assertStatus(403);
    }

    public function test_valid_status_transition_succeeds()
    {
        $response = $this->actingAs($this->driver1)->postJson("/api/driver/deliveries/{$this->delivery1->id}/status", [
            'status' => 'PICKED_UP'
        ]);
        $response->assertStatus(200);
        $this->assertEquals('PICKED_UP', $this->delivery1->fresh()->status);
    }

    public function test_invalid_status_transition_fails()
    {
        $response = $this->actingAs($this->driver1)->postJson("/api/driver/deliveries/{$this->delivery1->id}/status", [
            'status' => 'DELIVERED'
        ]);
        $response->assertStatus(422);
    }

    public function test_timeline_entry_is_created_when_status_changes()
    {
        $this->actingAs($this->driver1)->postJson("/api/driver/deliveries/{$this->delivery1->id}/status", [
            'status' => 'PICKED_UP'
        ]);
        
        $this->assertDatabaseHas('delivery_status_histories', [
            'delivery_id' => $this->delivery1->id,
            'status' => 'PICKED_UP',
            'changed_by' => $this->driver1->id
        ]);
    }

    public function test_driver_location_can_be_updated()
    {
        $response = $this->actingAs($this->driver1)->postJson("/api/driver/deliveries/{$this->delivery1->id}/location", [
            'latitude' => 12.34,
            'longitude' => 56.78
        ]);
        $response->assertStatus(200);
        $this->assertDatabaseHas('driver_locations', [
            'latitude' => 12.34,
            'longitude' => 56.78
        ]);
    }

    public function test_delivery_issue_can_be_reported()
    {
        $response = $this->actingAs($this->driver1)->postJson("/api/driver/deliveries/{$this->delivery1->id}/issues", [
            'reason' => 'Traffic',
            'description' => 'Heavy traffic delay'
        ]);
        $response->assertStatus(200);
        $this->assertDatabaseHas('delivery_issues', [
            'reason' => 'Traffic'
        ]);
        // Also verify the status changed to DELIVERY_FAILED
        $this->assertEquals('DELIVERY_FAILED', $this->delivery1->fresh()->status);
    }
}
