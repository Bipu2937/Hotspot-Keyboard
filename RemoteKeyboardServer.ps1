# --- SELF-ELEVATION ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms

# --- CONFIGURATION ---
$port = 5005
$ruleName = "Temp_Remote_Keyboard_Rule"

# --- FIREWALL HELPERS ---
function Enable-Firewall {
    Write-Host "Opening Firewall port $port..." -ForegroundColor Gray
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow -Quiet
}

function Disable-Firewall {
    Write-Host "`nCleaning up firewall rules..." -ForegroundColor Gray
    Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
}

function Sanitize-Key([string]$RawKey) {
    $specialChars = @('+', '^', '%', '~', '(', ')', '[', ']', '{', '}')
    if ($specialChars -contains $RawKey) { return "{$RawKey}" }
    return $RawKey
}

function Send-To-PC([string]$Key) {
    try {
        switch ($Key) {
            "ENTER"     { [System.Windows.Forms.SendKeys]::SendWait("{ENTER}") }
            "BACKSPACE" { [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}") }
            "SPACE"     { [System.Windows.Forms.SendKeys]::SendWait(" ") }
            default     { [System.Windows.Forms.SendKeys]::SendWait((Sanitize-Key $Key)) }
        }
    } catch { }
}

# --- STARTUP ---
Clear-Host
# Detecting IP based on the active interface seen in image_e4d83b.png
$activeIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.InterfaceAlias -notmatch "Loopback" -and $_.IPAddress -notlike "169.*"
}).IPAddress | Select-Object -First 1

Write-Host "--- Remote Keyboard Controller ---" -ForegroundColor Cyan
Write-Host "1. Android / Termux (UDP)"
Write-Host "2. iOS / Web (HTTP)"
$choice = Read-Host "Select Mode"

try {
    if ($choice -eq "1") {
        $udpClient = New-Object System.Net.Sockets.UdpClient($port)
        Write-Host "`nListening for Termux on $activeIP : $port..." -ForegroundColor Green
        while ($true) {
            if ($udpClient.Available -gt 0) {
                $endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
                $content = $udpClient.Receive([ref]$endpoint)
                Send-To-PC ([System.Text.Encoding]::UTF8.GetString($content))
            }
            Start-Sleep -Milliseconds 5
        }
    }
    else {
        Enable-Firewall
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://*:$port/")
        $listener.Start()

        Write-Host "`nWeb Server Active!" -ForegroundColor Green
        Write-Host "Open this URL on your phone:" -ForegroundColor Yellow
        Write-Host "http://$($activeIP):$port/" -ForegroundColor White -BackgroundColor Blue

        $html = @"
        <html><head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'></head>
        <body style='background:#111; color:white; font-family:sans-serif; display:flex; flex-direction:column; align-items:center; justify-content:center; height:100vh; margin:0;'>
            <h2 style='color:#00ff00'>Remote Keyboard</h2>
            <input type='text' id='i' autofocus style='padding:20px; width:85%; font-size:24px; border-radius:10px; border:none; outline:none;' autocomplete='off' autocapitalize='off' spellcheck='false'>
            <script>
                const input = document.getElementById('i');
                input.addEventListener('input', (e) => {
                    let char = e.data;
                    if(e.inputType === 'insertLineBreak') char = 'ENTER';
                    if(e.inputType === 'deleteContentBackward') char = 'BACKSPACE';
                    if(char === ' ') char = 'SPACE';
                    if(char) fetch('/?key=' + encodeURIComponent(char));
                    input.value = ''; 
                });
            </script>
        </body></html>
"@
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $keyReceived = $context.Request.QueryString["key"]
            if ($keyReceived) { Send-To-PC $keyReceived }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $context.Response.ContentLength64 = $buffer.Length
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
            $context.Response.Close()
        }
    }
}
catch {
    Write-Host "`nStopping: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # This block runs even if you press Ctrl+C
    if ($choice -eq "2") { 
        if ($listener) { $listener.Stop() }
        Disable-Firewall 
    }
    if ($udpClient) { $udpClient.Close() }
    Write-Host "Server Stopped Safely." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
}