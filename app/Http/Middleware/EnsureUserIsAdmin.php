<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsAdmin
{
    /**
     * Restringe el acceso al Backoffice únicamente a cuentas con rol administrador.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user) {
            return redirect()->route('admin.login');
        }

        if (! $user->isAdmin()) {
            abort(Response::HTTP_FORBIDDEN, 'Acceso reservado para administradores de Leoaventura.');
        }

        return $next($request);
    }
}
