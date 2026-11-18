<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('curriculum_levels', function (Blueprint $table) {
            $table->id();
            $table->string('code', 64)->unique();
            $table->string('title', 120);
            $table->string('phoneme', 24);
            $table->string('letter', 8);
            $table->string('example_word', 64);
            $table->unsignedTinyInteger('unit')->default(1);
            $table->unsignedSmallInteger('order_index')->unique();
            $table->string('audio_key', 120);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['is_active', 'order_index']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('curriculum_levels');
    }
};
