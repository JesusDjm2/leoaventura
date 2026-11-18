@extends('admin.layout')

@section('title', 'Dashboard')

@section('content')
<div class="page-head">
    <div>
        <h1>Dashboard General</h1>
        <p>Visión en tiempo real de familias, progreso infantil, currículo y planes de suscripción.</p>
    </div>
    <a href="{{ route('admin.curriculum.index') }}" class="btn btn-primary">+ Gestionar Fonemas</a>
</div>

<div class="alert alert-info">
    🎁 <strong>Modo Lanzamiento Activo:</strong> Actualmente todas las funciones de aprendizaje están abiertas de forma <strong>gratuita</strong>. La estructura de planes <strong>Gratis / Premium</strong> ya está operativa en <a href="{{ route('admin.subscribers.index') }}" style="color: inherit; font-weight: 900;">Familias y Suscriptores</a>.
</div>

<section class="kpi-grid" aria-label="Indicadores principales">
    <div class="card">
        <div class="kpi-label">Familias Registradas</div>
        <div class="kpi-value">{{ $kpis['total_families'] }}</div>
        <div class="kpi-sub">{{ $kpis['free_families'] }} Gratis · {{ $kpis['premium_families'] }} Premium</div>
    </div>
    <div class="card">
        <div class="kpi-label">Perfiles Infantiles</div>
        <div class="kpi-value">{{ $kpis['total_children'] }}</div>
        <div class="kpi-sub">Pequeños lectores activos</div>
    </div>
    <div class="card">
        <div class="kpi-label">Actividades Completadas</div>
        <div class="kpi-value">{{ $kpis['total_sessions'] }}</div>
        <div class="kpi-sub">≈ {{ $kpis['total_sessions'] * 3 }} min de lectura</div>
    </div>
    <div class="card">
        <div class="kpi-label">Estrellas Ganadas</div>
        <div class="kpi-value">★ {{ $kpis['total_stars'] }}</div>
        <div class="kpi-sub">Recompensas logradas</div>
    </div>
    <div class="card">
        <div class="kpi-label">Currículo Activo</div>
        <div class="kpi-value">{{ $kpis['active_levels'] }}/{{ $kpis['total_levels'] }}</div>
        <div class="kpi-sub">Fonemas publicados</div>
    </div>
</section>

<section class="grid-2">
    <div class="card">
        <h2 style="font-size: 1.05rem; font-weight: 900; margin-bottom: 4px;">Actividad de los últimos 7 días</h2>
        <p style="font-size: 13px; color: var(--muted); margin-bottom: 18px;">Sesiones de lectura sincronizadas por día</p>
        <div style="display: grid; grid-template-columns: repeat(7, 1fr); gap: 10px; align-items: end; height: 170px; padding-top: 16px;">
            @foreach ($daily_activity as $day)
                <div style="display: flex; flex-direction: column; align-items: center; gap: 6px; height: 100%; justify-content: flex-end;">
                    <span style="font-size: 12px; font-weight: 800; color: var(--navy);">{{ $day['count'] }}</span>
                    <div style="width: 100%; max-width: 38px; height: {{ max(10, $day['percent']) }}%; background: linear-gradient(180deg, #5BC0EB 0%, #102B4E 100%); border-radius: 10px 10px 4px 4px;"></div>
                    <span style="font-size: 11px; font-weight: 700; color: var(--muted);">{{ $day['label'] }}</span>
                </div>
            @endforeach
        </div>
    </div>

    <div class="card">
        <h2 style="font-size: 1.05rem; font-weight: 900; margin-bottom: 4px;">Dominio por Fonema</h2>
        <p style="font-size: 13px; color: var(--muted); margin-bottom: 16px;">Promedio global de acierto en letras practicadas</p>
        @if ($phoneme_stats->isEmpty())
            <p style="font-size: 14px; color: var(--muted); padding: 20px 0;">Aún no hay sesiones sincronizadas. Completa una actividad en la app web para ver métricas aquí.</p>
        @else
            <div style="display: flex; flex-direction: column; gap: 12px;">
                @foreach ($phoneme_stats as $stat)
                    <div>
                        <div style="display: flex; justify-content: space-between; font-size: 13px; font-weight: 800; margin-bottom: 4px;">
                            <span>Letra {{ $stat['phoneme'] }} ({{ $stat['sessions'] }} sesiones)</span>
                            <span>{{ $stat['avg_score'] }}%</span>
                        </div>
                        <div style="height: 10px; background: #EAF2FA; border-radius: 999px; overflow: hidden;">
                            <div style="width: {{ $stat['avg_score'] }}%; height: 100%; background: {{ $stat['avg_score'] >= 80 ? '#2E7D32' : '#FF9E3D' }}; border-radius: 999px;"></div>
                        </div>
                    </div>
                @endforeach
            </div>
        @endif
    </div>
</section>

<section class="card">
    <h2 style="font-size: 1.05rem; font-weight: 900; margin-bottom: 14px;">Últimos Avances Sincronizados</h2>
    @if ($recent_activity->isEmpty())
        <p style="font-size: 14px; color: var(--muted);">Sin actividad reciente todavía.</p>
    @else
        <div class="table-wrap">
            <table>
                <thead>
                <tr>
                    <th>Perfil Infantil</th>
                    <th>Actividad</th>
                    <th>Puntaje</th>
                    <th>Estrellas</th>
                    <th>Fecha</th>
                </tr>
                </thead>
                <tbody>
                @foreach ($recent_activity as $row)
                    <tr>
                        <td><strong>{{ $row->child?->name ?? 'Perfil #'.$row->child_id }}</strong></td>
                        <td><code>{{ $row->activity_id }}</code></td>
                        <td>{{ $row->score }} / 100</td>
                        <td>★ {{ $row->stars }}</td>
                        <td>{{ optional($row->updated_at)->format('d/m/Y H:i') }}</td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>
    @endif
</section>
@endsection
