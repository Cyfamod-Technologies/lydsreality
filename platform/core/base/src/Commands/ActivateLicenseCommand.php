<?php

namespace Botble\Base\Commands;

use Botble\Base\Supports\Core;
use Illuminate\Console\Command;

use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Input\InputOption;

#[AsCommand('cms:license:activate', 'Activate license')]
class ActivateLicenseCommand extends Command
{
    public function __construct(protected Core $core)
    {
        parent::__construct();
    }

    public function handle(): int
    {
        $this->core->handleDeactivatedLicense();
        $this->core->clearLicenseReminder();

        $this->components->warn('Legacy license activation has been disabled.');

        return self::SUCCESS;
    }

    protected function configure(): void
    {
        $this->addOption('buyer', null, InputOption::VALUE_REQUIRED, 'The buyer name');
        $this->addOption('purchase_code', null, InputOption::VALUE_REQUIRED, 'The purchase code');
    }
}
