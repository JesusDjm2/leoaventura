@extends('admin.layout')

@section('title', 'Familias y Suscriptores')

@section('content')
<div class="page-head">
    <div>
        <h1>Familias y Suscriptores</h1>
        <p>Gestiona cuentas registradas, perfiles infantiles y planes Gratis / Premium.</p>
    </div>
</div>

<div class="alert alert-info">
    💡 <strong>Política actual:</strong> Toda la app funciona en acceso <strong>Gratis</strong> por lanzamiento. Desde esta tabla puedes marcar cuentas como <strong>Premium</strong> (prueba, cortesía o futuro pago) y el estado se guarda en <code>users.plan_tier</code>.
</div>

<div class="card" style="margin-bottom: 20px;">
    <form method="GET" action="{{ route('admin.subscribers.index') }}" style="display: flex; flex-wrap: wrap; gap: 10px; align-items: center;">
        <input type="text" name="q" value="{{ $search }}" placeholder="Buscar por nombre o correo..." style="flex: 1; min-width: 220px;">
        <select name="plan">
            <option value="all" {{ $planFilter === 'all' ? 'selected' : '' }}>Todos ({{ $counts['all'] }})</option>
            <option value="free" {{ $planFilter === 'free' ? 'selected' : '' }}>Solo Gratis ({{ $counts['free'] }})</option>
            <option value="premium" {{ $planFilter === 'premium' ? 'selected' : '' }}>Solo Premium ({{ $counts['premium'] }})</option>
        </select>
        <button type="submit" class="btn btn-navy">Filtrar</button>
    </form>
</div>

<div class="card">
    @if ($subscribers->isEmpty())
        <p style="font-size: 14px; color: var(--muted);">No hay familias registradas con este filtro todavía.</p>
    @else
        <div class="table-wrap">
            <table>
                <thead>
                <tr>
                    <th>Familia</th>
                    <th>Niños / Avances</th>
                    <th>Plan Actual</th>
                    <th>Registro</th>
                    <th>Cambiar Plan (Gratis / Premium)</th>
                </tr>
                </thead>
                <tbody>
                @foreach ($subscribers as $subscriber)
                    @php
                        $totalProgress = $subscriber->children->sum('progress_count');
                    @endphp
                    <tr>
                        <td>
                            <strong>{{ $subscriber->name }}</strong><br>
                            <span style="font-size: 12px; color: var(--muted);">{{ $subscriber->email }}</span>
                        </td>
                        <td>
                            <strong>{{ $subscriber->children_count }}</strong> niño(s) ·
                            <strong>{{ $totalProgress }}</strong> actividades
                        </td>
                        <td>
                            <span class="badge {{ $subscriber->plan_tier === 'premium' ? 'badge-premium' : 'badge-free' }}">
                                {{ $subscriber->plan_tier === 'premium' ? '⭐ PREMIUM' : 'GRATIS' }}
                            </span>
                            <div style="font-size: 11px; color: var(--muted); margin-top: 4px;">
                                Estado: {{ $subscriber->subscription_status }}
                                @if ($subscriber->subscription_expires_at)
                                    · vence {{ $subscriber->subscription_expires_at->format('d/m/Y') }}
                                @endif
                            </div>
                        </td>
                        <td>{{ optional($subscriber->created_at)->format('d/m/Y') }}</td>
                        <td>
                            <form method="POST" action="{{ route('admin.subscribers.plan', $subscriber) }}" style="display: flex; flex-wrap: wrap; gap: 6px; align-items: center;">
                                @csrf
                                @method('PATCH')
                                <select name="plan_tier" class="input-sm">
                                    <option value="free" {{ $subscriber->plan_tier === 'free' ? 'selected' : '' }}>Gratis</option>
                                    <option value="premium" {{ $subscriber->plan_tier === 'premium' ? 'selected' : '' }}>Premium</option>
                                </select>
                                <select name="subscription_status" class="input-sm">
                                    <option value="active" {{ $subscriber->subscription_status === 'active' ? 'selected' : '' }}>Activa</option>
                                    <option value="trial" {{ $subscriber->subscription_status === 'trial' ? 'selected' : '' }}>Prueba</option>
                                    <option value="past_due" {{ $subscriber->subscription_status === 'past_due' ? 'selected' : '' }}>Pendiente</option>
                                    <option value="cancelled" {{ $subscriber->subscription_status === 'cancelled' ? 'selected' : '' }}>Cancelada</option>
                                </select>
                                <button type="submit" class="btn btn-primary btn-sm">Guardar</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>

        <div style="margin-top: 16px;">
            {{ $subscribers->links() }}
        </div>
    @endif
</div>
@endsection
