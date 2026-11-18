<?php

namespace App\Services\Admin;

use App\Models\ActivityProgress;
use App\Models\Child;
use App\Models\CurriculumLevel;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class AdminDashboardService
{
    /**
     * Agrega métricas globales en tiempo real con consultas acotadas (sin N+1).
     *
     * @return array<string, mixed>
     */
    public function summary(): array
    {
        $totalFamilies = User::query()->where('is_admin', false)->count();
        $freeFamilies = User::query()
            ->where('is_admin', false)
            ->where('plan_tier', User::PLAN_FREE)
            ->count();
        $premiumFamilies = User::query()
            ->where('is_admin', false)
            ->where('plan_tier', User::PLAN_PREMIUM)
            ->whereIn('subscription_status', ['active', 'trial'])
            ->count();

        $totalChildren = Child::query()->count();
        $totalSessions = ActivityProgress::query()->count();
        $totalStars = (int) ActivityProgress::query()->sum('stars');
        $activeLevels = CurriculumLevel::query()->where('is_active', true)->count();
        $totalLevels = CurriculumLevel::query()->count();

        $dailyActivity = $this->lastSevenDaysActivity();
        $phonemeStats = $this->phonemeMasteryStats();
        $recentActivity = ActivityProgress::query()
            ->with(['child:id,name,avatar_key,user_id'])
            ->select(['id', 'child_id', 'activity_id', 'score', 'stars', 'updated_at'])
            ->orderByDesc('updated_at')
            ->limit(10)
            ->get();

        return [
            'kpis' => [
                'total_families' => $totalFamilies,
                'free_families' => $freeFamilies,
                'premium_families' => $premiumFamilies,
                'total_children' => $totalChildren,
                'total_sessions' => $totalSessions,
                'total_stars' => $totalStars,
                'active_levels' => $activeLevels,
                'total_levels' => $totalLevels,
            ],
            'daily_activity' => $dailyActivity,
            'phoneme_stats' => $phonemeStats,
            'recent_activity' => $recentActivity,
        ];
    }

    /**
     * Conteo de sesiones completadas por día durante los últimos 7 días.
     *
     * @return array<int, array{label: string, date: string, count: int, percent: int}>
     */
    private function lastSevenDaysActivity(): array
    {
        $start = Carbon::now()->subDays(6)->startOfDay();
        $rows = ActivityProgress::query()
            ->select(['updated_at'])
            ->where('updated_at', '>=', $start)
            ->get();

        $countsByDate = [];
        for ($i = 6; $i >= 0; $i--) {
            $day = Carbon::now()->subDays($i);
            $countsByDate[$day->format('Y-m-d')] = [
                'label' => $day->format('d/m'),
                'date' => $day->format('Y-m-d'),
                'count' => 0,
            ];
        }

        foreach ($rows as $row) {
            $key = optional($row->updated_at)->format('Y-m-d');
            if ($key !== null && isset($countsByDate[$key])) {
                $countsByDate[$key]['count']++;
            }
        }

        $max = max(1, max(array_column($countsByDate, 'count')));

        return array_values(array_map(
            static fn (array $item): array => [
                ...$item,
                'percent' => (int) round(($item['count'] / $max) * 100),
            ],
            $countsByDate
        ));
    }

    /**
     * Dominio promedio y sesiones por fonema en toda la plataforma.
     *
     * @return Collection<int, array{phoneme: string, sessions: int, avg_score: int}>
     */
    private function phonemeMasteryStats(): Collection
    {
        $rows = ActivityProgress::query()
            ->select(['activity_id', 'score', 'metadata'])
            ->get();

        $buckets = [];
        foreach ($rows as $row) {
            $letter = $this->extractLetter($row);
            if ($letter === null) {
                continue;
            }
            if (! isset($buckets[$letter])) {
                $buckets[$letter] = ['phoneme' => $letter, 'sessions' => 0, 'score_sum' => 0];
            }
            $buckets[$letter]['sessions']++;
            $buckets[$letter]['score_sum'] += max(0, min(100, (int) $row->score));
        }

        return collect($buckets)
            ->map(static fn (array $b): array => [
                'phoneme' => $b['phoneme'],
                'sessions' => $b['sessions'],
                'avg_score' => (int) round($b['score_sum'] / max(1, $b['sessions'])),
            ])
            ->sortByDesc('sessions')
            ->take(10)
            ->values();
    }

    private function extractLetter(ActivityProgress $row): ?string
    {
        if (is_array($row->metadata) && ! empty($row->metadata['letter'])) {
            return mb_strtoupper(trim((string) $row->metadata['letter']));
        }
        if (preg_match('/^act_([a-zñ]+)_/iu', (string) $row->activity_id, $matches) === 1) {
            $slug = mb_strtolower($matches[1]);

            return $slug === 'enie' ? 'Ñ' : mb_strtoupper($slug);
        }

        return null;
    }
}
