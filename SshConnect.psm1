function New-SshConnectionMenu {
    <#
    .SYNOPSIS
        Shows menu for quick SSH connections.
    .DESCRIPTION
        Shows menu for quick SSH connections. Hosts stored in SshConnect.list text file in your home directory.
        It will be created on the first use. Lines starting with # are comments and will be ignored.
        Lines starting with ; are "visible comments" and will be shown in menu, but nothing else.
        You can use tham to group your hosts. 
        Host comments are in the same string with username@hostname, marked with # and will be shown.
    .NOTES
        This is for personal use. Don't wait more.
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
        $ListFile = [System.IO.Path]::Combine($HOME,'SshConnect.list')
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
                "# This is device list file for New-SshConnectionMenu from SshConnect.psm1 module.",
                "# Lines starting with # are comments and will be ignored.",
                '# Lines starting with ; are "visible comments" and will be shown in menu',
                "# You can use tham to group your hosts.",
                "# Host comments are in the same string with username@hostname, marked with # and will be shown.",
                "# Don't remove this notification.",
                "# Type hosts line by line as: username@hostname # Optional comment"
            ) | Out-File $ListFile -Encoding utf8
        }

        $DeviceList = $ListContent | Where-Object {($PSItem -notlike "#*") -and ($PSItem -notmatch "^\s*$")}

        if ($DeviceList) {
            Write-Host "Select host to connect via SSH:`n"

            $i = 0
            foreach ($Line in $DeviceList) {
                $DeviceConnection, $DeviceUserName, $DeviceHostName, $DeviceComment = $null
                if ($Line -like ";*") {
                    Write-Host $Line.TrimStart(';').Trim() -ForegroundColor DarkGray
                    continue
                }

                $DeviceConnection = $Line.Split('#')[0].Trim()

                if ($Line -like "*#*") {
                    $DeviceComment = $Line.Substring($Line.IndexOf('#'))
                }

                $DeviceUserName = $DeviceConnection.Split('@')[0]
                $DeviceHostName = $DeviceConnection.Split('@')[-1]

                Write-Host "$($i + 1) : $DeviceHostName (as $DeviceUserName)" -NoNewline
                Write-Host " $DeviceComment" -ForegroundColor DarkGray
                $Selectors."dev$i" = $DeviceConnection
                $i++
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
        elseif ($Responce -match "^[Xx]$") {return}
        elseif ($Responce -match "^[Ee]$") {
            Start-Process notepad.exe -ArgumentList $ListFile
        }
        else {
            Write-Error -Message "Selection unknown" -RecommendedAction "Check you choice and try again." -Category InvalidOperation
        }
    }
}
