<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex, nofollow">
    <title>Acceso Privado — Leoaventura</title>
    <style>
        :root {
            --bg-canvas: #F5F8FC;
            --surface: #FFFFFF;
            --navy-950: #071426;
            --navy-900: #0C213D;
            --navy-800: #102B4E;
            --navy-700: #1B3E6B;
            --ink: #0F233D;
            --ink-muted: #556B86;
            --ink-subtle: #7B8FA8;
            --border: #DCE6F2;
            --border-strong: #C2D4E8;
            --orange: #FF9E3D;
            --orange-hover: #F28C28;
            --cyan: #5BC0EB;
            --green: #2E7D32;
            --danger: #C62828;
            --danger-bg: #FEF2F2;
            --danger-border: #FECACA;
            --radius-lg: 20px;
            --radius-md: 12px;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            min-height: 100dvh;
            background: var(--bg-canvas);
            color: var(--ink);
            font-family: "Inter", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            -webkit-font-smoothing: antialiased;
            overflow-x: hidden;
        }

        .split-shell {
            display: grid;
            grid-template-columns: 1fr;
            min-height: 100dvh;
        }

        @media (min-width: 960px) {
            .split-shell {
                grid-template-columns: minmax(420px, 1.08fr) minmax(440px, 1fr);
            }
        }

        /* Panel izquierdo: identidad ejecutiva y arquitectura visual */
        .brand-panel {
            position: relative;
            background:
                radial-gradient(620px circle at 18% 12%, rgba(91, 192, 235, 0.22), transparent 60%),
                radial-gradient(520px circle at 88% 86%, rgba(255, 158, 61, 0.16), transparent 58%),
                linear-gradient(155deg, var(--navy-950) 0%, var(--navy-900) 48%, var(--navy-800) 100%);
            color: #FFFFFF;
            padding: 32px 24px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            gap: 28px;
            overflow: hidden;
        }

        .brand-panel::before {
            content: "";
            position: absolute;
            inset: 0;
            background-image: radial-gradient(rgba(255, 255, 255, 0.08) 1px, transparent 1px);
            background-size: 28px 28px;
            pointer-events: none;
            mask-image: linear-gradient(180deg, rgba(0, 0, 0, 0.65), transparent 90%);
        }

        @media (min-width: 960px) {
            .brand-panel {
                padding: 48px 52px;
            }
        }

        .brand-top {
            position: relative;
            z-index: 1;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
        }

        .brand-lockup {
            display: inline-flex;
            align-items: center;
            gap: 12px;
        }

        .brand-logo-wrap {
            width: 44px;
            height: 44px;
            border-radius: 12px;
            background: rgba(255, 255, 255, 0.12);
            border: 1px solid rgba(255, 255, 255, 0.18);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 5px;
            backdrop-filter: blur(8px);
        }

        .brand-logo-wrap img {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }

        .brand-name {
            font-size: 1.15rem;
            font-weight: 800;
            letter-spacing: -0.02em;
        }

        .env-pill {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 6px 12px;
            border-radius: 999px;
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.15);
            font-size: 12px;
            font-weight: 600;
            color: rgba(255, 255, 255, 0.88);
        }

        .env-dot {
            width: 7px;
            height: 7px;
            border-radius: 50%;
            background: #4ADE80;
            box-shadow: 0 0 0 3px rgba(74, 222, 128, 0.22);
        }

        .brand-hero {
            position: relative;
            z-index: 1;
            max-width: 460px;
        }

        .eyebrow {
            display: inline-block;
            font-size: 12px;
            font-weight: 700;
            letter-spacing: 0.09em;
            text-transform: uppercase;
            color: var(--cyan);
            margin-bottom: 12px;
        }

        .brand-hero h1 {
            font-size: clamp(1.65rem, 3vw, 2.35rem);
            font-weight: 800;
            line-height: 1.18;
            letter-spacing: -0.03em;
            margin-bottom: 14px;
        }

        .brand-hero p {
            color: rgba(226, 238, 252, 0.80);
            font-size: 0.96rem;
            line-height: 1.6;
        }

        .pillars {
            position: relative;
            z-index: 1;
            display: none;
            gap: 12px;
            margin-top: 28px;
        }

        @media (min-width: 960px) {
            .pillars {
                display: grid;
            }
        }

        .pillar {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            padding: 14px 16px;
            border-radius: 14px;
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid rgba(255, 255, 255, 0.11);
            backdrop-filter: blur(8px);
        }

        .pillar-icon {
            width: 34px;
            height: 34px;
            border-radius: 10px;
            background: rgba(91, 192, 235, 0.15);
            color: var(--cyan);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .pillar strong {
            display: block;
            font-size: 13.5px;
            font-weight: 700;
            color: #FFFFFF;
            margin-bottom: 2px;
        }

        .pillar span {
            font-size: 12.5px;
            color: rgba(226, 238, 252, 0.72);
            line-height: 1.45;
        }

        .brand-foot {
            position: relative;
            z-index: 1;
            display: none;
            align-items: center;
            justify-content: space-between;
            font-size: 12px;
            color: rgba(226, 238, 252, 0.56);
            padding-top: 20px;
            border-top: 1px solid rgba(255, 255, 255, 0.10);
        }

        @media (min-width: 960px) {
            .brand-foot { display: flex; }
        }

        /* Panel derecho: formulario de autenticación */
        .auth-panel {
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 32px 20px 44px;
        }

        @media (min-width: 960px) {
            .auth-panel { padding: 48px; }
        }

        .auth-card {
            width: 100%;
            max-width: 420px;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 36px 30px;
            box-shadow:
                0 1px 2px rgba(15, 35, 61, 0.04),
                0 12px 32px -4px rgba(15, 35, 61, 0.08),
                0 24px 60px -12px rgba(15, 35, 61, 0.06);
            animation: cardEnter 0.36s cubic-bezier(0.22, 1, 0.36, 1) both;
        }

        @keyframes cardEnter {
            from { opacity: 0; transform: translateY(12px); }
            to { opacity: 1; transform: translateY(0); }
        }

        @media (prefers-reduced-motion: reduce) {
            .auth-card { animation: none; }
        }

        .auth-head {
            margin-bottom: 26px;
        }

        .auth-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 11.5px;
            font-weight: 700;
            color: var(--navy-800);
            background: #EDF5FC;
            border: 1px solid #D3E5F7;
            padding: 4px 10px;
            border-radius: 999px;
            margin-bottom: 14px;
        }

        .auth-head h2 {
            font-size: 1.55rem;
            font-weight: 800;
            letter-spacing: -0.025em;
            color: var(--ink);
            margin-bottom: 6px;
        }

        .auth-head p {
            font-size: 14px;
            color: var(--ink-muted);
            line-height: 1.5;
        }

        .alert-error {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            background: var(--danger-bg);
            color: var(--danger);
            border: 1px solid var(--danger-border);
            border-radius: var(--radius-md);
            padding: 12px 14px;
            font-size: 13.5px;
            font-weight: 600;
            margin-bottom: 20px;
            line-height: 1.45;
        }

        .field {
            margin-bottom: 18px;
        }

        .field label {
            display: block;
            font-size: 13px;
            font-weight: 700;
            color: var(--ink);
            margin-bottom: 7px;
        }

        .input-group {
            position: relative;
            display: flex;
            align-items: center;
        }

        .input-icon {
            position: absolute;
            left: 14px;
            color: var(--ink-subtle);
            pointer-events: none;
            display: flex;
            align-items: center;
        }

        .input-group input {
            width: 100%;
            min-height: 48px;
            padding: 11px 14px 11px 42px;
            border: 1.5px solid var(--border);
            border-radius: var(--radius-md);
            font-size: 15px;
            color: var(--ink);
            background: #FAFBFD;
            transition: border-color 0.16s ease, box-shadow 0.16s ease, background-color 0.16s ease;
        }

        .input-group input.has-trailing {
            padding-right: 48px;
        }

        .input-group input:hover {
            border-color: var(--border-strong);
        }

        .input-group input:focus {
            outline: none;
            background: #FFFFFF;
            border-color: var(--navy-800);
            box-shadow: 0 0 0 4px rgba(16, 43, 78, 0.10);
        }

        .toggle-pw {
            position: absolute;
            right: 4px;
            width: 44px;
            height: 44px;
            border: none;
            background: transparent;
            color: var(--ink-muted);
            border-radius: 10px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: color 0.15s ease, background-color 0.15s ease;
        }

        .toggle-pw:hover {
            color: var(--ink);
            background: #EEF4FA;
        }

        .toggle-pw:focus-visible {
            outline: 2px solid var(--navy-800);
            outline-offset: -2px;
        }

        .form-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin: 6px 0 22px;
        }

        .checkbox-wrap {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 13.5px;
            font-weight: 600;
            color: var(--ink-muted);
            cursor: pointer;
            min-height: 44px;
        }

        .checkbox-wrap input {
            width: 17px;
            height: 17px;
            accent-color: var(--navy-800);
            cursor: pointer;
        }

        .btn-submit {
            width: 100%;
            min-height: 50px;
            border: none;
            border-radius: var(--radius-md);
            background: var(--navy-800);
            color: #FFFFFF;
            font-size: 15px;
            font-weight: 700;
            letter-spacing: -0.01em;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            box-shadow: 0 1px 2px rgba(16, 43, 78, 0.20), 0 8px 18px -4px rgba(16, 43, 78, 0.28);
            transition: transform 0.14s ease, background-color 0.16s ease, box-shadow 0.16s ease;
        }

        .btn-submit:hover {
            background: var(--navy-700);
            transform: translateY(-1px);
            box-shadow: 0 2px 4px rgba(16, 43, 78, 0.22), 0 12px 24px -6px rgba(16, 43, 78, 0.34);
        }

        .btn-submit:active {
            transform: translateY(0);
        }

        .btn-submit:disabled {
            opacity: 0.72;
            cursor: wait;
            transform: none;
        }

        .security-note {
            margin-top: 22px;
            padding-top: 18px;
            border-top: 1px solid #EDF2F8;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 7px;
            font-size: 12px;
            color: var(--ink-subtle);
            font-weight: 500;
        }
    </style>
