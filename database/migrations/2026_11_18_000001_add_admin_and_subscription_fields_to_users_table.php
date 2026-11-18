<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (! Schema::hasColumn('users', 'is_admin')) {
                $table->boolean('is_admin')->default(false)->after('password')->index();
            }
            if (! Schema::hasColumn('users', 'plan_tier')) {
                $table->string('plan_tier', 20)->default('free')->after('is_admin')->index();
            }
            if (! Schema::hasColumn('users', 'subscription_status')) {
                $table->string('subscription_status', 20)->default('active')->after('plan_tier');
            }
            if (! Schema::hasColumn('users', 'subscription_expires_at')) {
                $table->timestamp('subscription_expires_at')->nullable()->after('subscription_status');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $columns = array_values(array_filter(
                ['is_admin', 'plan_tier', 'subscription_status', 'subscription_expires_at'],
                static fn (string $col): bool => Schema::hasColumn('users', $col)
            ));

            if (! empty($columns)) {
                $table->dropColumn($columns);
            }
        });
    }
};
