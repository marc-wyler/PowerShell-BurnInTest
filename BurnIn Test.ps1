### BurnIn Test / Marc Wyler 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '400,400'
$Form.text = "BurnIn Test"
$Form.TopMost = $false

$Label1 = New-Object system.Windows.Forms.Label
$Label1.text = "Information"
$Label1.AutoSize = $true
$Label1.width = 25
$Label1.height = 10
$Label1.location = New-Object System.Drawing.Point(153,24)
$Label1.Font = 'Microsoft Sans Serif,12,style=Bold'

$Textbox = New-Object System.Windows.Forms.TextBox
$Textbox.Text = "This Tool performs a Stress Test on the System.
Restart the System when the Test has ended."
$Textbox.ReadOnly = "true"
$Textbox.Multiline = "True"
$Textbox.width = 315
$Textbox.height = 80
$Textbox.location = New-Object System.Drawing.Point(44,48)

$TextboxProg = New-Object System.Windows.Forms.TextBox
$TextboxProg.Text = "Progress:`r`n"
$TextboxProg.ReadOnly = "true"
$TextboxProg.Multiline = "True"
$TextboxProg.width = 315
$TextboxProg.height = 160
$TextboxProg.location = New-Object System.Drawing.Point(44,138)

$ButtonGo = New-Object system.Windows.Forms.Button
$ButtonGo.text = "Start"
$ButtonGo.width = 60
$ButtonGo.height = 30
$ButtonGo.location = New-Object System.Drawing.Point(44,325)
$ButtonGo.Font = 'Microsoft Sans Serif,10'
$ButtonGo.Add_Click({  
    ### Open Taskmanager 
    $TextboxProg.AppendText("Open Taskmanager`r`n")
    Start-Process taskmgr 


    ### Check Internet Connection on LAN1
    $TxtNetAdapter = "C:\Public\BurnIn\NetAdapter.txt"
    Get-NetAdapter -Name "LAN1" | Out-File -FilePath $TxtNetAdapter
    $CheckNetAdapter = Get-Content $TxtNetAdapter
    $ContainsWord = $CheckNetAdapter | ForEach-Object{$_ -match "Up"}
    If ($ContainsWord -contains $true){
        $TextboxProg.AppendText("Net Connection successfull`r`n")
    } else {
        $TextboxProg.AppendText("Net Connection not successfull!`r`n")
     }
    Remove-Item $TxtNetAdapter

    ### Stress Test CPU // calculation for every core --> CPU 100%
    $TextboxProg.AppendText("CPU Test started ...`r`n")
    $NumberOfLogicalProcessors = Get-WmiObject win32_processor | Select-Object -ExpandProperty NumberOfLogicalProcessors
    ForEach ($core in 1..$NumberOfLogicalProcessors){ 
        Start-Job -ScriptBlock{
            $result = 1;
            foreach ($loopnumber in 1..2147483647){
                $result=1;
                foreach ($loopnumber1 in 1..2147483647){
                    $result=1;
                    foreach($number in 1..2147483647){
                        $result = $result * $number
                    }
                }
                $result  
        }
    }
}

    ###Stress Test Memory
    $TextboxProg.AppendText("Memory Test started ...`r`n")
    Start-Job -ScriptBlock{
    1..50|ForEach-Object{$x=1}{[array]$x+=$x}
    }

    ###Check Harddrive
    $ChkDisk = "C:\Public\disks.txt"
    Get-WmiObject -Class win32_logicaldisk | Out-File $ChkDisk
    
    #Check for VolumeName SystemDisk
    $ChkDiskNames = (Get-Content $ChkDisk | Select-String -Pattern "SystemDisk").Count
    If ($ChkDiskNames -eq 1){
        $TextboxProg.AppendText("SystemDisk existing.`r`n")
    } else { 
        $TextboxProg.AppendText("WARNING: SystemDisk not existing!`r`n")
    }

    #Check for VolumeName BackupDisk
    $ChkDiskNames = (Get-Content $ChkDisk | Select-String -Pattern "Backup").Count
    If ($ChkDiskNames -eq 1){
        $TextboxProg.AppendText("BackupDisk existing.`r`n")
    } else { 
        $TextboxProg.AppendText("WARNING: BackupDisk not existing!`r`n")
    }

    #Check for VolumeName SQLData
    $ChkDiskNames = (Get-Content $ChkDisk | Select-String -Pattern "SQLData").Count
    If ($ChkDiskNames -eq 1){
        $TextboxProg.AppendText("SQLData existing.`r`n")
    } else { 
        $TextboxProg.AppendText("WARNING: SQLData not existing!`r`n")
    }

    #Check for VolumeName SQLLog
    $ChkDiskNames = (Get-Content $ChkDisk | Select-String -Pattern "SQLLog").Count
    If ($ChkDiskNames -eq 1){
        $TextboxProg.AppendText("SQLLog existing.`r`n")
    } else { 
        $TextboxProg.AppendText("WARNING: SQLLog not existing!`r`n")
    }
    Remove-Item $ChkDisk
    
    #Check Health Status
    $ChkHealthDisk = "C:\Public\diskStatus.txt"
    wmic diskdrive get Name,Model,SerialNumber,Size,Status | Out-File $ChkHealthDisk
    $CountDisk = (Get-Content $ChkHealthDisk | Select-String -Pattern " OK").Count 
    If ($CountDisk -lt 4){
        $TextboxProg.AppendText("WARNING: Health Status Harddisks not OK!`r`n")
    } else {
        $TextboxProg.AppendText("Harddisks Health Status OK.`r`n")
    }
    Remove-Item $ChkHealthDisk

    ###Check if IP is set to DHCP
    $CheckDHCP = "C:\Public\DHCP.txt"
    Get-NetIPAddress -InterfaceAlias "LAN1" -AddressFamily IPv4 | Out-File -FilePath $CheckDHCP
    $CheckFile = Get-Content $CheckDHCP
    $ContainsWord = $CheckFile | ForEach-Object{$_ -match "DHCP"}
    if ($ContainsWord -contains $true) {
        $TextboxProg.AppendText("WARNING: Host is set to DHCP!`r`n")
        } else {
        $TextboxProg.AppendText("Host has an assigned IP Address.`r`n")
        }
    Remove-Item $CheckDHCP

    #Timer 
    $timer = 15
    $Counter_Label = New-Object System.Windows.Forms.Label
    $Counter_Label.AutoSize = $true
    $Counter_Label.Width = 15
    $Counter_Label.Height = 10

    $Form.Controls.Add($Counter_Label)
    while ($timer -ge 0){
        $Counter_Label.Text = "Seconds Remaining: ($timer)"
        start-sleep 1
        $timer -= 1      
    }

    if ($timer -lt 1){
        Stop-Job *
        $TextboxProg.AppendText("Check finished!`r`n")
    }
})

$ButtonEnd = New-Object system.Windows.Forms.Button
$ButtonEnd.text = "Stop"
$ButtonEnd.width = 60
$ButtonEnd.height = 30
$ButtonEnd.location = New-Object System.Drawing.Point(168,325)
$ButtonEnd.Font = 'Microsoft Sans Serif,10'
$ButtonEnd.Add_Click({
    #$timer = 1
    Stop-Job *
    $TextboxProg.ResetText()
    $TextboxProg.Text = "Stopped all Tasks"    
})

$Form.controls.AddRange(@($ButtonGo, $ButtonEnd, $Label1, $Textbox, $TextboxProg))
[void] $Form.ShowDialog()