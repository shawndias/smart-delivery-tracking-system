<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryIssue extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_id', 'reported_by', 'reason', 'description'
    ];

    public function delivery()
    {
        return $this->belongsTo(Delivery::class);
    }

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reported_by');
    }
}
