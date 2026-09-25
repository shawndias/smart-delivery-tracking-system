<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = \App\Models\User::find(4);
$delivery = \App\Models\Delivery::find(9);

$controller = app()->make(\App\Http\Controllers\Api\DriverDeliveryController::class);
$request = \Illuminate\Http\Request::create('/api/driver/deliveries/9', 'GET');
$request->setUserResolver(function() use ($user) { return $user; });

try {
    $response = $controller->show($request, $delivery);
    echo "SUCCESS:\n";
    echo $response->getContent();
} catch (\Exception $e) {
    echo "ERROR:\n";
    echo $e->getMessage();
}
