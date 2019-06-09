#!/usr/bin/pwsh
[CmdletBinding()]
Param(
    [String]$WazuhAPIServer = "127.0.0.1",
    [Parameter(Mandatory=$true)]
    [String]$AgentName,
    [String]$AgentIP = 'any',
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
    $url = $base_url + $resource

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

# Test for agent already existing in manager
Write-Verbose "Testing for existing agent with name $AgentName"
$agentexist = req -method "GET" -resource "/agents?pretty" -params @{search=$AgentName} # searches for the agent based on the env variable name
$agentinfo = $agentexist.Content | ConvertFrom-Json | select -expand data | select totalitems

# If agent does not already exist proceed to create agent and register the agent key
if ($agentinfo.totalitems -lt 1){
    if(!$Force){
        $r = Read-Host "Agent does not exist. Would you like to create agent '$agentname'? (y/N)"
        if($r -notlike "y*"){return} #exit script if no response
    }

    Write-Verbose "Agent does not exist. Creating new agent"
    # Adding agent and getting Id from manager
    $response = (req -method "POST" -resource "/agents" -params @{name=$AgentName;ip=$AgentIP}).Content | ConvertFrom-Json
    If ($response.error -ne '0') {
        throw "Failure to add agent: $($response.message)"
    }
    $agentid = $response.data.id
    $agent_key = $response.data.key

    return New-Object psobject -Property @{AgentID=$agentid;Name=$AgentName;AuthKey=$agent_key}
}
Else{
    Write-Verbose "Agent exists. Retrieving authorization key"
    # If agent is found in manager by name it will retrieve the key
    $agentid = ($agentexist.Content | ConvertFrom-Json | select -expand data | select -expand items).id # expands the embedded JSON items to retrieve the agent ID
    $response = (req -method "GET" -resource "/agents/$agentid/key").Content | ConvertFrom-Json
    # Key received from manager
    $agent_key = $response.data

    return New-Object psobject -Property @{AgentID=$agentid;Name=$AgentName;AuthKey=$agent_key}
}