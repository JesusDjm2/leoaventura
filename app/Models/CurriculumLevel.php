<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CurriculumLevel extends Model
{
    protected $fillable = [
        'code',
        'title',
        'phoneme',
        'letter',
        'example_word',
        'unit',
        'order_index',
        'audio_key',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'unit' => 'integer',
            'order_index' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    /**
     * Actividades pedagógicas pertenecientes a este nivel fonético.
     */
    public function activities(): HasMany
    {
        return $this->hasMany(CurriculumActivity::class)->orderBy('order_index');
    }
}
