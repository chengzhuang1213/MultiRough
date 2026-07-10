@echo off
setlocal

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

netsh advfirewall firewall delete rule name="MultiRough Host UDP 24567" >nul 2>&1
netsh advfirewall firewall add rule name="MultiRough Host UDP 24567" dir=in action=allow protocol=UDP localport=24567 remoteip=localsubnet profile=private,public

if not "%errorlevel%"=="0" (
    echo Failed to add the Windows Firewall rule.
    pause
    exit /b 1
)

echo MultiRough hosting is now allowed on UDP port 24567 for the local network.
echo You only need to run this once on the computer that creates the room.
pause
