<?php

namespace Botble\Base\Exceptions;

use Symfony\Component\HttpKernel\Exception\HttpException;

class RequiresLicenseActivatedException extends HttpException
{
    public function __construct($message = 'The remote download service rejected this request.')
    {
        parent::__construct(403, $message);
    }
}
