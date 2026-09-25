<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    public function deliveriesAsCustomer()
    {
        return $this->hasMany(Delivery::class, 'customer_id');
    }

    public function deliveriesAsDriver()
    {
        return $this->hasMany(Delivery::class, 'driver_id');
    }

    public function driverLocations()
    {
        return $this->hasMany(DriverLocation::class, 'driver_id');
    }

    public function deliveryIssues()
    {
        return $this->hasMany(DeliveryIssue::class, 'reported_by');
    }
}
