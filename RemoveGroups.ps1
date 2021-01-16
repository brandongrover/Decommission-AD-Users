#Admin Check
$CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent()) 
if (($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) -eq $false) 
{ 
    $ArgumentList = "-noprofile -noexit -file `"{0}`" -Path `"$Path`" -MaxStage $MaxStage" 
    If ($ValidateOnly) { $ArgumentList = $ArgumentList + " -ValidateOnly" } 
    If ($SkipValidation) { $ArgumentList = $ArgumentList + " -SkipValidation $SkipValidation" } 
    If ($Mode) { $ArgumentList = $ArgumentList + " -Mode $Mode" }
    Write-Host "Requires Admin Privilege"  -ForegroundColor red
    Start-Sleep -s 2
    $request = Read-Host -Prompt "Would you like to relaunch as Admin? [y/n]"
    if ( $request -match "[yY]" ) {  
    Start-Process powershell.exe -Verb RunAs -ArgumentList ($ArgumentList -f ($myinvocation.MyCommand.Definition)) -Wait 
    Exit 
    } else {
        Exit
    }
}
Clear-Host

#Vars
$pwd = $MyInvocation.MyCommand.Path
$path = Split-Path $pwd -Parent
$eoeList = Import-Csv -Path $path\DisabledAccounts.csv -Delimiter "," -Header ID
$date = Get-Date -Format "yyyy-MM-dd"

#Header
$item = "*"
Write-Host $item.padright(99,'*')
Write-Host $item.padright(30,"*")" Remove Groups from Disabled Accounts "$item.padright(29,"*")
Write-Host $item.padright(99,'*')

#Build Decomission List
$array = @()
$eoeList | ForEach-Object {
    $array = $array + $_.ID
    }

#Output List to user
Write-Host "Account List:"
foreach($obj in $array) { Write-Host $obj}
Write-Host ""

#Begin removing groups output
Write-Host $item.padright(27,'*')
Write-Host $item.padright(2,'*')"Begin removing groups **"
Write-Host $item.padright(27,'*')
$userList = Get-ADUser -Filter * -SearchBase "CN=Users,DC=homelab,DC=com"  | Where-Object {$_.Enabled -eq $false -or $_.Enabled -eq $null} | Select-Object -Property SamAccountName, SID

$array | ForEach-Object {
    $user = $userList | Where-Object -Property SamAccountName -eq $_

    if($userList.SamAccountName -contains $_) {
    $removeGroupList = Get-ADPrincipalGroupMembership $user.SamAccountName | Where-Object {$_.Name -ne "Domain Users"} | Select name
    $reply = Read-Host -Prompt "Are you sure you want to delete groups from $_ ? [y/n]"
        if ( $reply -match "[yY]" ) {  
            foreach ($name in $removeGroupList.name) {
		        Remove-ADGroupMember -Identity $name -Members $user.SamAccountName
            }
	    }
    Write-Host ""
    Write-Host "Completed removing groups from $_ proceeding to next account."
    } else {
        Write-Host "Unable to find account $_"
    }
}
Write-Host "Completed task."
