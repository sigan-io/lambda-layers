<?php declare(strict_types=1);

if (getenv('BREF_AUTOLOAD_PATH')) {
    require getenv('BREF_AUTOLOAD_PATH');
} else {
    $app_root = getenv('LAMBDA_TASK_ROOT');

    require $app_root . '/vendor/autoload.php';
}

$runtime_class = getenv('RUNTIME_CLASS');

if (! class_exists($runtime_class)) {
    throw new RuntimeException("Bref is not installed in your application (could not find the class \"$runtime_class\" in Composer dependencies). Did you run \"composer require bref/bref\"?");
}

$runtime_class::run();
