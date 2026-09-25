<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryStatusHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_id', 'status', 'changed_by', 'latitude', 'longitude'
    ];

    public function delivery()
    {
        return $this->belongsTo(Delivery::class);
    }

    public function changedBy()
    {
        return $this->belongsTo(User::class, 'changed_by');
    }
}
