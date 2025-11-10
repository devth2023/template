#!/usr/bin/env bash
set -e
ROOT=$(pwd)
mkdir -p {app/Enums,app/Models,app/Services,app/Observers,app/Events,app/Listeners,app/Jobs,app/Http/Controllers/Admin,app/Http/Controllers/Vendor,app/Http/Controllers/Customer,app/Http/Middleware,database/migrations,database/seeders,resources/views/livewire/backend/admin,resources/views/livewire/frontend/shop,resources/css,resources/js,config}
# Write a few example files (expandable)
cat > README.md <<'MD'
# Blife Healthy

Blife Healthy e‑commerce and MLM platform

Quick start:
1. cp .env.example .env and set env
2. composer install
3. npm install && npm run dev
4. php artisan key:generate
5. php artisan migrate --seed
MD

cat > LICENSE <<'LICENSE'
MIT License

Copyright (c) $(date +%Y)

Permission is hereby granted, free of charge...
LICENSE

cat > .gitignore <<'GIT'
/vendor
/node_modules
/.env
/.env.*
/public/storage
/storage/*.key
/.idea
/.vscode
/.phpunit.result.cache
GIT

# composer.json minimal
cat > composer.json <<'JSON'
{
  "name": "devth2023/blife-healthy",
  "type": "project",
  "autoload": {
    "psr-4": { "App\\": "app/" }
  },
  "require": {
    "php": ">=8.1",
    "laravel/framework": "^12.0"
  },
  "require-dev": {
    "phpunit/phpunit": "^10.0",
    "nunomaduro/phpinsights": "^2.0"
  }
}
JSON

# package.json minimal
cat > package.json <<'PKG'
{
  "name": "blife-healthy",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  },
  "devDependencies": {
    "vite": "^5.0"
  }
}
PKG

# Example GitHub Actions CI file
mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'YAML'
name: CI
on: [push, pull_request]
jobs:
  php-tests:
    runs-on: ubuntu-latest
    services: {}
    steps:
      - uses: actions/checkout @v4
      - name: Setup PHP
        uses: shivammathur/setup-php @v2
        with:
          php-version: '8.2'
      - name: Install dependencies
        run: composer install --no-progress --no-suggest --prefer-dist
      - name: Run tests
        run: vendor/bin/phpunit --configuration phpunit.xml || true
  node-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout @v4
      - name: Setup Node
        uses: actions/setup-node @v4
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run build
YAML

# Create sample Enums (10)
for f in OrderStatus MlmSyncStatus ProductStatus VendorStatus RefundStatus PaymentStatus SupportStatus ReviewStatus CouponType ShippingType; do
  cat > "app/Enums/${f}.php" <<PHP
<?php

namespace App\Enums;

enum ${f}: string
{
    // TODO: add cases
    case SAMPLE = 'sample';

    public function label(): string
    {
        return match(\$this) {
            self::SAMPLE => 'ตัวอย่าง',
        };
    }
}
PHP
done

# Create sample Models (subset)
cat > app/Models/Order.php <<'PHP'
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Enums\OrderStatus;

class Order extends Model
{
    use HasFactory;
    protected $fillable = ['user_id','order_number','status','total','shipping_address','payment_method'];
    protected $casts = [
        'status' => OrderStatus::class,
        'shipping_address' => 'array',
        'total' => 'decimal:2'
    ];

    public function getStatusLabelAttribute(): string
    {
        return \$this->status->label();
    }
}
PHP

# Services sample
cat > app/Services/OrderService.php <<'PHP'
<?php
namespace App\Services;

use App\Models\Order;
use Illuminate\Support\Facades\DB;

class OrderService
{
    public function processOrder(array $data): Order
    {
        return DB::transaction(function () use ($data) {
            return Order::create($data);
        });
    }
}
PHP

# Observers, Events, Listeners, Jobs, Controllers, Middleware minimal stubs
cat > app/Observers/OrderObserver.php <<'PHP'
<?php
namespace App\Observers;

use App\Models\Order;

class OrderObserver
{
    public function created(Order $order): void {}
    public function updated(Order $order): void {}
}
PHP

cat > app/Events/OrderStatusChanged.php <<'PHP'
<?php
namespace App\Events;

use App\Models\Order;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;

class OrderStatusChanged implements ShouldBroadcast
{
    public function __construct(public Order $order) {}
    public function broadcastOn(): PrivateChannel { return new PrivateChannel('user.'.$this->order->user_id); }
}
PHP

cat > app/Listeners/StatusFeedbackListener.php <<'PHP'
<?php
namespace App\Listeners;

use App\Events\OrderStatusChanged;

class StatusFeedbackListener
{
    public function handle(OrderStatusChanged $event): void {}
}
PHP

cat > app/Jobs/SyncMlmCommissionJob.php <<'PHP'
<?php
namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;

class SyncMlmCommissionJob implements ShouldQueue
{
    use Queueable;
    public function handle(): void {}
}
PHP

cat > app/Http/Controllers/Admin/DashboardController.php <<'PHP'
<?php
namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;

class DashboardController extends Controller
{
    public function index() { return view('livewire.backend.admin.dashboard'); }
}
PHP

cat > app/Http/Middleware/EnsureAdmin.php <<'PHP'
<?php
namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next)
    {
        if (!$request->user()?->hasRole('admin')) {
            abort(403);
        }
        return $next($request);
    }
}
PHP

# Example migration
cat > database/migrations/2025_01_01_000000_create_orders_table.php <<'MIG'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('order_number')->unique();
            $table->string('status');
            $table->decimal('total', 15, 2);
            $table->json('shipping_address')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }
    public function down(): void { Schema::dropIfExists('orders'); }
};
MIG

# Seeder sample
cat > database/seeders/DatabaseSeeder.php <<'PHP'
<?php
namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // \App\Models\User::factory(10)->create();
    }
}
PHP

# Views sample
cat > resources/views/livewire/backend/admin/dashboard.blade.php <<'BLADE'
<div>
    <h1>แดชบอร์ด</h1>
    <x-flux::table :rows="[]">No data yet</x-flux::table>
</div>
BLADE

# CSS/JS sample
cat > resources/css/flux-frontend.css <<'CSS'
/* FluxUI stub */
body { font-family: ui-sans-serif; }
CSS
cat > resources/js/flux-frontend.js <<'JS'
// Alpine stub
document.addEventListener('alpine:init', () => {});
JS

# Config sample
cat > config/mlm.php <<'PHP'
<?php
return [
    'api_key' => env('MLM_API_KEY'),
    'endpoint' => env('MLM_ENDPOINT', 'https://api.example.com')
];
PHP

# Finalize git
git init
git add --all
git commit -m "Initial full production blueprint scaffold (push-all)"

echo "Scaffold generated and committed locally. Next: create repo on GitHub and push."