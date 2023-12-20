<?php declare(strict_types=1);

$autoload_path = getenv('BREF_AUTOLOAD_PATH') ?: '/var/vendor/autoload.php';

require $autoload_path;

$runtime_class = getenv('RUNTIME_CLASS') ?: 'Bref\FpmRuntime\Main';

if (! class_exists($runtime_class)) {
    throw new RuntimeException("Bref is not installed in your application (could not find the class \"$runtime_class\" in Composer dependencies). Did you run \"composer require bref/bref\"?");
}

$runtime_class::run();
