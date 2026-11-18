<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class AdminSubscriberController extends Controller
{
    public function index(Request $request): View
    {
        $planFilter = (string) $request->query('plan', 'all');
        $search = trim((string) $request->query('q', ''));

        $query = User::query()
            ->where('is_admin', false)
            ->select(['id', 'name', 'email', 'plan_tier', 'subscription_status', 'subscription_expires_at', 'created_at'])
            ->withCount('children')
            ->with(['children' => static fn ($q) => $q->select(['id', 'user_id', 'name'])->withCount('progress')])
            ->orderByDesc('created_at');

        if (in_array($planFilter, [User::PLAN_FREE, User::PLAN_PREMIUM], true)) {
            $query->where('plan_tier', $planFilter);
        }

        if ($search !== '') {
            $query->where(static function ($q) use ($search): void {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $subscribers = $query->paginate(20)->withQueryString();

        $counts = [
            'all' => User::query()->where('is_admin', false)->count(),
            'free' => User::query()->where('is_admin', false)->where('plan_tier', User::PLAN_FREE)->count(),
            'premium' => User::query()->where('is_admin', false)->where('plan_tier', User::PLAN_PREMIUM)->count(),
        ];

        return view('admin.subscribers', [
            'subscribers' => $subscribers,
            'planFilter' => $planFilter,
            'search' => $search,
            'counts' => $counts,
        ]);
    }

    public function updatePlan(Request $request, User $user): RedirectResponse
    {
        $validated = $request->validate([
            'plan_tier' => ['required', 'in:free,premium'],
            'subscription_status' => ['required', 'in:active,trial,past_due,cancelled'],
            'subscription_expires_at' => ['nullable', 'date'],
        ]);

        DB::transaction(function () use ($user, $validated): void {
            $user->plan_tier = $validated['plan_tier'];
            $user->subscription_status = $validated['subscription_status'];
            $user->subscription_expires_at = $validated['plan_tier'] === User::PLAN_PREMIUM
                ? ($validated['subscription_expires_at'] ?? now()->addMonth())
                : null;
            $user->save();
        });

        return back()->with(
            'status',
            sprintf('Plan de %s actualizado a %s (%s).', $user->name, strtoupper($user->plan_tier), $user->subscription_status)
        );
    }
}
