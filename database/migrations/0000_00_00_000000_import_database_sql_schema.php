<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private const DUMP_PATH = 'database.sql';

    public function up(): void
    {
        $this->assertMysqlDriver();

        $tables = $this->extractTables($this->readDump());

        DB::unprepared('SET FOREIGN_KEY_CHECKS=0;');

        try {
            foreach ($tables as $table) {
                DB::unprepared($table['statement']);
            }
        } finally {
            DB::unprepared('SET FOREIGN_KEY_CHECKS=1;');
        }
    }

    public function down(): void
    {
        $this->assertMysqlDriver();

        $tables = array_reverse($this->extractTables($this->readDump()));

        DB::unprepared('SET FOREIGN_KEY_CHECKS=0;');

        try {
            foreach ($tables as $table) {
                Schema::dropIfExists($table['name']);
            }
        } finally {
            DB::unprepared('SET FOREIGN_KEY_CHECKS=1;');
        }
    }

    private function assertMysqlDriver(): void
    {
        if (DB::getDriverName() !== 'mysql') {
            throw new RuntimeException('This migration only supports MySQL/MariaDB because database.sql is a MySQL dump.');
        }
    }

    private function readDump(): string
    {
        $path = base_path(self::DUMP_PATH);

        if (! File::exists($path)) {
            throw new RuntimeException(sprintf('Could not find SQL dump at "%s".', $path));
        }

        return File::get($path);
    }

    /**
     * @return array<int, array{name: string, statement: string}>
     */
    private function extractTables(string $sql): array
    {
        preg_match_all('/CREATE TABLE `([^`]+)` \(.*?\) ENGINE=.*?;/s', $sql, $matches, PREG_SET_ORDER);

        if (! $matches) {
            throw new RuntimeException('No CREATE TABLE statements were found in database.sql.');
        }

        return array_map(
            fn (array $match): array => [
                'name' => $match[1],
                'statement' => $match[0],
            ],
            $matches
        );
    }
};
