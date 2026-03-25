<?php

namespace Botble\Installer\Http\Controllers;

use Botble\Base\Http\Controllers\BaseController;
use Carbon\Carbon;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\URL;

class LicenseController extends BaseController
{
    public function index(): RedirectResponse
    {
        return $this->redirectToFinalStep();
    }

    public function store(): RedirectResponse
    {
        return $this->redirectToFinalStep();
    }

    public function skip(): RedirectResponse
    {
        return $this->redirectToFinalStep();
    }

    protected function redirectToFinalStep(): RedirectResponse
    {
        return redirect()->to(URL::temporarySignedRoute('installers.final', Carbon::now()->addMinutes(30)));
    }
}
