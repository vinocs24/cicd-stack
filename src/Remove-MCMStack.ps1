Param(
    [object[]] $Customer
)
Import-Module AWSPowerShell.NetCore
$config = (Get-Content -Raw "config.json") -join "`n" | convertfrom-json
$Wait_Time = 5

function Remove-MCMStackSet {
    if($(Get-MCMStackSet)){
        Remove-MCMStackSetInstance

        ## Below loop removes StackSet once all instances are removed.
        ## May holdup job on runner so set for 30 iterations (2.5 minutes)
        $cnt = 0
        $success = $false
        do{
            try{
                Remove-CFNStackSet -StackSetName $config.Service.StackSetName -Region $config.Service.Region -Confirm:$false -Force -Credential $AccountCred | Out-Null
                $success = $true
            }
            catch {
                ## Put the start-sleep in the catch statement so we don't sleep if the condition is true and waste time
                Write-Host -ForegroundColor Yellow $("INFO : {0} : StackSet still has instances. Waiting {1} seconds." -f $Customer.Name, $Wait_Time)
                Start-sleep -Seconds $Wait_Time
                $cnt++
            }
        } until($success -or $cnt -eq 30)

        if($success) {
            Write-Host -ForegroundColor Green $("SUCCESS : {0} : StackSet {1} has been [ DELETED ]" -f $Customer.Name, $config.Service.StackSetName)
        } else {
            Write-Host -ForegroundColor Blue $("INFO : {0} : StackSet still has instances. Remove will complete in Status Job." -f $Customer.Name)
        }
    }
}

function Get-MCMStackSet {
    try {
        $stackDetails = (Get-CFNStackSet -StackSetName $config.Service.StackSetName -Region $config.Service.Region -Credential $AccountCred)
    } catch {
        Write-Host -ForegroundColor Red $("INFO : {0} : {1}" -f $Customer.Name, $_.Exception.Message)
    }
    return $stackDetails
 }

 function Get-MCMCredential{
    $Account = $Customer.AccountId
    $ExecutionRole = $config.Service.ExecutionRole
    $RoleSessionName = $config.Service.SessionName
    $RoleArn = "arn:aws:iam::${Account}:role/${ExecutionRole}"
    $Response = (Use-STSRole -Region $config.Service.Region -RoleArn $RoleArn -RoleSessionName $RoleSessionName).Credentials
    $Credentials = New-AWSCredentials -AccessKey $Response.AccessKeyId -SecretKey $Response.SecretAccessKey -SessionToken $Response.SessionToken
    return $Credentials
}
$AccountCred = Get-MCMCredential

Remove-MCMStack
