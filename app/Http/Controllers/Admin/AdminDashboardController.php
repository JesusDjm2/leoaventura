<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\Admin\AdminDashboardService;
use Illuminate\View\View;

class AdminDashboardController extends Controller
{
    public function index(AdminDashboardService $dashboardService): View
    {
        return view('admin.dashboard', $dashboardService->summary());
    }
}
