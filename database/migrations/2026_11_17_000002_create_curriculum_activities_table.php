<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('curriculum_activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('curriculum_level_id')
                ->constrained('curriculum_levels')
                ->cascadeOnDelete();
            $table->string('activity_code', 80)->unique();
            $table->string('type', 48)->index();
            $table->string('title', 140);
            $table->string('instruction', 255);
            $table->string('audio_key', 120);
            $table->unsignedSmallInteger('order_index')->default(1);
            $table->json('payload');
            $table->timestamps();

            $table->index(['curriculum_level_id', 'order_index']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('curriculum_activities');
    }
};
