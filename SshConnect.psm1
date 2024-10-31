function New-SshConnectionMenu {
    <#
    .SYNOPSIS
        Shows menu for quick SSH connections.
    .DESCRIPTION
        Shows menu for quick SSH connections. Hosts stored in SshConnect.list text file in module directory.
    .NOTES
        This is for personal use. Don't wait more
    .LINK
        https://github.com/AleksejEgorov/SshConnect
    .EXAMPLE
        New-SshConnectionMenu 
        Show menu based on default list file
    .EXAMPLE
        New-SshConnectionMenu -ListFile $HOME\Documents\SSH_hosts.txt
        Show menu based on your list file
    #>
    
    
    [CmdletBinding()]
    param (
        # Host list file
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [string]$ListFile
    )
    
    $WindowTitle = $host.UI.RawUI.WindowTitle
    if (!$ListFile) {
        $ListFile = [System.IO.Path]::Combine($PSScriptRoot,'SshConnect.list')
    }

    while ($true) {   
        $host.UI.RawUI.WindowTitle = $WindowTitle
        Write-Host '============================================' -ForegroundColor DarkGray
        Write-Host '     Secure shell connector' -ForegroundColor Green
        Write-Host '============================================' -ForegroundColor  DarkGray


        $Selectors = @{}
        if (Test-Path $ListFile) {
            $ListContent = Get-Content $ListFile
        }
        else {
            $ListContent = @()
            @(
                "# This is device list file for SshConnect.ps1 profile script.",
                "# Lines starting with # are comments and will be ignored.",
                "# Don't remove this notification.",
                "# Type hosts line by line as username@hostname"
            ) | Out-File $ListFile -Encoding utf8
        }

        $DeviceList = $ListContent | Where-Object {($PSItem -notlike "#*") -and ($PSItem -notmatch "^\s*$")}

        if ($DeviceList) {
            Write-Host "Select host to connect via SSH:`n"

            for ($i = 0; $i -lt $DeviceList.Count; $i++) {
                $DeviceConnection, $DeviceUserName, $DeviceHostName, $DeviceComment = $null

                $DeviceConnection = $DeviceList[$i].Split('#')[0].Trim()

                if ($DeviceList[$i] -like "*#*") {
                    $DeviceComment = $DeviceList[$i].Substring($DeviceList[$i].IndexOf('#'))
                }

                $DeviceUserName = $DeviceConnection.Split('@')[0]
                $DeviceHostName = $DeviceConnection.Split('@')[-1]

                Write-Host "$($i + 1) : $DeviceHostName (as $DeviceUserName) $DeviceComment"
                $Selectors."dev$i" = $DeviceConnection
            }

        }

        Write-Host "`nE : Edit host list`nR : Reload list`n^C or X : Exit to PowerShell"

        $Responce = Read-Host "Select"

        if ($Responce -match "\d+") {
            $Responce = [int]$Responce - 1
            $host.UI.RawUI.WindowTitle = $Selectors."dev$Responce".Split("@")[1]
            ssh $Selectors."dev$Responce"
        }
        elseif ($Responce -match "^[Rr]$") {}
        elseif ($Responce -match "^[Xx]$") {exit 0}
        elseif ($Responce -match "^[Ee]$") {
            Start-Process notepad.exe -ArgumentList $ListFile
        }
        else {
            Write-Error -Message "Selection unknown" -RecommendedAction "Check you choice and try again." -Category InvalidOperation
        }
    }
}
