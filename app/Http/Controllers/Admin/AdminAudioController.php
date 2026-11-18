<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\Admin\AudioStudioService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;
use RuntimeException;
use Symfony\Component\HttpFoundation\Response;

class AdminAudioController extends Controller
{
    public function index(AudioStudioService $studio): View
    {
        return view('admin.audio', $studio->inventory());
    }

    /**
     * Procesa una grabación desde el navegador o archivo subido y la publica automáticamente.
     */
    public function upload(Request $request, AudioStudioService $studio): JsonResponse|RedirectResponse
    {
        $validated = $request->validate([
            'category' => ['required', 'string', 'in:fonemas,palabras,silabas,instrucciones,mascota'],
            'clip_name' => ['required', 'string', 'regex:/^[a-z0-9]+(_[a-z0-9]+)*$/'],
            'audio' => ['required', 'file', 'max:15360'],
        ]);

        try {
            $result = $studio->processAndPublish(
                $validated['category'],
                $validated['clip_name'],
                $request->file('audio')
            );
        } catch (RuntimeException $e) {
            if ($request->expectsJson()) {
                return response()->json(['ok' => false, 'message' => $e->getMessage()], Response::HTTP_UNPROCESSABLE_ENTITY);
            }

            return back()->withErrors(['audio' => $e->getMessage()]);
        }

        if ($request->expectsJson()) {
            return response()->json([
                'ok' => true,
                'message' => 'Audio normalizado y publicado correctamente.',
                ...$result,
            ], Response::HTTP_OK);
        }

        return back()->with('status', "Audio {$result['clip_id']} normalizado y publicado.");
    }

    public function destroy(Request $request, string $category, string $clipName, AudioStudioService $studio): JsonResponse|RedirectResponse
    {
        try {
            $studio->deleteClip($category, $clipName);
        } catch (RuntimeException $e) {
            if ($request->expectsJson()) {
                return response()->json(['ok' => false, 'message' => $e->getMessage()], Response::HTTP_UNPROCESSABLE_ENTITY);
            }

            return back()->withErrors(['audio' => $e->getMessage()]);
        }

        if ($request->expectsJson()) {
            return response()->json(['ok' => true, 'message' => 'Audio eliminado del catálogo.']);
        }

        return back()->with('status', "Audio {$category}/{$clipName} eliminado.");
    }
}
