<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Delivery extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id', 'driver_id', 'status', 'pickup_address',
        'delivery_address', 'estimated_arrival_at', 'started_at', 'delivered_at'
    ];

    protected $casts = [
        'estimated_arrival_at' => 'datetime',
        'started_at' => 'datetime',
        'delivered_at' => 'datetime',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function statusHistories()
    {
        return $this->hasMany(DeliveryStatusHistory::class);
    }

    public function driverLocations()
    {
        return $this->hasMany(DriverLocation::class);
    }

    public function issues()
    {
        return $this->hasMany(DeliveryIssue::class);
    }
}
