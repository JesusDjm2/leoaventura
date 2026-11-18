@extends('admin.layout')

@section('title', 'Currículo de Fonemas')

@section('content')
<div class="page-head">
    <div>
        <h1>Gestor de Currículo (Fonemas y Letras)</h1>
        <p>Añade nuevas letras/dígrafos o activa y edita niveles en vivo sin recompilar la app.</p>
    </div>
</div>

<div class="card" style="margin-bottom: 24px;">
    <h2 style="font-size: 1.05rem; font-weight: 900; margin-bottom: 14px;">+ Agregar Nuevo Fonema o Dígrafo (ej. Z, H, CH, LL, RR)</h2>
    <form method="POST" action="{{ route('admin.curriculum.store') }}" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; align-items: end;">
        @csrf
        <div>
            <label style="display: block; font-size: 12px; font-weight: 800; margin-bottom: 4px;">Letra / Dígrafo</label>
            <input type="text" name="letter" required maxlength="4" placeholder="ej. z o ch" style="width: 100%;">
        </div>
        <div>
            <label style="display: block; font-size: 12px; font-weight: 800; margin-bottom: 4px;">Fonema</label>
            <input type="text" name="phoneme" required maxlength="20" placeholder="ej. /s/ o /tʃ/" style="width: 100%;">
        </div>
        <div>
            <label style="display: block; font-size: 12px; font-weight: 800; margin-bottom: 4px;">Palabra ejemplo</label>
            <input type="text" name="example_word" required maxlength="60" placeholder="ej. Zorro" style="width: 100%;">
        </div>
        <div>
            <label style="display: block; font-size: 12px; font-weight: 800; margin-bottom: 4px;">Emoji / Ícono</label>
            <input type="text" name="emoji" maxlength="10" placeholder="🦊" style="width: 100%;">
        </div>
        <div>
            <label style="display: block; font-size: 12px; font-weight: 800; margin-bottom: 4px;">Unidad (1–6)</label>
            <input type="number" name="unit" value="4" min="1" max="6" required style="width: 100%;">
        </div>
        <button type="submit" class="btn btn-primary">Publicar Fonema</button>
    </form>
</div>

<div class="card">
    <div class="table-wrap">
        <table>
            <thead>
            <tr>
                <th>Letra</th>
                <th>Unidad</th>
                <th>Fonema y Palabra</th>
                <th>Actividades</th>
                <th>Estado</th>
                <th>Acciones</th>
            </tr>
            </thead>
            <tbody>
            @foreach ($levels as $level)
                <tr>
                    <td>
                        <span style="display: inline-flex; width: 38px; height: 38px; border-radius: 50%; background: var(--sky); border: 2px solid var(--navy); align-items: center; justify-content: center; font-weight: 900; font-size: 18px;">
                            {{ mb_strtoupper($level->letter) }}
                        </span>
                    </td>
                    <td>Unidad {{ $level->unit }}</td>
                    <td>
                        <form method="POST" action="{{ route('admin.curriculum.update', $level) }}" style="display: flex; flex-wrap: wrap; gap: 6px; align-items: center;">
                            @csrf
                            @method('PUT')
                            <input type="text" name="phoneme" value="{{ $level->phoneme }}" class="input-sm" style="width: 78px;" required>
                            <input type="text" name="example_word" value="{{ $level->example_word }}" class="input-sm" style="width: 130px;" required>
                            <input type="number" name="unit" value="{{ $level->unit }}" min="1" max="6" class="input-sm" style="width: 60px;" required>
                            <button type="submit" class="btn btn-outline btn-sm">Guardar</button>
                        </form>
                    </td>
                    <td>{{ $level->activities_count }} base (+ sílabas/lectura)</td>
                    <td>
                        <span class="badge {{ $level->is_active ? 'badge-active' : 'badge-inactive' }}">
                            {{ $level->is_active ? 'Activo' : 'Oculto' }}
                        </span>
                    </td>
                    <td>
                        <form method="POST" action="{{ route('admin.curriculum.toggle', $level) }}">
                            @csrf
                            @method('PATCH')
                            <button type="submit" class="btn btn-sm {{ $level->is_active ? 'btn-danger' : 'btn-navy' }}">
                                {{ $level->is_active ? 'Ocultar' : 'Activar' }}
                            </button>
                        </form>
                    </td>
                </tr>
            @endforeach
            </tbody>
        </table>
    </div>
</div>
@endsection
