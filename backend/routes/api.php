<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::post('/login', [App\Http\Controllers\Api\AuthController::class, 'login']);
Route::post('/register', [App\Http\Controllers\Api\AuthController::class, 'register']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::post('/logout', [App\Http\Controllers\Api\AuthController::class, 'logout']);

    // Customer APIs
    Route::get('/deliveries', [App\Http\Controllers\Api\CustomerDeliveryController::class, 'index']);
    Route::post('/deliveries', [App\Http\Controllers\Api\CustomerDeliveryController::class, 'store']);
    Route::get('/deliveries/{delivery}', [App\Http\Controllers\Api\CustomerDeliveryController::class, 'show']);
    Route::get('/deliveries/{delivery}/timeline', [App\Http\Controllers\Api\CustomerDeliveryController::class, 'timeline']);
    Route::get('/deliveries/{delivery}/location', [App\Http\Controllers\Api\CustomerDeliveryController::class, 'location']);

    // Driver APIs
    Route::get('/driver/deliveries', [App\Http\Controllers\Api\DriverDeliveryController::class, 'index']);
    Route::get('/driver/deliveries/{delivery}', [App\Http\Controllers\Api\DriverDeliveryController::class, 'show']);
    Route::post('/driver/deliveries/{delivery}/status', [App\Http\Controllers\Api\DriverDeliveryController::class, 'updateStatus']);
    Route::post('/driver/deliveries/{delivery}/location', [App\Http\Controllers\Api\DriverDeliveryController::class, 'updateLocation']);
    Route::post('/driver/deliveries/{delivery}/issues', [App\Http\Controllers\Api\DriverDeliveryController::class, 'reportIssue']);
});
