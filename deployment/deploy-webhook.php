<?php

// To use this script:
// - Setup Git repository, make sure no .env, credential, log, storage files are committed
// - On server where this is deployed setup Git with SSH key, so no password input is required when running git pull
// - Place this file in public directory
// - Configure '$allowedTokens' below - can use `openssl rand -hex 23` to generate it
// - Combine URL where this app is accessible over the internet with secret token, i.e.: https://example-site.com/deploy-webhook.php?t=SECRET_TOKEN
// - Add webhook in your Git provider to call this URL when new commits are pushed to repository
// - Done

// CONFIGURATION
$logDir = '../deployment';
$logFilename = 'deploy-webhook.log';
$logMaxFileSize = 5 * 1024 * 1024; // Maximum file size in bytes (e.g., 5MB)
$logMaxFiles = 1; // Maximum number of historical log files to keep
$allowedTokens = [ // Can use `openssl rand -hex 23` to generate
];
// -------------

function logMessage($message)
{
    global $logDir, $logFilename, $logMaxFiles, $logMaxFileSize;

    $logFilePath = "$logDir/$logFilename";
    $logFilenameDotPos = strrpos($logFilename, '.');
    $logExt = $logFilenameDotPos ? substr($logFilename, $logFilenameDotPos) : '';


    // Check if directory exists, if not create it
    if (!is_dir($logDir)) {
        mkdir($logDir, 0777, true);
    }

    // Check if file exceeds the maximum size
    if (file_exists($logFilePath) && filesize($logFilePath) > $logMaxFileSize) {
        // Roll the file, e.g., rename it
        rename($logFilePath, $logFilePath . '.' . time() . $logExt);
    }

    // Clean up old log files
    $files = glob($logFilePath . '.*');
    if ($files) {
        usort($files, function ($a, $b) {
            $at = filemtime($a);
            $bt = filemtime($b);
            return $at < $bt ? 1 : ($at > $bt ? -1 : 0);
        });

        // Remove old files if more than $maxLogFiles
        while (count($files) > $logMaxFiles) {
            $oldfile = array_pop($files);
            if (!unlink($oldfile)) {
                error_log('could not delete log file: ' . $oldfile);
            }
        }
    }

    // Write the message to the log file
    file_put_contents($logFilePath, date('Y-m-d H:i:s') . ' - ' . $message . PHP_EOL, FILE_APPEND);
}

$clientAddr = $_SERVER['REMOTE_ADDR'];
$token = $_GET['t'] ?? '';
if (!in_array($token, $allowedTokens)) {
    http_response_code(404);
    logMessage("ERROR Client $clientAddr provided invalid token");
    die();
}

$output = shell_exec("(cd .. && git pull --rebase && echo success) 2>&1 ; echo $?");
$outputLines = explode("\n", trim($output));
$exitCodeStr = array_pop($outputLines);
$successLine = array_pop($outputLines);

if ($successLine === 'success' && $exitCodeStr === '0') {
    logMessage("INFO Webhook deployment from client '$clientAddr' successfully executed: `git pull --rebase` succeeded, output: '$output'");
} else {
    logMessage("ERROR Webhook deployment failed from client '$clientAddr', exit code '$exitCodeStr', output: '$output'");
}
