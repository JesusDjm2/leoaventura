<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreChildRequest;
use App\Models\Child;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ChildController extends Controller
{
    /**
     * List all children associated with the authenticated parent.
     */
    public function index(Request $request): JsonResponse
    {
        $children = $request->user()->children()->latest()->get();

        return response()->json([
            'data' => $children,
        ], Response::HTTP_OK);
    }

    /**
     * Store a new child profile for the authenticated parent.
     */
    public function store(StoreChildRequest $request): JsonResponse
    {
        $child = $request->user()->children()->create([
            'name' => $request->name,
            'birth_date' => $request->birth_date,
            'avatar_key' => $request->avatar_key ?? 'leon_leo',
            'reading_level' => $request->reading_level ?? 'vocales',
            'accessibility_settings' => $request->accessibility_settings ?? [
                'audio_feedback' => true,
                'high_contrast' => false,
                'voice_speed' => 'normal',
            ],
        ]);

        return response()->json([
            'message' => 'Perfil de párvulo creado con éxito.',
            'data' => $child,
        ], Response::HTTP_CREATED);
    }

    /**
     * Display the specified child profile.
     */
    public function show(Child $child): JsonResponse
    {
        return response()->json([
            'data' => $child,
        ], Response::HTTP_OK);
    }

    /**
     * Update the specified child profile.
     */
    public function update(StoreChildRequest $request, Child $child): JsonResponse
    {
        $child->update($request->validated());

        return response()->json([
            'message' => 'Perfil de párvulo actualizado con éxito.',
            'data' => $child->fresh(),
        ], Response::HTTP_OK);
    }

    /**
     * Remove the specified child profile.
     */
    public function destroy(Child $child): JsonResponse
    {
        $child->delete();

        return response()->json([
            'message' => 'Perfil de párvulo eliminado con éxito.',
        ], Response::HTTP_OK);
    }
}
