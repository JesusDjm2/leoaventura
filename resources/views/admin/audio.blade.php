@extends('admin.layout')

@section('title', 'Estudio de Audio')

@section('content')
<meta name="csrf-token" content="{{ csrf_token() }}">

<style>
    .syl-accordion {
        background: var(--surface);
        border: 1.5px solid var(--border);
        border-radius: 16px;
        overflow: hidden;
        transition: border-color 0.15s ease;
    }
    .syl-accordion[open] {
        border-color: var(--cyan);
        box-shadow: 0 8px 20px rgba(16, 43, 78, 0.06);
    }
    .syl-summary {
        list-style: none;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        padding: 12px 16px;
        cursor: pointer;
        user-select: none;
    }
    .syl-summary::-webkit-details-marker { display: none; }
    .syl-summary:hover { background: #F6FAFE; }
    .syl-chevron {
        transition: transform 0.18s ease;
        color: var(--muted);
        flex-shrink: 0;
    }
    .syl-accordion[open] .syl-chevron { transform: rotate(90deg); }
    .syl-rows {
        border-top: 1px solid #EAF2FA;
        padding: 8px 12px 12px;
        display: flex;
        flex-direction: column;
        gap: 8px;
        background: #FAFCFF;
    }
    .compact-row {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        justify-content: space-between;
        gap: 8px;
        padding: 8px 10px;
        background: #FFFFFF;
        border: 1px solid #E2EEF8;
        border-radius: 12px;
    }
    .compact-left {
        display: flex;
        align-items: center;
        gap: 10px;
        min-width: 150px;
    }
    .compact-badge {
        min-width: 44px;
        height: 34px;
        padding: 0 10px;
        border-radius: 10px;
        background: var(--sky);
        border: 1.5px solid var(--navy);
        display: inline-flex;
        align-items: center;
        justify-content: center;
        font-weight: 900;
        font-size: 14px;
        color: var(--navy);
    }
    .compact-actions {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 6px;
    }
    .compact-audio {
        height: 30px;
        max-width: 175px;
    }
    .compact-draft {
        width: 100%;
        display: none;
        margin-top: 6px;
        padding: 8px 10px;
        background: #FFF8EE;
        border: 1.5px solid var(--orange);
        border-radius: 10px;
    }
</style>

<div class="page-head">
    <div>
        <h1>Estudio de Audio</h1>
        <p>Graba con tu micrófono o sube audios listos. El sistema normaliza el volumen (-16 LUFS), recorta silencios y publica automáticamente en la app.</p>
    </div>
    <span class="badge {{ $ffmpeg_available ? 'badge-active' : 'badge-inactive' }}" style="padding: 8px 14px; font-size: 13px;">
        {{ $ffmpeg_available ? 'Procesamiento automático activo (ffmpeg)' : 'ffmpeg no detectado' }}
    </span>
</div>

<div class="card" style="margin-bottom: 22px;">
    <div style="display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 12px; margin-bottom: 10px;">
        <div>
            <strong style="font-size: 15px;">Progreso del Catálogo de Voces</strong>
            <span id="studio-stats-text" style="font-size: 13.5px; color: var(--muted); margin-left: 8px;">
                🎙️ {{ $stats['recorded'] }} grabadas · 🤖 {{ $stats['pending'] }} sintéticas pendientes ({{ $stats['percent'] }}%)
            </span>
        </div>
        <div style="display: flex; flex-wrap: wrap; gap: 8px; align-items: center;">
            <button type="button" class="btn btn-navy btn-sm tab-btn" data-tab="fonemas">Fonemas ({{ count($groups['fonemas']) }})</button>
            <button type="button" class="btn btn-outline btn-sm tab-btn" data-tab="palabras">Palabras ({{ count($groups['palabras']) }})</button>
            <button type="button" class="btn btn-outline btn-sm tab-btn" data-tab="silabas">Sílabas ({{ count($groups['silabas']) }})</button>
            <button type="button" class="btn btn-outline btn-sm tab-btn" data-tab="instrucciones">Instrucciones ({{ count($groups['instrucciones']) }})</button>
            <button type="button" class="btn btn-outline btn-sm tab-btn" data-tab="mascota">Frases de Leo ({{ count($groups['mascota']) }})</button>
            <input type="text" id="audio-search-input" class="input-sm" placeholder="Buscar palabra o sílaba..." style="width: 185px;">
            <label style="display: inline-flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 700; color: var(--muted); padding: 0 8px; cursor: pointer;">
                <input type="checkbox" id="filter-pending-only">
                <span>Solo pendientes</span>
            </label>
        </div>
    </div>
    <div style="height: 10px; background: #EAF2FA; border-radius: 999px; overflow: hidden;">
        <div id="studio-progress-bar" style="width: {{ $stats['percent'] }}%; height: 100%; background: linear-gradient(90deg, #5BC0EB 0%, #2E7D32 100%); border-radius: 999px; transition: width 0.3s ease;"></div>
    </div>
</div>

<div id="studio-toast" class="alert alert-success" role="status" style="display: none;"></div>

{{-- Pestañas estándar: Fonemas, Palabras, Instrucciones y Frases de Leo --}}
@foreach (['fonemas', 'palabras', 'instrucciones', 'mascota'] as $groupKey)
    @php $slots = $groups[$groupKey]; @endphp
    <section
        class="audio-group"
        data-group="{{ $groupKey }}"
        style="{{ $groupKey === 'fonemas' ? '' : 'display:none;' }}"
    >
        <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(310px, 1fr)); gap: 14px;">
            @foreach ($slots as $slot)
                <article
                    class="card audio-card"
                    data-category="{{ $slot['category'] }}"
                    data-clip-name="{{ $slot['clip_name'] }}"
                    data-recorded="{{ $slot['recorded'] ? '1' : '0' }}"
                    style="display: flex; flex-direction: column; gap: 10px; padding: 16px;"
                >
                    <div style="display: flex; align-items: flex-start; justify-content: space-between; gap: 10px;">
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <span style="width: 40px; height: 40px; border-radius: 12px; background: var(--sky); border: 2px solid var(--navy); display: inline-flex; align-items: center; justify-content: center; font-weight: 900; font-size: {{ strlen($slot['badge']) > 2 ? '11px' : '17px' }}; flex-shrink: 0;">
                                {{ $slot['badge'] }}
                            </span>
                            <div>
                                <h3 style="font-size: 14.5px; font-weight: 800; line-height: 1.25;">{{ $slot['title'] }}</h3>
                                <div style="font-size: 12px; color: var(--muted);">{{ $slot['hint'] }}</div>
                            </div>
                        </div>
                        <span class="badge status-badge {{ $slot['recorded'] ? 'badge-active' : 'badge-premium' }}">
                            {{ $slot['recorded'] ? '🎙️ Grabada' : '🤖 Sintética' }}
                        </span>
                    </div>

                    <div style="background: #F6FAFE; border: 1px solid #DFECF7; border-radius: 10px; padding: 8px 10px; font-size: 13px; font-weight: 600; color: var(--navy); line-height: 1.4;">
                        {{ $slot['script'] }}
                    </div>

                    <div class="published-player-wrap" style="{{ $slot['recorded'] ? '' : 'display:none;' }}">
                        <audio class="published-player" controls preload="none" style="width: 100%; height: 34px;" src="{{ $slot['preview_url'] ?? '' }}"></audio>
                    </div>

                    <div class="draft-wrap" style="display: none; background: #FFF8EE; border: 1.5px solid var(--orange); border-radius: 12px; padding: 8px 10px;">
                        <div style="font-size: 12px; font-weight: 800; color: #9A4D00; margin-bottom: 6px;">Toma lista para revisar:</div>
                        <audio class="draft-player" controls style="width: 100%; height: 32px; margin-bottom: 6px;"></audio>
                        <div style="display: flex; gap: 8px;">
                            <button type="button" class="btn btn-primary btn-sm save-draft-btn" style="flex: 1;">Guardar</button>
                            <button type="button" class="btn btn-outline btn-sm discard-draft-btn">Descartar</button>
                        </div>
                    </div>

                    <div style="display: flex; flex-wrap: wrap; gap: 6px; margin-top: auto;">
                        <button type="button" class="btn btn-navy btn-sm record-btn" style="flex: 1;">
                            <span class="rec-label">🎙️ Grabar</span>
                        </button>
                        <label class="btn btn-outline btn-sm" style="cursor: pointer;">
                            <span>📤 Subir</span>
                            <input type="file" class="file-upload-input" accept="audio/*,.wav,.mp3,.m4a,.ogg,.webm" style="display: none;">
                        </label>
                        <button
                            type="button"
                            class="btn btn-danger btn-sm delete-btn"
                            style="{{ $slot['recorded'] ? '' : 'display:none;' }}"
                        >
                            Borrar
                        </button>
                    </div>

                    <div class="card-feedback" style="font-size: 12px; font-weight: 700; display: none;"></div>
                </article>
            @endforeach
        </div>
    </section>
