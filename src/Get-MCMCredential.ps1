
function Get-MCMCustomerCredential{
    $Account = $Customer.AccountId
    $ExecutionRole = $config.Service.ExecutionRole
    $RoleSessionName = $config.Service.SessionName
    $RoleArn = "arn:aws:iam::${Account}:role/${ExecutionRole}"
    $Response = (Use-STSRole -Region $config.Service.Region -RoleArn $RoleArn -RoleSessionName $RoleSessionName).Credentials
    $Credentials = New-AWSCredentials -AccessKey $Response.AccessKeyId -SecretKey $Response.SecretAccessKey -SessionToken $Response.SessionToken
    return $Credentials
}
