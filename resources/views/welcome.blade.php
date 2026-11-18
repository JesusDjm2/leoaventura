<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Leoaventura — Aprende a Leer Jugando</title>
    <meta name="description" content="Leoaventura ayuda a niños de 3 a 6 años a aprender a leer en español jugando con 20 fonemas, trazado táctil, sílabas mágicas y lectura guiada junto al León Leo.">
    <style>
        :root {
            --sky-top: #CBE9FF;
            --sky: #D9F0FF;
            --sky-light: #F3FAFF;
            --navy: #102B4E;
            --navy-soft: #1B3E6B;
            --muted: #4A6482;
            --orange: #FF9E3D;
            --orange-dark: #DF7A17;
            --green: #62C462;
            --green-dark: #2E7D32;
            --cyan: #5BC0EB;
            --surface: #FFFFFF;
            --border: #D4E7F7;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }
        html { scroll-behavior: smooth; }

        body {
            min-height: 100dvh;
            background: linear-gradient(180deg, var(--sky-top) 0%, var(--sky) 36%, var(--sky-light) 100%);
            color: var(--navy);
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            -webkit-font-smoothing: antialiased;
            overflow-x: hidden;
        }

        /* Cielo vivo con nubes sutiles en GPU */
        .sky-layer {
            position: fixed;
            inset: 0;
            pointer-events: none;
            z-index: 0;
            overflow: hidden;
        }
        .cloud {
            position: absolute;
            background: rgba(255, 255, 255, 0.72);
            border-radius: 999px;
            will-change: transform;
        }
        .cloud::before, .cloud::after {
            content: "";
            position: absolute;
            background: inherit;
            border-radius: 50%;
        }
        .cloud-1 {
            top: 72px; left: -120px; width: 130px; height: 42px;
            animation: driftRight 34s linear infinite;
        }
        .cloud-1::before { width: 58px; height: 58px; top: -26px; left: 20px; }
        .cloud-1::after { width: 46px; height: 46px; top: -18px; right: 18px; }

        .cloud-2 {
            top: 210px; left: -160px; width: 104px; height: 34px; opacity: 0.65;
            animation: driftRight 46s linear infinite 11s;
        }
        .cloud-2::before { width: 46px; height: 46px; top: -20px; left: 16px; }
        .cloud-2::after { width: 38px; height: 38px; top: -14px; right: 14px; }

        .sun-glow {
            position: absolute;
            top: -50px; right: -40px;
            width: 240px; height: 240px;
            border-radius: 50%;
            background: radial-gradient(circle, rgba(255, 213, 79, 0.45) 0%, rgba(255, 158, 61, 0.16) 45%, transparent 72%);
            animation: sunBreathe 6s ease-in-out infinite;
        }

        @keyframes driftRight {
            from { transform: translate3d(-40px, 0, 0); }
            to { transform: translate3d(calc(100vw + 220px), 0, 0); }
        }
        @keyframes sunBreathe {
            0%, 100% { transform: scale(1); opacity: 0.9; }
            50% { transform: scale(1.08); opacity: 1; }
        }
        @keyframes leoFloat {
            0%, 100% { transform: translate3d(0, 0, 0) rotate(-1deg); }
            50% { transform: translate3d(0, -10px, 0) rotate(1.5deg); }
        }

        .container {
            position: relative;
            z-index: 1;
            width: 100%;
            max-width: 1080px;
            margin: 0 auto;
            padding: 0 20px;
        }

        /* Header */
        header {
            padding: 18px 0;
        }
        .nav-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
        }
        .brand {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            text-decoration: none;
            color: var(--navy);
            font-weight: 900;
            font-size: 1.25rem;
            letter-spacing: -0.02em;
        }
        .brand img {
            width: 44px;
            height: 44px;
            object-fit: contain;
        }
        .nav-cta {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            min-height: 46px;
            padding: 10px 18px;
            border-radius: 999px;
            background: var(--navy);
            color: #FFFFFF;
            text-decoration: none;
            font-weight: 800;
            font-size: 14px;
            box-shadow: 0 6px 16px rgba(16, 43, 78, 0.18);
            transition: transform 0.16s cubic-bezier(0.22, 1, 0.36, 1), background-color 0.16s ease;
        }
        .nav-cta:hover { transform: translateY(-2px); background: var(--navy-soft); }

        /* Hero asimétrico */
        .hero {
            padding: 28px 0 40px;
            display: grid;
            grid-template-columns: 1fr;
            gap: 32px;
            align-items: center;
        }
        @media (min-width: 860px) {
            .hero {
                padding: 44px 0 56px;
                grid-template-columns: 1.12fr 0.88fr;
                gap: 44px;
            }
        }
        .pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(255, 255, 255, 0.85);
            border: 1.5px solid var(--cyan);
            color: var(--green-dark);
            font-weight: 800;
            font-size: 12.5px;
            padding: 6px 14px;
            border-radius: 999px;
            margin-bottom: 16px;
        }
        .hero h1 {
            font-size: clamp(2.1rem, 4.6vw, 3.25rem);
            font-weight: 900;
            line-height: 1.1;
            letter-spacing: -0.03em;
            margin-bottom: 16px;
        }
        .hero h1 .accent {
            color: #D66B08;
        }
        .hero p.lead {
            font-size: clamp(1rem, 1.8vw, 1.14rem);
            line-height: 1.65;
            color: var(--muted);
            max-width: 540px;
            margin-bottom: 26px;
        }
        .hero-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 14px;
            align-items: center;
        }
        .btn-play {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            min-height: 58px;
            padding: 14px 28px;
            border-radius: 22px;
            background: var(--orange);
            color: var(--navy);
            border: 2.5px solid var(--navy);
            box-shadow: 0 5px 0 var(--orange-dark), 0 12px 24px rgba(223, 122, 23, 0.25);
            text-decoration: none;
            font-size: 1.08rem;
            font-weight: 900;
            transition: transform 0.14s cubic-bezier(0.34, 1.56, 0.64, 1), box-shadow 0.14s ease;
        }
        .btn-play:hover {
            transform: translateY(-2px) scale(1.02);
            box-shadow: 0 7px 0 var(--orange-dark), 0 16px 28px rgba(223, 122, 23, 0.30);
        }
        .btn-play:active {
            transform: translateY(2px) scale(0.98);
            box-shadow: 0 2px 0 var(--orange-dark);
        }
        .hero-trust {
            display: flex;
            flex-wrap: wrap;
            gap: 16px;
            margin-top: 22px;
            font-size: 13px;
            font-weight: 700;
            color: var(--muted);
        }

        /* Escenario interactivo de Leo */
        .hero-stage {
            position: relative;
            background: rgba(255, 255, 255, 0.90);
            border: 2.5px solid var(--cyan);
            border-radius: 32px;
            padding: 28px 24px;
            box-shadow: 0 22px 48px rgba(16, 43, 78, 0.12), 0 4px 12px rgba(16, 43, 78, 0.06);
            text-align: center;
            backdrop-filter: blur(8px);
        }
        .leo-ring {
            width: 172px;
            height: 172px;
            margin: 0 auto 16px;
            border-radius: 50%;
            background: radial-gradient(circle, rgba(255, 158, 61, 0.32) 0%, rgba(255, 213, 79, 0.18) 65%, transparent 100%);
            border: 3px solid var(--orange);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: transform 0.18s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .leo-ring:hover { transform: scale(1.05); }
        .leo-ring img {
            width: 146px;
            height: 146px;
            object-fit: contain;
            animation: leoFloat 3.6s ease-in-out infinite;
        }
        .speech-bubble {
            display: inline-block;
            background: var(--sky-light);
            border: 1.5px solid var(--border);
            border-radius: 18px;
            padding: 10px 16px;
            font-size: 14.5px;
            font-weight: 800;
            color: var(--navy);
            margin-bottom: 18px;
            min-height: 44px;
        }
        .demo-letters {
            display: flex;
            justify-content: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        .letter-btn {
            width: 60px;
            height: 60px;
            border-radius: 18px;
            border: 2px solid var(--navy);
            background: #FFFFFF;
            color: var(--navy);
            font-size: 24px;
            font-weight: 900;
            cursor: pointer;
            box-shadow: 0 4px 0 #C4DBEE;
            transition: transform 0.14s cubic-bezier(0.34, 1.56, 0.64, 1), background-color 0.14s ease;
        }
        .letter-btn:hover { transform: translateY(-3px) scale(1.06); background: #FFF5E6; }
        .letter-btn.active {
            background: var(--orange);
            box-shadow: 0 4px 0 var(--orange-dark);
            transform: scale(1.08);
        }
        .demo-hint {
            margin-top: 12px;
            font-size: 12.5px;
            font-weight: 700;
            color: var(--muted);
        }

        /* Sección 4 pasos pedagógicos */
        .section {
            padding: 36px 0 64px;
            scroll-margin-top: 24px;
        }
        .section-head {
            text-align: center;
            max-width: 620px;
            margin: 0 auto 30px;
        }
        .section-head h2 {
            font-size: clamp(1.55rem, 3.2vw, 2.15rem);
            font-weight: 900;
            letter-spacing: -0.02em;
            margin-bottom: 8px;
        }
        .section-head p {
            color: var(--muted);
            font-size: 0.98rem;
            line-height: 1.55;
        }
        .steps-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 18px;
        }
        .step-card {
            background: var(--surface);
            border: 1.5px solid var(--border);
            border-radius: 24px;
            padding: 22px 20px;
            box-shadow: 0 10px 26px rgba(16, 43, 78, 0.07);
            transition: transform 0.2s cubic-bezier(0.22, 1, 0.36, 1), box-shadow 0.2s ease;
        }
        .step-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 16px 34px rgba(16, 43, 78, 0.11);
        }
        .step-num {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 40px;
            height: 40px;
            border-radius: 14px;
            font-weight: 900;
            font-size: 18px;
            margin-bottom: 12px;
        }
        .step-card h3 {
            font-size: 1.08rem;
            font-weight: 800;
            margin-bottom: 6px;
        }
        .step-card p {
            font-size: 14px;
            line-height: 1.55;
            color: var(--muted);
        }

        /* Animación de entrada por scroll */
        .reveal {
            opacity: 0;
            transform: translate3d(0, 18px, 0);
            transition: opacity 0.5s cubic-bezier(0.22, 1, 0.36, 1), transform 0.5s cubic-bezier(0.22, 1, 0.36, 1);
        }
        .reveal.is-visible {
            opacity: 1;
            transform: translate3d(0, 0, 0);
        }

        footer {
            padding: 24px 0 36px;
            text-align: center;
            font-size: 13px;
            font-weight: 600;
            color: var(--muted);
            border-top: 1px solid rgba(16, 43, 78, 0.08);
        }

        @media (prefers-reduced-motion: reduce) {
            .cloud, .sun-glow, .leo-ring img { animation: none !important; }
            .reveal { opacity: 1 !important; transform: none !important; transition: none !important; }
        }
    </style>
</head>
<body>
    <div class="sky-layer" aria-hidden="true">
        <div class="sun-glow"></div>
        <div class="cloud cloud-1"></div>
        <div class="cloud cloud-2"></div>
    </div>

    <div class="container">
        <header>
            <nav class="nav-bar" aria-label="Navegación principal">
                <a href="{{ route('portal.home') }}" class="brand">
                    <img src="/images/brand/leoaventura_logo.png" alt="Logo Leoaventura" width="44" height="44" fetchpriority="high">
                    <span>Leoaventura</span>
                </a>
                <a href="{{ $appWebUrl }}" class="nav-cta">
                    <span>Abrir App Web</span>
                    <span aria-hidden="true">→</span>
                </a>
            </nav>
        </header>

        <main>
            <section class="hero">
                <div>
                    <span class="pill">✨ Lectura inicial · 3 a 6 años · 100% Gratis</span>
                    <h1>Aprender a leer se vuelve su <span class="accent">aventura favorita</span>.</h1>
                    <p class="lead">
                        Con el León Leo y el método de fonética sintética, tu pequeño descubre el sonido real de las 20 letras esenciales, traza con chispas mágicas, junta sílabas y lee sus primeras palabras sin frustración.
                    </p>
                    <div class="hero-actions">
                        <a href="{{ $appWebUrl }}" class="btn-play">
                            <span>Comenzar a Jugar</span>
                            <span aria-hidden="true">→</span>
                        </a>
                    </div>
                    <div class="hero-trust">
                        <span>🛡️ Sin anuncios</span>
                        <span>🔒 Privacidad infantil COPPA</span>
                        <span>📊 Reporte para padres en PDF</span>
                    </div>
                </div>

                <div class="hero-stage" aria-label="Prueba interactiva de sonidos con Leo">
                    <button type="button" id="leo-stage-btn" class="leo-ring" aria-label="Tocar al León Leo para escuchar un saludo">
                        <img src="/images/brand/leo_mascot.png" alt="León Leo, tu guía de lectura" width="146" height="146" fetchpriority="high">
                    </button>
                    <div id="leo-speech" class="speech-bubble" role="status" aria-live="polite">
                        ¡Hola! Toca una letra para escuchar cómo suena con Leo.
                    </div>
                    <div class="demo-letters" role="group" aria-label="Letras interactivas de muestra">
                        <button type="button" class="letter-btn" data-letter="M" data-cue="Mmm, M con A suena MA, como en Mamá">M</button>
                        <button type="button" class="letter-btn" data-letter="P" data-cue="Ppp, P con A suena PA, como en Pato">P</button>
                        <button type="button" class="letter-btn" data-letter="S" data-cue="Sss, S con O suena SO, como en Sol">S</button>
                        <button type="button" class="letter-btn" data-letter="A" data-cue="Aaa, A como en Árbol">A</button>
                    </div>
                    <p class="demo-hint">Toca a Leo o cualquier letra para probar el audio infantil</p>
                </div>
            </section>

            <section class="section" aria-labelledby="metodo-title">
                <div class="section-head reveal">
                    <h2 id="metodo-title">4 pasos divertidos en cada letra</h2>
                    <p>Cada uno de los 20 fonemas guía al niño de forma natural desde el trazo hasta leer su primera palabra completa.</p>
                </div>

                <div class="steps-grid">
                    <article class="step-card reveal">
                        <div class="step-num" style="background:#FFF0DF;color:#D66B08;">1</div>
                        <h3>Traza con estrellitas</h3>
                        <p>Una estrellita guía muestra por dónde empezar y el trazo suelta chispas de colores al avanzar.</p>
                    </article>
                    <article class="step-card reveal">
                        <div class="step-num" style="background:#E3F6FD;color:#0E6A96;">2</div>
                        <h3>Escucha y descubre</h3>
                        <p>El niño escucha el sonido puro del fonema y encuentra el dibujo correcto con ayuda empática de Leo.</p>
                    </article>
                    <article class="step-card reveal">
                        <div class="step-num" style="background:#E8F6E8;color:#2E7D32;">3</div>
                        <h3>Sílabas mágicas</h3>
                        <p>Junta consonantes y vocales (M + A = MA) viendo y escuchando cómo se fusionan en tiempo real.</p>
                    </article>
                    <article class="step-card reveal">
                        <div class="step-num" style="background:#F2EBFF;color:#5B35A8;">4</div>
                        <h3>Lee tu primera palabra</h3>
                        <p>Decodifica sílaba por sílaba en tipografía escolar Andika y celebra con burbujas y estrellas voladoras.</p>
                    </article>
                </div>
            </section>
        </main>

        <footer>
            Leoaventura · Educación inicial lúdica, segura y libre de anuncios.
        </footer>
    </div>

    <script>
        (function () {
            const speechEl = document.getElementById('leo-speech');
            const leoBtn = document.getElementById('leo-stage-btn');
            const letterBtns = document.querySelectorAll('.letter-btn');

            function speakEs(text) {
                if (!('speechSynthesis' in window)) return;
                try {
                    window.speechSynthesis.cancel();
                    const u = new SpeechSynthesisUtterance(text);
                    u.lang = 'es-ES';
                    u.rate = 0.88;
                    u.pitch = 1.06;
                    window.speechSynthesis.speak(u);
                } catch (_) {}
            }

            if (leoBtn && speechEl) {
                leoBtn.addEventListener('click', function () {
                    const msg = '¡Hola! Soy el León Leo. ¿Jugamos a descubrir letras hoy?';
                    speechEl.textContent = msg;
                    speakEs(msg);
                });
            }

            letterBtns.forEach(function (btn) {
                btn.addEventListener('click', function () {
                    letterBtns.forEach(function (b) { b.classList.remove('active'); });
                    btn.classList.add('active');
                    const cue = btn.getAttribute('data-cue') || '';
                    if (speechEl) speechEl.textContent = '🔊 ' + cue + '!';
                    speakEs(cue);
                });
            });

            // Revelado suave por scroll (respetando prefers-reduced-motion)
            const reveals = document.querySelectorAll('.reveal');
            if ('IntersectionObserver' in window && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
                const io = new IntersectionObserver(function (entries) {
                    entries.forEach(function (entry) {
                        if (entry.isIntersecting) {
                            entry.target.classList.add('is-visible');
                            io.unobserve(entry.target);
                        }
                    });
                }, { threshold: 0.15 });
                reveals.forEach(function (el) { io.observe(el); });
            } else {
                reveals.forEach(function (el) { el.classList.add('is-visible'); });
            }
        })();
    </script>
</body>
</html>
