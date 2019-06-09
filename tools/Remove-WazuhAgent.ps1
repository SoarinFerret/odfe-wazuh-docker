#!/usr/bin/pwsh
[CmdletBinding()]
Param(
    [String]$WazuhAPIServer = "127.0.0.1",
    [Parameter(Mandatory=$true)]
    [String]$AgentName,
    [Parameter(Mandatory=$true)]
    [PSCredential]$Credential,
    $Port = 55000,
    [Switch]$UseSSL,
    [Switch]$Force
)

# Param building
$base_url = $(if($UseSSL){"https://"}else{"http://"})+$WazuhAPIServer+":"+$Port

################################################################################
#
#                              Helper Methods
#
################################################################################

function Use-SelfSignedCerts {
    if($PSEdition -ne "Core"){
        add-type @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class PolicyCert : ICertificatePolicy {
                public PolicyCert() {}
                public bool CheckValidationResult(
                    ServicePoint sPoint, X509Certificate cert,
                    WebRequest wRequest, int certProb) {
                    return true;
                }
            }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object PolicyCert
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

    }else{
        Write-Warning -Message "Function not supported in PSCore. Just use the '-SkipCertificateCheck' flag"
    }
}


function req($method, $resource, $params){
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Credential.GetNetworkCredential().username, $Credential.GetNetworkCredential().password)))
    $url = $base_url + $resource;

    if($PSEdition -ne "Core"){
        return Invoke-WebRequest -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method $method -Uri $url -Body $params -UseBasicParsing
    }else{
        return Invoke-WebRequest -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method $method -Uri $url -Body $params -SkipCertificateCheck -UseBasicParsing
    }

}

################################################################################
#
#                              Main Execution
#
################################################################################

# Disable SSL Checking
if($PSEdition -ne "Core"){
    Write-Verbose "Not running Pwsh Core: Enabling use of self-signed certs"
    Use-SelfSignedCerts
}

# Test API integration to make sure IE has run through initial startup dialogue - This can be a problem with new servers.
try{
    $testresponse = (req -method "GET" -resource "/manager/info?pretty").Content | ConvertFrom-Json | select -expand data -ErrorAction Stop -ErrorVariable geterr
    Write-Verbose "The Wazuh manager is contactable via the API, the response is: `n$($testresponse | ft | Out-String)"
}catch{
    throw "Failed to connect to server with the following error: $_"
}

Write-Verbose "Getting agent id for $AgentName"
$agentid = (req -method "GET" -resource "/agents?pretty" -params @{search=$AgentName} | ConvertFrom-Json | select -expand data | select -expand items).id
Write-Verbose "Got agent id of $agentid for $AgentName. Removing agent..."
$response = (req -method "DELETE" -resource "/agents/$agentid" | ConvertFrom-Json)
if($response.error -ne 0){
    throw "Error removing host: $($respose.data)"
}else{
    Write-Verbose "..DONE"
    return $response.data.affected_agents
}