name: Windows Cloudflare Tunnel
on: workflow_dispatch

jobs:
  build:
    runs-on: windows-latest
    steps:
      - name: Enable RDP Access
        run: |
          Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
          Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
          Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1

      - name: Download Cloudflare Tunnel
        run: |
          Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile "cloudflared.exe"

      - name: Start Quick Tunnel
        run: |
          # ব্যাকগ্রাউন্ডে ক্লাউডফ্লায়ার টানেল রান করে লোকাল RDP (পোর্ট ৩৩৮৯) ফরোয়ার্ড করা
          Start-Process -FilePath ".\cloudflared.exe" -ArgumentList "tunnel --url rdp://localhost:3389" -RedirectStandardOutput "tunnel.log" -RedirectStandardError "tunnel_err.log"
          
          # টানেল ইউআরএল জেনারেট হওয়ার জন্য ৫ সেকেন্ড অপেক্ষা
          Start-Sleep -Seconds 5
          
          # জেনারেট হওয়া ট্রাইক্লাউডফ্লায়ার (trycloudflare.com) লিংকটি টার্মিনালে প্রিন্ট করা
          Get-Content "tunnel.log" -Wait -Tail 10

      - name: Keep Runner Alive
        run: |
          Start-Sleep -Seconds 21600