</head>
<body>
<div class="split-shell">
    <section class="brand-panel" aria-label="Identidad Leoaventura">
        <div class="brand-top">
            <div class="brand-lockup">
                <div class="brand-logo-wrap">
                    <img src="/images/brand/leoaventura_logo.png" alt="Logo Leoaventura">
                </div>
                <span class="brand-name">Leoaventura</span>
            </div>
            <span class="env-pill">
                <span class="env-dot" aria-hidden="true"></span>
                Sistema Operativo
            </span>
        </div>

        <div class="brand-hero">
            <span class="eyebrow">Consola de Administración</span>
            <h1>Gestiona el aprendizaje y crecimiento desde un solo lugar.</h1>
            <p>
                Supervisa avances reales de lectura, administra planes Gratis y Premium,
                y publica nuevos fonemas en vivo sin recompilar la aplicación.
            </p>

            <div class="pillars">
                <div class="pillar">
                    <div class="pillar-icon" aria-hidden="true">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="m19 9-5 5-4-4-3 3"/></svg>
                    </div>
                    <div>
                        <strong>Analítica pedagógica en vivo</strong>
                        <span>Métricas agregadas de dominio fonético, sesiones y estrellas ganadas.</span>
                    </div>
                </div>
                <div class="pillar">
                    <div class="pillar-icon" aria-hidden="true">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/></svg>
                    </div>
                    <div>
                        <strong>Currículo dinámico de 20+ fonemas</strong>
                        <span>Publica nuevas letras, palabras y dígrafos directamente al motor Flutter.</span>
                    </div>
                </div>
                <div class="pillar">
                    <div class="pillar-icon" aria-hidden="true">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                    </div>
                    <div>
                        <strong>Privacidad infantil COPPA</strong>
                        <span>Acceso privado con límite de intentos, sin rastreadores ni indexación.</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="brand-foot">
            <span>Leoaventura Backoffice</span>
            <span>Acceso restringido · Uso interno</span>
        </div>
    </section>

    <main class="auth-panel">
        <div class="auth-card">
            <div class="auth-head">
                <span class="auth-badge">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                    Acceso restringido
                </span>
                <h2>Iniciar sesión</h2>
                <p>Ingresa con tu cuenta de administrador para continuar.</p>
            </div>

            @if ($errors->any())
                <div class="alert-error" role="alert">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0;margin-top:1px;" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/></svg>
                    <span>{{ $errors->first() }}</span>
                </div>
            @endif

            <form id="admin-login-form" method="POST" action="{{ route('admin.login.submit') }}" novalidate>
                @csrf

                <div class="field">
                    <label for="email">Correo electrónico</label>
                    <div class="input-group">
                        <span class="input-icon" aria-hidden="true">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>
                        </span>
                        <input
                            id="email"
                            type="email"
                            name="email"
                            value="{{ old('email') }}"
                            required
                            autofocus
                            autocomplete="username"
                            placeholder="admin@leoaventura.app"
                        >
                    </div>
                </div>

                <div class="field">
                    <label for="password">Contraseña</label>
                    <div class="input-group">
                        <span class="input-icon" aria-hidden="true">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                        </span>
                        <input
                            id="password"
                            type="password"
                            name="password"
                            class="has-trailing"
                            required
                            autocomplete="current-password"
                            placeholder="Ingresa tu contraseña"
                        >
                        <button
                            type="button"
                            id="toggle-password"
                            class="toggle-pw"
                            aria-label="Mostrar contraseña"
                            aria-pressed="false"
                        >
                            <svg id="eye-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/></svg>
                        </button>
                    </div>
                </div>

                <div class="form-row">
                    <label class="checkbox-wrap">
                        <input type="checkbox" name="remember" value="1">
                        <span>Mantener sesión iniciada</span>
                    </label>
                </div>

                <button type="submit" id="submit-btn" class="btn-submit">
                    <span id="submit-label">Ingresar a la consola</span>
                    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
                </button>
            </form>

            <div class="security-note">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                <span>Sesión protegida contra fuerza bruta · No indexado</span>
            </div>
        </div>
    </main>
</div>

<script>
    (function () {
        const pwInput = document.getElementById('password');
        const toggleBtn = document.getElementById('toggle-password');
        const form = document.getElementById('admin-login-form');
        const submitBtn = document.getElementById('submit-btn');
        const submitLabel = document.getElementById('submit-label');

        if (toggleBtn && pwInput) {
            toggleBtn.addEventListener('click', function () {
                const isHidden = pwInput.type === 'password';
                pwInput.type = isHidden ? 'text' : 'password';
                toggleBtn.setAttribute('aria-pressed', String(isHidden));
                toggleBtn.setAttribute('aria-label', isHidden ? 'Ocultar contraseña' : 'Mostrar contraseña');
            });
        }

        if (form && submitBtn && submitLabel) {
            form.addEventListener('submit', function () {
                submitBtn.disabled = true;
                submitLabel.textContent = 'Verificando credenciales...';
            });
        }
    })();
</script>
</body>
</html>
