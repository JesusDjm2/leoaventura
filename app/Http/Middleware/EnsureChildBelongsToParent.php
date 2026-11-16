<?php

namespace App\Http\Middleware;

use App\Models\Child;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureChildBelongsToParent
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $child = $request->route('child');

        if ($child) {
            if (! $child instanceof Child) {
                $child = Child::findOrFail($child);
            }

            if ((int) $child->user_id !== (int) $request->user()?->id) {
                abort(403, 'Acceso denegado: este perfil no pertenece al padre autenticado.');
            }
        }

        return $next($request);
    }
}
