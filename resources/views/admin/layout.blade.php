<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex, nofollow">
    <title>@yield('title', 'Panel Administrador') — Leoaventura</title>
    <style>
        :root {
            --sky: #D9F0FF;
            --sky-soft: #F2F9FF;
            --navy: #102B4E;
            --navy-soft: #1B3E6B;
            --muted: #526B87;
            --orange: #FF9E3D;
            --green: #2E7D32;
            --green-bg: #E8F5E9;
            --cyan: #5BC0EB;
            --amber-bg: #FFF3E0;
            --amber-text: #9A4D00;
            --danger: #C62828;
            --danger-bg: #FFEBEE;
            --surface: #FFFFFF;
            --border: #D4E6F4;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            min-height: 100dvh;
            background: var(--sky-soft);
            color: var(--navy);
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            overflow-x: hidden;
        }
        .shell {
            display: grid;
            grid-template-columns: 1fr;
            min-height: 100dvh;
        }
        @media (min-width: 960px) {
            .shell { grid-template-columns: 264px 1fr; }
        }
        .sidebar {
            background: var(--navy);
            color: #FFFFFF;
            padding: 24px 18px;
            display: flex;
            flex-direction: column;
            gap: 20px;
        }
        .brand {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.25rem;
            font-weight: 900;
            letter-spacing: -0.01em;
            color: #FFFFFF;
            text-decoration: none;
        }
        .brand-pill {
            font-size: 11px;
            font-weight: 800;
            background: var(--orange);
            color: var(--navy);
            padding: 3px 8px;
            border-radius: 999px;
        }
        .nav {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }
        @media (min-width: 960px) {
            .nav { flex-direction: column; }
        }
        .nav a {
            display: flex;
            align-items: center;
            gap: 10px;
            min-height: 44px;
            padding: 10px 14px;
            border-radius: 14px;
            color: rgba(255, 255, 255, 0.85);
            text-decoration: none;
            font-weight: 700;
            font-size: 14px;
            transition: background 0.15s ease, color 0.15s ease;
        }
        .nav a:hover, .nav a.active {
            background: rgba(91, 192, 235, 0.22);
            color: #FFFFFF;
        }
        .nav a.active {
            border-left: 4px solid var(--orange);
        }
        .sidebar-footer {
            margin-top: auto;
            padding-top: 16px;
            border-top: 1px solid rgba(255, 255, 255, 0.14);
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .sidebar-footer .user-meta {
            font-size: 12px;
            color: rgba(255, 255, 255, 0.72);
        }
        .main {
            padding: 24px 20px 48px;
            max-width: 1240px;
            width: 100%;
            margin: 0 auto;
        }
        @media (min-width: 960px) {
            .main { padding: 32px 36px 56px; }
        }
        .page-head {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 24px;
        }
        .page-head h1 {
            font-size: clamp(1.4rem, 2.6vw, 1.9rem);
            font-weight: 900;
        }
        .page-head p {
            color: var(--muted);
            font-size: 14px;
            margin-top: 4px;
        }
        .alert {
            padding: 14px 18px;
            border-radius: 16px;
            margin-bottom: 20px;
            font-weight: 700;
            font-size: 14px;
        }
        .alert-success {
            background: var(--green-bg);
            color: var(--green);
            border: 1.5px solid #A5D6A7;
        }
        .alert-info {
            background: var(--sky);
            color: var(--navy);
            border: 1.5px solid var(--cyan);
        }
        .alert-error {
            background: var(--danger-bg);
            color: var(--danger);
            border: 1.5px solid #EF9A9A;
        }
        .card {
            background: var(--surface);
            border: 1.5px solid var(--border);
            border-radius: 22px;
            padding: 20px;
            box-shadow: 0 8px 24px rgba(16, 43, 78, 0.06);
        }
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(185px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }
        .kpi-label {
            font-size: 12px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--muted);
        }
        .kpi-value {
            font-size: 2rem;
            font-weight: 900;
            margin: 6px 0 4px;
            color: var(--navy);
        }
        .kpi-sub {
            font-size: 13px;
            color: var(--muted);
            font-weight: 600;
        }
        .grid-2 {
            display: grid;
            grid-template-columns: 1fr;
            gap: 20px;
            margin-bottom: 24px;
        }
        @media (min-width: 900px) {
            .grid-2 { grid-template-columns: 1.25fr 1fr; }
        }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            min-height: 44px;
            padding: 8px 16px;
            border-radius: 14px;
            border: 1.5px solid transparent;
            font-weight: 800;
            font-size: 14px;
            cursor: pointer;
            text-decoration: none;
            transition: transform 0.12s ease, opacity 0.12s ease;
        }
        .btn:hover { transform: translateY(-1px); }
        .btn-primary { background: var(--orange); color: var(--navy); border-color: var(--navy); }
        .btn-navy { background: var(--navy); color: #FFFFFF; }
        .btn-outline { background: var(--surface); color: var(--navy); border-color: var(--border); }
        .btn-danger { background: var(--danger-bg); color: var(--danger); border-color: #EF9A9A; }
        .btn-sm { min-height: 36px; padding: 6px 12px; font-size: 13px; border-radius: 10px; }
        .table-wrap { overflow-x: auto; }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        th, td {
            padding: 12px 10px;
            text-align: left;
            border-bottom: 1px solid #EAF2FA;
            vertical-align: middle;
        }
        th {
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--muted);
            font-weight: 800;
        }
        .badge {
            display: inline-flex;
            align-items: center;
            padding: 4px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 800;
        }
        .badge-free { background: var(--sky); color: var(--navy); }
        .badge-premium { background: var(--amber-bg); color: var(--amber-text); border: 1px solid var(--orange); }
        .badge-active { background: var(--green-bg); color: var(--green); }
        .badge-inactive { background: #ECEFF1; color: #546E7A; }
        input[type="text"], input[type="email"], input[type="password"], input[type="number"], input[type="date"], select {
            min-height: 44px;
            padding: 8px 12px;
            border: 1.5px solid var(--border);
            border-radius: 12px;
            font-size: 14px;
            color: var(--navy);
            background: #FFFFFF;
        }
        .input-sm { min-height: 36px !important; padding: 4px 8px !important; font-size: 13px !important; }
    </style>
</head>
<body>
<div class="shell">
    <aside class="sidebar">
        <a href="{{ route('admin.dashboard') }}" class="brand">
            <img src="/images/brand/leoaventura_logo.png" alt="Logo Leoaventura" style="width: 34px; height: 34px; object-fit: contain; background: rgba(255,255,255,0.12); padding: 4px; border-radius: 10px;">
            <span>Leoaventura</span>
            <span class="brand-pill">PRO</span>
        </a>

        <nav class="nav" aria-label="Navegación de administración">
            <a href="{{ route('admin.dashboard') }}" class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>
                <span>Dashboard</span>
            </a>
            <a href="{{ route('admin.subscribers.index') }}" class="{{ request()->routeIs('admin.subscribers.*') ? 'active' : '' }}">
                <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                <span>Familias y Planes</span>
            </a>
            <a href="{{ route('admin.curriculum.index') }}" class="{{ request()->routeIs('admin.curriculum.*') ? 'active' : '' }}">
                <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/></svg>
                <span>Currículo Fonético</span>
            </a>
            <a href="{{ env('APP_WEB_URL', 'http://localhost:8080') }}" target="_blank" rel="noopener">
                <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg>
                <span>Ver App Web</span>
            </a>
        </nav>

        <div class="sidebar-footer">
            <div class="user-meta">
                Sesión: <strong>{{ auth()->user()->name }}</strong><br>
                {{ auth()->user()->email }}
            </div>
            <form method="POST" action="{{ route('admin.logout') }}">
                @csrf
                <button type="submit" class="btn btn-outline btn-sm" style="width: 100%;">
                    Cerrar sesión
                </button>
            </form>
        </div>
    </aside>

    <main class="main">
        @if (session('status'))
            <div class="alert alert-success" role="status">{{ session('status') }}</div>
        @endif

        @if ($errors->any())
            <div class="alert alert-error" role="alert">
                {{ $errors->first() }}
            </div>
        @endif

        @yield('content')
    </main>
</div>
</body>
</html>
