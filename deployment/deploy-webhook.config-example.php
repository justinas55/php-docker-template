<?php

// CONFIGURATION (move to root app folder)
$logDir = '../deployment';
$logFilename = 'deploy-webhook.log';
$logMaxFileSize = 5 * 1024 * 1024; // Maximum file size in bytes (e.g., 5MB)
$logMaxFiles = 1; // Maximum number of historical log files to keep
$allowedTokens = [ // Can use `openssl rand -hex 23` to generate
];
$pathToSSHKey = '~/.ssh/examplekey';
// -------------