@endforeach

{{-- Pestaña Sílabas: agrupada por Palabra y por Familia Consonántica (vista compacta colapsable) --}}
<section class="audio-group" data-group="silabas" style="display: none;">
    <div style="display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 10px; margin-bottom: 14px;">
        <div style="display: flex; flex-wrap: wrap; gap: 8px;">
            <button type="button" class="btn btn-primary btn-sm syl-subtab-btn" data-subtab="words">
                Por Palabra ({{ count($syllable_groups['words']) }})
            </button>
            <button type="button" class="btn btn-outline btn-sm syl-subtab-btn" data-subtab="families">
                Por Familia Consonante ({{ count($syllable_groups['families']) }})
            </button>
        </div>
        <div style="display: flex; gap: 8px;">
            <button type="button" id="syl-expand-all" class="btn btn-outline btn-sm">Abrir todos</button>
            <button type="button" id="syl-collapse-all" class="btn btn-outline btn-sm">Cerrar todos</button>
        </div>
    </div>

    @foreach (['words' => $syllable_groups['words'], 'families' => $syllable_groups['families']] as $subKey => $accordions)
        <div
            class="syl-subview"
            data-subview="{{ $subKey }}"
            style="display: {{ $subKey === 'words' ? 'grid' : 'none' }}; grid-template-columns: repeat(auto-fill, minmax(420px, 1fr)); gap: 12px; align-items: start;"
        >
            @foreach ($accordions as $idx => $acc)
                <details class="syl-accordion" data-group-id="{{ $acc['id'] }}" {{ $idx < 2 ? 'open' : '' }}>
                    <summary class="syl-summary">
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <svg class="syl-chevron" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                            <div>
                                <strong style="font-size: 15px;">{{ $acc['title'] }}</strong>
                                <span style="font-size: 12.5px; color: var(--muted); font-weight: 700; margin-left: 8px;">{{ $acc['subtitle'] }}</span>
                            </div>
                        </div>
                        <span class="badge acc-counter {{ $acc['recorded'] === $acc['total'] && $acc['total'] > 0 ? 'badge-active' : 'badge-free' }}">
                            {{ $acc['recorded'] }}/{{ $acc['total'] }}
                        </span>
                    </summary>

                    <div class="syl-rows">
                        @foreach ($acc['slots'] as $slot)
                            <div
                                class="compact-row audio-card"
                                data-category="{{ $slot['category'] }}"
                                data-clip-name="{{ $slot['clip_name'] }}"
                                data-recorded="{{ $slot['recorded'] ? '1' : '0' }}"
                                data-search-extra="{{ $acc['title'] }} {{ $acc['subtitle'] }}"
                            >
                                <div class="compact-left">
                                    <span class="compact-badge">{{ $slot['badge'] }}</span>
                                    <div>
                                        <span class="badge status-badge {{ $slot['recorded'] ? 'badge-active' : 'badge-premium' }}" style="font-size: 11px;">
                                            {{ $slot['recorded'] ? '🎙️ Grabada' : '🤖 Sintética' }}
                                        </span>
                                    </div>
                                </div>

                                <div class="compact-actions">
                                    <div class="published-player-wrap" style="{{ $slot['recorded'] ? '' : 'display:none;' }}">
                                        <audio class="published-player compact-audio" controls preload="none" src="{{ $slot['preview_url'] ?? '' }}"></audio>
                                    </div>
                                    <button type="button" class="btn btn-navy btn-sm record-btn">
                                        <span class="rec-label">🎙️ Grabar</span>
                                    </button>
                                    <label class="btn btn-outline btn-sm" style="cursor: pointer;">
                                        <span>📤</span>
                                        <input type="file" class="file-upload-input" accept="audio/*,.wav,.mp3,.m4a,.ogg,.webm" style="display: none;">
                                    </label>
                                    <button
                                        type="button"
                                        class="btn btn-danger btn-sm delete-btn"
                                        style="{{ $slot['recorded'] ? '' : 'display:none;' }}"
                                        title="Eliminar"
                                    >
                                        ✕
                                    </button>
                                </div>

                                <div class="draft-wrap compact-draft">
                                    <div style="display: flex; flex-wrap: wrap; align-items: center; gap: 8px;">
                                        <audio class="draft-player compact-audio" controls style="flex: 1; max-width: none;"></audio>
                                        <button type="button" class="btn btn-primary btn-sm save-draft-btn">Guardar</button>
                                        <button type="button" class="btn btn-outline btn-sm discard-draft-btn">Descartar</button>
                                    </div>
                                </div>

                                <div class="card-feedback" style="width: 100%; font-size: 11.5px; font-weight: 700; display: none;"></div>
                            </div>
                        @endforeach
                    </div>
                </details>
            @endforeach
        </div>
    @endforeach
