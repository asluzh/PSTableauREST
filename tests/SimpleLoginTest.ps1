$Config = @{
    server="https://10ax.online.tableau.com";
    username="user@gmail.com";
    password="***";
    site="sandbox";
    # pat_name="";
    # pat_secret="";
}
# alternatively, read the contents from a config file
# $Config = Get-Content $ConfigFile | ConvertFrom-Json
if ($Config.username) {
    $Config | Add-Member -MemberType NoteProperty -Name "credential" -Value (New-Object System.Management.Automation.PSCredential($Config.username, (ConvertTo-SecureString $Config.password -AsPlainText -Force)))
}
if ($Config.pat_name) {
    $Config | Add-Member -MemberType NoteProperty -Name "pat_credential" -Value (New-Object System.Management.Automation.PSCredential($Config.pat_name, (ConvertTo-SecureString $Config.pat_secret -AsPlainText -Force)))
}

if ($Config.pat_name) {
    $response = Connect-TableauServer -Server $Config.server -Site $Config.site -Credential $Config.pat_credential -PersonalAccessToken
} else {
    $response = Connect-TableauServer -Server $Config.server -Site $Config.site -Credential $Config.credential
}
$user = Get-TableauUser -UserId $response.user.id
Write-Host ("Successfully logged in as user: {0} ({1})" -f $user.name, $user.fullName)

# ... do more server operations here

Disconnect-TableauServer | Out-Null