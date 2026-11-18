<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CurriculumActivity extends Model
{
    public const TYPE_TRACING = 'tracing';
    public const TYPE_SOUND_MATCH = 'sound_match';

    protected $fillable = [
        'curriculum_level_id',
        'activity_code',
        'type',
        'title',
        'instruction',
        'audio_key',
        'order_index',
        'payload',
    ];

    protected function casts(): array
    {
        return [
            'order_index' => 'integer',
            'payload' => 'array',
        ];
    }

    /**
     * Nivel fonético al que pertenece la actividad.
     */
    public function level(): BelongsTo
    {
        return $this->belongsTo(CurriculumLevel::class, 'curriculum_level_id');
    }
}
