# grab functions from files
get-childitem $psscriptroot\functions\ -filter "*.ps1" | 
? { -not ($_.name.Contains(".Tests.")) } |
? { -not (($_.name).StartsWith("_")) } |
% { . $_.fullname }


$usenative = $true
$lib = "$psscriptroot\lib\publishmap.core.dll"

function loadLib($lib, [scriptblock] $init) {
    $libdir = split-path -parent $lib 

    $OnAssemblyResolve = [System.ResolveEventHandler] {
        param($sender, $e)
        write-warning "resolving assembly '$($e.Name)' by $sender"
        foreach($a in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
            if ($a.FullName -eq $e.Name) {
                return $a
            }
            $splits = $e.Name.Split(",")
            if ($a.GetName().Name -eq $splits[0]) {
                return $a
            }
        }
        Write-Warning "failed to resolve assembly '$($e.name)'"
        return $null
    }


    foreach($asm in (get-childitem $libdir -Filter "*.dll")) {
        try {
            [System.Reflection.Assembly]::LoadFile($asm.fullname)
            #write-host "imported $($asm.Name)"
        } catch {
            write-warning "failed to import $($asm.Name): $($_.Exception.Message)"
        }
    }
    
    try {
       
  
        #      [System.AppDomain]::CurrentDomain.add_AssemblyResolve($OnAssemblyResolve)
        Add-Type -Path "$lib"
        if ($init -ne $null) {
            Invoke-Command $init
        }
        #write-host "lib $lib imported"
       
    } catch {
        throw $_
    }
    finally {
        # [System.AppDomain]::CurrentDomain.remove_AssemblyResolve($OnAssemblyResolve)

    }
}

if ($usenative) {

    loadlib $lib -init { 
        [Publishmap.Utils.Inheritance.Inheritance]::Init()
    }

    function add-property {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline = $true, Position=1)] $object, 
            [Parameter(Mandatory=$true,Position=2)] $name, 
            [Parameter(Mandatory=$true,Position=3)] $value, 
            [switch][bool] $ifNotExists,
            [switch][bool] $overwrite,
            [switch][bool] $merge
        )  
        # Measure-function  "$($MyInvocation.MyCommand.Name)" { 
        if ($object -is [System.Collections.IDictionary]) {
            $r = [Publishmap.Utils.Inheritance.Inheritance]::AddProperty($object, $name, $value, $ifNotExists, $overwrite, $merge)
        }
        else {
            $null = $object | add-member -name $name -membertype noteproperty -value $value
        }
        
        return $object
        #  } 
    }

    
    function add-properties(
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)] 
        $object,
        [Parameter(Mandatory=$true)]
        $props, 
        [switch][bool] $ifNotExists, 
        [switch][bool] $merge, 
        $exclude = @()
    ) {
        # Measure-function  "$($MyInvocation.MyCommand.Name)" { 
        $r = [Publishmap.Utils.Inheritance.Inheritance]::AddProperties($object, $props, $ifNotExists, $merge, $exclude)
        return $object
        #   }
    }


    function add-metaproperties {
        param($group, $fullpath, $specialkeys = @("settings", "global_prof1iles"))
        #Measure-function  "$($MyInvocation.MyCommand.Name)" { 
        [Publishmap.Utils.Inheritance.Inheritance]::AddMetaProperties($group, $fullpath, $specialkeys)      
        return $group      
        # }
    }



    function copy-hashtable($hash) {
        #  Measure-function  "$($MyInvocation.MyCommand.Name)" {
        return [Publishmap.Utils.Inheritance.Inheritance]::CopyHashtable($hash)
        #  }
    }

    function Add-InheritedProperties($from, $to, $exclude = @(), [switch][bool] $valuesOnly) {
        #  Measure-function  "$($MyInvocation.MyCommand.Name)" {
        $r = [Publishmap.Utils.Inheritance.Inheritance]::AddInheritedProperties($from, $to, @($exclude), $valuesOnly)
       
        #  }
    }

    function postprocess-publishmap($map) {    
        #  Measure-function  "$($MyInvocation.MyCommand.Name)" {
        [Publishmap.Utils.Inheritance.Inheritance]::PostProcessPublishmap($map)
        return $map
        #  }
    }

    function Add-GlobalSettings($proj, $settings) {
        #   Measure-function  "$($MyInvocation.MyCommand.Name)" {
        [Publishmap.Utils.Inheritance.Inheritance]::AddGlobalSettings($proj, $settings)
        #   }
    }

    function import-genericgroup($group,
        $fullpath, 
        $settings = $null,
        $settingskey = "settings",
        $specialkeys = @("settings", "global_profiles")
    ) {
        # Measure-function  "$($MyInvocation.MyCommand.Name)" {
        $g = [Publishmap.Utils.Inheritance.Inheritance]::ImportGenericGroup($group, $fullpath, $settings, $settingskey, $specialkeys)
        return $g
        #  }
    }
}
