# Prerequisites

Before installing the CDC WSL distribution, you need two things set up on your Windows machine: WSL2 itself, and an elevated privilege account to run the required commands.

## Elevated Privilege Account

Running `wsl --install` and `wsl --update` requires a Windows elevated privilege (`-su`) account. If you do not already have one:

1. Submit a request at [https://ociotools.cdc.gov/ep](https://ociotools.cdc.gov/ep).
2. Your supervisor and ISSO/SSPO (Information System Security Officer / System Security Privacy Officer) will need to approve the request.
3. Once approved, **restart your computer** so the new account is registered by Windows.

Your `-su` account password is stored in [CyberArk](https://cyber.cdc.gov). Retrieve it there when prompted.

## Enable and Update WSL2

Once you have your elevated privilege account, open PowerShell as your `-su` account and run:

```powershell
wsl --install
wsl --update
```
