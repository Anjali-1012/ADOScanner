Set-StrictMode -Version Latest

. $PSScriptRoot\Framework\Framework.ps1


#These are the topmost folder PS1 files that load 
@("$PSScriptRoot\SVT", "$PSScriptRoot\AlertMonitoring", "$PSScriptRoot\ContinuousAssurance","$PSScriptRoot\AzSKADOInfo", "$PSScriptRoot\STMapping") |
    ForEach-Object {
    (Get-ChildItem -Path $_ -Recurse -File -Include "*.ps1") |
        ForEach-Object {
        . $_.FullName
    }
}


function Set-AzSKADOPrivacyNoticeResponse {
    <#
	.SYNOPSIS
	This command would help to set user preferences for EULA and Privacy.
	.DESCRIPTION
	This command would help to set user preferences for EULA and Privacy.

	.PARAMETER AcceptPrivacyNotice
		Provide the flag to suppress the Privacy notice prompt and submit the acceptance. (Yes/No)

	.LINK
	https://aka.ms/azskossdocs

    #>
    [Alias("Set-AzSKPrivacyNoticeResponse")]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the flag to suppress the Privacy notice prompt and submit the acceptance. (Yes/No)")]
        [string]
        [ValidateSet("Yes", "No")]
		[Alias("apn")]
        $AcceptPrivacyNotice
    )
    Begin {
        [CommandHelper]::BeginCommand($PSCmdlet.MyInvocation);
        [ListenerHelper]::RegisterListeners();
    }
    Process {
        try {
            $azskSettings = [ConfigurationManager]::GetLocalAzSKSettings();

            if ($AcceptPrivacyNotice -eq "yes") {
                $azskSettings.PrivacyNoticeAccepted = $true
                $azskSettings.UsageTelemetryLevel = "Anonymous"
            }

            if ($AcceptPrivacyNotice -eq "no") {
                $azskSettings.PrivacyNoticeAccepted = $false
                $azskSettings.UsageTelemetryLevel = "None"
            }
            [ConfigurationManager]::UpdateAzSKSettings($azskSettings)
            [EventBase]::PublishGenericCustomMessage("Successfully updated privacy settings.");
        }
        catch {
            [EventBase]::PublishGenericException($_);
        }

    }
    End {
        [ListenerHelper]::UnregisterListeners();
    }
}

function Clear-AzSKADOSessionState {

    Write-Host "Clearing $([Constants]::AzSKModuleName) session state..." -ForegroundColor Yellow
    [ConfigOverride]::ClearConfigInstance()
    Write-Host "Session state cleared." -ForegroundColor Yellow

}


function Set-AzSKADOPolicySettings {
    <#
	.SYNOPSIS
	This command would help to set online policy store URL.
	.DESCRIPTION
	This command would help to set online policy store URL.

	.PARAMETER AutoUpdateCommand
			Provide org install URL
	.PARAMETER AutoUpdate
            Toggle the auto-update feature
    #>
    [Alias("Set-AzSKPolicySettings")]
    Param(

        [Parameter(Mandatory = $false, HelpMessage = "Project that hosts ADO organization-specific policy")]
        [Alias("pp")]
        $PolicyProject,

        [Parameter(Mandatory = $false, HelpMessage = "Provide org install URL")]
        [string]
        [Alias("auc")]
        $AutoUpdateCommand,

        [Parameter(Mandatory = $false, ParameterSetName = "AutoUpdatePolicy", HelpMessage = "Toggle the auto-update feature")]
        [ValidateSet("On", "Off", "NotSet")]
        [Alias("au")]
        $AutoUpdate,

        [Parameter(Mandatory = $false, HelpMessage = "Turn org/admin control attestation on/off")]
        [bool]
        [Alias("oca")]
        $EnableOrgControlAttestation,

        [Parameter(Mandatory = $false, HelpMessage = "Provide scanner tool path")]
        [string]
        [Alias("stp")]
        $SecretsScanToolFolder,

        [Parameter(Mandatory = $false, HelpMessage = "Provide scanner tool name")]
        [string]
        [Alias("stn")]
        $SecretsScanToolName,

        [Parameter(Mandatory = $false, HelpMessage = "Branch that hosts ADO organization-specific policy")]
        [string]
        [Alias("bid")]
        $BranchId
    )
    Begin {
        [CommandHelper]::BeginCommand($PSCmdlet.MyInvocation);
        [ListenerHelper]::RegisterListeners();
    }
    Process {
        try {

            $azskSettings = [ConfigurationManager]::GetLocalAzSKSettings();
            
            if (-not [string]::IsNullOrWhiteSpace($AutoUpdateCommand)) 
            {
                $azskSettings.AutoUpdateCommand = $AutoUpdateCommand;
            }
            
            if ($AutoUpdate) 
            {
                $azskSettings.AutoUpdateSwitch = $AutoUpdate
            }
            
            if (-not [string]::IsNullOrWhiteSpace($PolicyProject)) 
            {
                $azskSettings.PolicyProject = $PolicyProject;
            }
            
            if ($EnableOrgControlAttestation) 
            {
                $azskSettings.EnableOrgControlAttestation = $true
            }
            else
            {
                $azskSettings.EnableOrgControlAttestation = $false
            }
            
            if (-not [string]::IsNullOrWhiteSpace($BranchId)) 
            {
                $azskSettings.BranchId = $BranchId;
            }

            if($SecretsScanToolFolder -and $SecretsScanToolName)
            {
                $azskSettings.SecretsScanToolFolder = $SecretsScanToolFolder
                $azskSettings.SecretsScanToolName = $SecretsScanToolName
            }
            
            [ConfigurationManager]::UpdateAzSKSettings($azskSettings);
            [ConfigOverride]::ClearConfigInstance();            
            [EventBase]::PublishGenericCustomMessage("Successfully configured settings.", [MessageType]::Warning);
        }
        catch {
            [EventBase]::PublishGenericException($_);
        }
    }
    End {
        [ListenerHelper]::UnregisterListeners();
    }
}

