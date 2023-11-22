<?php declare(strict_types=1);

/********************************************************
 *
 * Copies the system dependencies used by a binary/extension.
 *
 * Usage:
 *    php copy-dependencies.php <file-to-analyze> <target-directory>
 *
 * For example:
 *    php copy-dependencies.php /opt/bin/php /opt/lib
 *
 ********************************************************/

if (! ($argv[1] ?? false)) {
    echo 'Missing the first argument, check the file to see how to use it' . PHP_EOL;
    exit(1);
}

if (! ($argv[2] ?? false)) {
    echo 'Missing the second argument, check the file to see how to use it' . PHP_EOL;
    exit(1);
}

[$_, $extension, $target_directory, $libraries_index] = $argv;

// Create the target directory if it doesn't exist
if (! is_dir($target_directory)) {
    mkdir($target_directory, 0777, true);
}

$default_libraries = file(__DIR__ . "/" . $libraries_index);
$default_libraries = array_map('trim', $default_libraries);

// For some reason some libraries are actually not in Lambda, despite being in the docker image 🤷
// $default_libraries = array_filter($default_libraries, function ($extension) {
//     return ! str_contains($extension, 'libgcrypt.so') && ! str_contains($extension, 'libgpg-error.so');
// });

$required_libraries = list_dependencies($extension);

// Exclude existing system libraries
$required_libraries = array_filter($required_libraries, function (string $lib) use ($default_libraries) {
    // Libraries that we compiled are in /opt/lib or /opt/lib64, we compiled them because they are more
    // recent than the ones in Lambda so we definitely want to use them
    $is_compiled_library = str_starts_with($lib, '/opt/lib');
    $is_not_in_lambda = !in_array(basename($lib), $default_libraries, true);

    $keep = $is_compiled_library || $is_not_in_lambda;

    if (! $keep) {
        echo "Skipping $lib because it's already in Lambda" . PHP_EOL;
    }

    return $keep;
});

// Copy all the libraries
foreach ($required_libraries as $library_path) {
    $target_path = $target_directory . '/' . basename($library_path);

    echo "Copying $library_path to $target_path" . PHP_EOL;

    $success = copy($library_path, $target_path);

    if (!$success) {
        throw new RuntimeException("Could not copy $library_path to $target_path");
    }
}


function list_dependencies(string $extension): array {
    // ldd lists the dependencies of a binary or library/extension (.so file)
    exec("ldd $extension 2>&1", $lines);

    if (str_contains(end($lines), 'exited with unknown exit code (139)')) {
        // We can't use `ldd` on binaries (like /opt/bin/php) because it fails on cross-platform builds
        // so we fall back to `LD_TRACE_LOADED_OBJECTS` (which doesn't work for .so files, that's why we also try `ldd`)
        // See https://stackoverflow.com/a/35905007/245552
        $output = shell_exec("LD_TRACE_LOADED_OBJECTS=1 $extension 2>&1");

        if (!$output) {
            throw new RuntimeException("Could not list dependencies for $extension");
        }

        $lines = explode(PHP_EOL, $output);
    }

    $dependencies = [];

    foreach ($lines as $line) {
        if (str_ends_with($line, ' => not found')) {
            throw new RuntimeException("This library is a dependency for $extension but cannot be found by 'ldd':\n$line\n");
        }

        $matches = [];

        if (preg_match('/=> (.*) \(0x[0-9a-f]+\)/', $line, $matches)) {
            $dependencies[] = $matches[1];
        }
    }

    return $dependencies;
}