</section>

<script>
(function () {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    const uploadUrl = @json(route('admin.audio.upload'));
    const deleteBaseUrl = @json(url(config('admin.path', 'gestion-leo').'/audio'));
    const toast = document.getElementById('studio-toast');
    const pendingFilter = document.getElementById('filter-pending-only');
    const searchInput = document.getElementById('audio-search-input');

    let activeRecorder = null;
    let activeStream = null;
    let activeTimer = null;
    let activeRecordingCard = null;
    const draftBlobs = new WeakMap();

    function showToast(message, isError = false) {
        toast.textContent = message;
        toast.className = 'alert ' + (isError ? 'alert-error' : 'alert-success');
        toast.style.display = 'block';
        clearTimeout(toast._t);
        toast._t = setTimeout(() => { toast.style.display = 'none'; }, 5000);
    }

    function refreshStats() {
        // Deduplica por category/clip_name porque una sílaba puede mostrarse en Palabra y en Familia
        const uniqueMap = new Map();
        document.querySelectorAll('.audio-card').forEach(c => {
            const key = c.dataset.category + '/' + c.dataset.clipName;
            if (!uniqueMap.has(key) || c.dataset.recorded === '1') {
                uniqueMap.set(key, c.dataset.recorded === '1');
            }
        });
        const total = uniqueMap.size;
        let recorded = 0;
        uniqueMap.forEach(isRec => { if (isRec) recorded++; });
        const pct = total > 0 ? Math.round((recorded / total) * 100) : 0;

        const text = document.getElementById('studio-stats-text');
        const bar = document.getElementById('studio-progress-bar');
        if (text) text.textContent = `🎙️ ${recorded} grabadas · 🤖 ${total - recorded} sintéticas pendientes (${pct}%)`;
        if (bar) bar.style.width = `${pct}%`;

        // Actualiza contadores X/Y en cada acordeón de sílabas
        document.querySelectorAll('.syl-accordion').forEach(acc => {
            const rows = Array.from(acc.querySelectorAll('.audio-card'));
            const done = rows.filter(r => r.dataset.recorded === '1').length;
            const badge = acc.querySelector('.acc-counter');
            if (badge) {
                badge.textContent = `${done}/${rows.length}`;
                badge.className = 'badge acc-counter ' + (done === rows.length && rows.length > 0 ? 'badge-active' : 'badge-free');
            }
        });

        applyPendingFilter();
    }

    function applyPendingFilter() {
        const onlyPending = pendingFilter && pendingFilter.checked;
        const term = searchInput ? searchInput.value.trim().toLowerCase() : '';

        document.querySelectorAll('.audio-card').forEach(card => {
            const haystack = (card.textContent + ' ' + (card.dataset.searchExtra || '')).toLowerCase();
            const hideByPending = onlyPending && card.dataset.recorded === '1';
            const hideBySearch = term !== '' && !haystack.includes(term);
            card.style.display = (hideByPending || hideBySearch) ? 'none' : 'flex';
        });

        // Oculta acordeones que quedaron sin filas visibles tras filtrar
        document.querySelectorAll('.syl-accordion').forEach(acc => {
            const visibleRows = Array.from(acc.querySelectorAll('.audio-card')).filter(r => r.style.display !== 'none');
            acc.style.display = visibleRows.length === 0 ? 'none' : '';
            if (term !== '' && visibleRows.length > 0) {
                acc.open = true;
            }
        });
    }

    // Tabs principales
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const target = btn.dataset.tab;
            document.querySelectorAll('.tab-btn').forEach(b => {
                b.className = 'btn btn-sm tab-btn ' + (b.dataset.tab === target ? 'btn-navy' : 'btn-outline');
            });
            document.querySelectorAll('.audio-group').forEach(sec => {
                sec.style.display = sec.dataset.group === target ? '' : 'none';
            });
        });
    });

    // Sub-tabs dentro de Sílabas (Por Palabra / Por Familia)
    document.querySelectorAll('.syl-subtab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const target = btn.dataset.subtab;
            document.querySelectorAll('.syl-subtab-btn').forEach(b => {
                b.className = 'btn btn-sm syl-subtab-btn ' + (b.dataset.subtab === target ? 'btn-primary' : 'btn-outline');
            });
            document.querySelectorAll('.syl-subview').forEach(view => {
                view.style.display = view.dataset.subview === target ? 'grid' : 'none';
            });
        });
    });

    const expandAllBtn = document.getElementById('syl-expand-all');
    const collapseAllBtn = document.getElementById('syl-collapse-all');
    if (expandAllBtn) {
        expandAllBtn.addEventListener('click', () => {
            document.querySelectorAll('.syl-accordion').forEach(a => { a.open = true; });
        });
    }
    if (collapseAllBtn) {
        collapseAllBtn.addEventListener('click', () => {
            document.querySelectorAll('.syl-accordion').forEach(a => { a.open = false; });
        });
    }

    if (pendingFilter) pendingFilter.addEventListener('change', applyPendingFilter);
    if (searchInput) searchInput.addEventListener('input', applyPendingFilter);

    function setCardFeedback(card, msg, isError = false) {
        const fb = card.querySelector('.card-feedback');
        if (!fb) return;
        fb.textContent = msg;
        fb.style.color = isError ? 'var(--danger)' : 'var(--green)';
        fb.style.display = msg ? 'block' : 'none';
    }

    function syncMatchingCards(category, clipName, previewUrl, recorded) {
        const selector = `.audio-card[data-category="${category}"][data-clip-name="${clipName}"]`;
        document.querySelectorAll(selector).forEach(card => {
            card.dataset.recorded = recorded ? '1' : '0';
            const badge = card.querySelector('.status-badge');
            if (badge) {
                badge.textContent = recorded ? '🎙️ Grabada' : '🤖 Sintética';
                badge.className = 'badge status-badge ' + (recorded ? 'badge-active' : 'badge-premium');
            }
            const playerWrap = card.querySelector('.published-player-wrap');
            const player = card.querySelector('.published-player');
            if (playerWrap && player) {
                player.src = recorded && previewUrl ? (previewUrl + '&ts=' + Date.now()) : '';
                playerWrap.style.display = recorded ? '' : 'none';
            }
            const delBtn = card.querySelector('.delete-btn');
            if (delBtn) delBtn.style.display = recorded ? '' : 'none';
            const draft = card.querySelector('.draft-wrap');
            if (draft) draft.style.display = 'none';
        });
    }

    async function uploadBlobOrFile(card, blobOrFile, filename) {
        const category = card.dataset.category;
        const clipName = card.dataset.clipName;
        const formData = new FormData();
        formData.append('category', category);
        formData.append('clip_name', clipName);
        formData.append('audio', blobOrFile, filename);

        setCardFeedback(card, 'Normalizando volumen y publicando...');

        try {
            const resp = await fetch(uploadUrl, {
                method: 'POST',
                headers: {
                    'X-CSRF-TOKEN': csrfToken,
                    'Accept': 'application/json',
                },
                body: formData,
            });
            const data = await resp.json();
            if (!resp.ok || !data.ok) {
                throw new Error(data.message || 'No se pudo procesar el audio.');
            }

            syncMatchingCards(category, clipName, data.preview_url, true);
            draftBlobs.delete(card);

            setCardFeedback(card, 'Publicado (-16 LUFS).');
            showToast(`Audio ${data.clip_id} publicado correctamente.`);
            refreshStats();
        } catch (err) {
            setCardFeedback(card, err.message || 'Error al subir el audio.', true);
            showToast(err.message || 'Error al procesar el audio.', true);
        }
    }

    function stopActiveRecording() {
        if (activeRecorder && activeRecorder.state === 'recording') {
            activeRecorder.stop();
        }
        if (activeStream) {
            activeStream.getTracks().forEach(t => t.stop());
            activeStream = null;
        }
        if (activeTimer) {
            clearInterval(activeTimer);
            activeTimer = null;
        }
        if (activeRecordingCard) {
            const btn = activeRecordingCard.querySelector('.record-btn');
            btn.className = 'btn btn-navy btn-sm record-btn';
            btn.querySelector('.rec-label').textContent = '🎙️ Grabar';
            activeRecordingCard = null;
        }
    }

    document.querySelectorAll('.audio-card').forEach(card => {
        const recordBtn = card.querySelector('.record-btn');
        const fileInput = card.querySelector('.file-upload-input');
        const saveDraftBtn = card.querySelector('.save-draft-btn');
        const discardDraftBtn = card.querySelector('.discard-draft-btn');
        const deleteBtn = card.querySelector('.delete-btn');

        recordBtn.addEventListener('click', async () => {
            if (activeRecordingCard === card) {
                stopActiveRecording();
                return;
            }
            if (activeRecordingCard) {
                stopActiveRecording();
            }

            if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                setCardFeedback(card, 'Tu navegador no permite acceso al micrófono. Usa "Subir".', true);
                return;
            }

            try {
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
                    ? 'audio/webm;codecs=opus'
                    : (MediaRecorder.isTypeSupported('audio/webm') ? 'audio/webm' : '');
                const recorder = mimeType ? new MediaRecorder(stream, { mimeType }) : new MediaRecorder(stream);
                const chunks = [];

                activeStream = stream;
                activeRecorder = recorder;
                activeRecordingCard = card;

                recorder.ondataavailable = e => {
                    if (e.data && e.data.size > 0) chunks.push(e.data);
                };

                recorder.onstop = () => {
                    const blob = new Blob(chunks, { type: recorder.mimeType || 'audio/webm' });
                    draftBlobs.set(card, blob);
                    const draftPlayer = card.querySelector('.draft-player');
                    draftPlayer.src = URL.createObjectURL(blob);
                    card.querySelector('.draft-wrap').style.display = 'block';
                    setCardFeedback(card, 'Revisa tu toma y pulsa "Guardar".');
                };

                recorder.start();
                let seconds = 0;
                recordBtn.className = 'btn btn-danger btn-sm record-btn';
                recordBtn.querySelector('.rec-label').textContent = '⏹ 0:00';
                setCardFeedback(card, 'Grabando...');

                activeTimer = setInterval(() => {
                    seconds++;
                    const m = Math.floor(seconds / 60);
                    const s = String(seconds % 60).padStart(2, '0');
                    recordBtn.querySelector('.rec-label').textContent = `⏹ ${m}:${s}`;
                }, 1000);
            } catch (err) {
                setCardFeedback(card, 'Permiso de micrófono denegado o no disponible.', true);
            }
        });

        saveDraftBtn.addEventListener('click', () => {
            const blob = draftBlobs.get(card);
            if (!blob) return;
            uploadBlobOrFile(card, blob, card.dataset.clipName + '.webm');
        });

        discardDraftBtn.addEventListener('click', () => {
            draftBlobs.delete(card);
            card.querySelector('.draft-wrap').style.display = 'none';
            setCardFeedback(card, '');
        });

        fileInput.addEventListener('change', () => {
            const file = fileInput.files && fileInput.files[0];
            if (!file) return;
            uploadBlobOrFile(card, file, file.name);
            fileInput.value = '';
        });

        deleteBtn.addEventListener('click', async () => {
            const category = card.dataset.category;
            const clipName = card.dataset.clipName;
            if (!confirm(`¿Eliminar la grabación ${category}/${clipName}?`)) return;

            try {
                const resp = await fetch(`${deleteBaseUrl}/${category}/${clipName}`, {
                    method: 'DELETE',
                    headers: {
                        'X-CSRF-TOKEN': csrfToken,
                        'Accept': 'application/json',
                    },
                });
                if (!resp.ok) throw new Error('No se pudo eliminar el audio.');

                syncMatchingCards(category, clipName, '', false);
                setCardFeedback(card, 'Eliminado.');
                refreshStats();
            } catch (err) {
                setCardFeedback(card, err.message, true);
            }
        });
    });
})();
</script>
@endsection
