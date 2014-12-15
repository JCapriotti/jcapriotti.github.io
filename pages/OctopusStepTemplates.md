# Testable PowerShell Octopus Step Templates

I just started using Octopus and love how easy it is to make clean, reusable deployment steps. While you can throw any ad hoc PowerShell script into a deployment project, things that are going to be reused go into step templates. 

Simply put, Octopus describes them as "pre-configured steps that can be reused in multiple projects." A step template can do things like "create a file", "create IIS application", "git pull", etc. 

I did find a [good guide](http://www.lavinski.me/making-great-octopus-powershell-step-templates/) which got me started, but I struggled a bit getting the example to work. So I tweaked it a bit.

## Getting Started 
Step templates are simply PowerShell scripts along with some metadata that defines the title, properties, etc. The template can be edited in a text editor, but Octopus provides a nice editor. To create a new template you can either start fresh or import a template from [the library](https://library.octopusdeploy.com/#!/listing)

### Starting Fresh
* Library -> Step Templates -> Add step template
* Select "Run a PowerShell script" (that's what this article is describing)

### Importing
* Go to [the library](https://library.octopusdeploy.com/#!/listing) and find either a simple step or one that does something similar to what you want to do. 
* Copy the step's JSON go back to Octopus
* Click the Import link, paste the JSON and click Import
* Click on your step to start editing


## Settings & Parameters
This part is pretty basic but give it a useful Name and Description under Settings, then move on to Parameters.

Parameters are what the user fills in when adding a step to a project. The variable name is the most important party, but the label and description should be useful and clear as to what the parameter does.

I created two parameters: RequiredParameter and DefaultedParameter.

![Parameter Editor](/images/OctopusParameters.png)

## Step Script 
First the basics: This is just PowerShell, but with an important hashtable named `$OctopusParameters`. It contains the parameters you defined above, plus [system variables](http://docs.octopusdeploy.com/display/OD/System+variables). To reference a parameter, just index into it with the variable name as the key: 

```powershell
$requiredParameter = $OctopusParameters["RequiredParameter"]
```

Once you start writing your script, IMO it is best to write it in your favorite text editor and test in the PowerShell console. There is too much overhead to write it in the Octopus editor, go to your project, run a deployment and then look at the log files for errors.

Using the [guide](http://www.lavinski.me/making-great-octopus-powershell-step-templates/) I mentioned above to get me started, I came up with a style for writing scripts that work the same both in the console and in Octopus.

First, here is what my sample script looks like:

```powershell
$ErrorActionPreference = "Stop" 
## Utility method for retrieving a parameter
function Get-Parameter($Name, $Default, [switch]$Required) {
    $result = $null

    if ($OctopusParameters -ne $null) {
        $result = $OctopusParameters[$Name]
    }

    if ($result -eq $null) {
        if ($Required) {
            throw "Missing parameter value $Name"
        } else {
            $result = $Default
        }
    }

    return $result
}

# Get the parameters
$requiredParameter = Get-Parameter "RequiredParameter" -Required
$defaultedParameter = Get-Parameter "DefaultedParameter" "default value"

Write-Host "RequiredParameter: $requiredParameter"
Write-Host "DefaultedParameter: $defaultedParameter"
Write-Host "WhatIf: $whatIf"

# Main body of the script goes here!
```

I have a `Get-Parameter` utility function that encapsulates the logic for throwing errors if a required parameter is not present, and specifying default values if an optional parameter is not present.

Unfortunately you can't simply run this step in the console because `$OctopusParameters` does not exist. So this function is used for testing:

```powershell
function Invoke-OctopusStep {
	param (
		[Parameter(Mandatory=$true)]
		[hashtable]$parameters,

		[Parameter(Mandatory=$true)]
		[string]$script
	)
	
	$OctopusParameters = @{}
	foreach ($item in $parameters.GetEnumerator()) {
		$OctopusParameters[$item.Name] = $item.Value;
	}

	& $script
}
```

It takes a hashtable of your parameter's keys/values and the name of the script to execute. And here is how it looks when it is used:

#### Call with No Parameters
```powershell
PS> Invoke-OctopusStep @{} .\step.ps1
Missing parameter value RequiredParameter
At C:\temp\step.ps1:12 char:13
+             throw "Missing parameter value $Name"
+             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+ CategoryInfo          : OperationStopped: (Missing paramet...quiredParameter:String) [], RuntimeException
+ FullyQualifiedErrorId : Missing parameter value RequiredParameter
```

#### Call with required parameter but no default
```powershell
PS> Invoke-OctopusStep @{RequiredParameter="apple"} .\step.ps1
RequiredParameter: apple
DefaultedParameter: default value
WhatIf: False
```
    
#### Call with both the required and defaulted parameter
```powershell
PS> Invoke-OctopusStep @{RequiredParameter="apple"; DefaultedParameter="orange"} .\step.ps1
RequiredParameter: apple
DefaultedParameter: orange
WhatIf: False
```

When calling `Invoke-OctopusStep`, it will also pass through (so to speak) things like -WhatIf. So if you want to handle that parameter in your script, you can just reference it and it works as expected.

#### Call with -WhatIf
```powershell
PS> Invoke-OctopusStep @{RequiredParameter="apple"; DefaultedParameter="orange"} .\step.ps1 -WhatIf
RequiredParameter: apple
DefaultedParameter: orange
WhatIf: True
```


Let me know if you have any thoughts on making this better!