function Set-AzSKADOUsageTelemetryLevel {
    <#
	.SYNOPSIS
	This command would help to set telemetry level.
	.DESCRIPTION
	This command would help to set telemetry level.

	.PARAMETER Level
		Provide the telemetry level

	#>
    Param(
        [Parameter(Mandatory = $true, HelpMessage = "Provide the telemetry level")]
        [ValidateSet("None", "Anonymous")]
        [string]
		[Alias("lvl")]
        $Level
    )
    Begin {
        [CommandHelper]::BeginCommand($PSCmdlet.MyInvocation);
        [ListenerHelper]::RegisterListeners();
    }
    Process {
        try {
            $azskSettings = [ConfigurationManager]::GetLocalAzSKSettings();
            $azskSettings.UsageTelemetryLevel = $Level
            [ConfigurationManager]::UpdateAzSKSettings($azskSettings);
            [EventBase]::PublishGenericCustomMessage("Successfully set usage telemetry level");
            # clearing session state so that telemetry setting will be immediately effective 
            [ConfigOverride]::ClearConfigInstance()           
        }
        catch {
            [EventBase]::PublishGenericException($_);
        }
    }
    End {
        [ListenerHelper]::UnregisterListeners();
    }
}

function Set-AzSKADOUserPreference {
    <#
	.SYNOPSIS
	This command would help to set user preferences for ADO.
	.DESCRIPTION
	This command would help to set user preferences for ADO.
	.PARAMETER OutputFolderPath
    Provide the custom folder path for output files generated from ADO
	.PARAMETER ResetOutputFolderPath
    Reset the output folder path to default value
	.LINK
	https://aka.ms/adoscanner
	#>
    
    Param
    (
        [Parameter(Mandatory = $false, HelpMessage = "Provide the custom folder path for output files generated from ADO")]
        [string]
		[Alias("ofp")]
        $OutputFolderPath,

        [Parameter(Mandatory = $false, HelpMessage = "Reset the output folder path to default value")]
        [switch]
		[Alias("rofp")]
        $ResetOutputFolderPath

        <#
        [switch]
        [Parameter(Mandatory = $true, ParameterSetName = "EnableComplianceStorage", HelpMessage = "Switch to enable storage of compliance report data at subscription.")]
        [Alias("scus")]
		$StoreComplianceSummaryInUserSubscriptions,

        [switch]
        [Parameter(Mandatory = $false, ParameterSetName = "DisableComplianceStorage", HelpMessage = "Switch to disable storage of compliance report data at subscription.")]
        [Alias("dcsus")]
		$DisableComplianceSummaryStorageInUserSubscriptions
        #>
    )
    Begin {
        [CommandHelper]::BeginCommand($PSCmdlet.MyInvocation);
        [ListenerHelper]::RegisterListeners();
    }
    Process {
        try {
            $azskSettings = [ConfigurationManager]::GetLocalAzSKSettings();
            $flag = $false
            if ($ResetOutputFolderPath) {
                
                $azskSettings.OutputFolderPath = "";
                [EventBase]::PublishGenericCustomMessage("Output folder path has been reset successfully");
                $flag = $true
            }
            elseif (-not [string]::IsNullOrWhiteSpace($OutputFolderPath)) {
                if (Test-Path -Path $OutputFolderPath) {                    
                    $azskSettings.OutputFolderPath = $OutputFolderPath;
                    [EventBase]::PublishGenericCustomMessage("Output folder path has been changed successfully");
                    $flag = $true
                }
                else {
                    [EventBase]::PublishGenericCustomMessage("The specified path does not exist", [MessageType]::Error);
                }
            }
            <#
            if($StoreComplianceSummaryInUserSubscriptions)
            {
                $azskSettings.StoreComplianceSummaryInUserSubscriptions = $true;
            }
            if($DisableComplianceSummaryStorageInUserSubscriptions)
            {
                $azskSettings.StoreComplianceSummaryInUserSubscriptions = $false;
            }
            #>
            if($flag)
            {
                [ConfigurationManager]::UpdateAzSKSettings($azskSettings);
                [EventBase]::PublishGenericCustomMessage("Successfully set user preference");
            }
            else {
                [EventBase]::PublishGenericCustomMessage("No changes done for user preference",[MessageType]::Error);
            }
        }
        catch {
            [EventBase]::PublishGenericException($_);
        }
    }
    End {
        [ListenerHelper]::UnregisterListeners();
    }
}


#$FrameworkPath = $PSScriptRoot

. $FrameworkPath\Helpers\AliasHelper.ps1
