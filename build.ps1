##
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
##

##
#  Builds the source code and generates application package.
#  You can also open the solution file in Visual Studio 2017 and build.
##

param
(
    # Configuration to build.
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = "Release",

    # Platform to build for. 
    [ValidateSet('clean', 'rebuild')]
    [string]$Target = "rebuild",

    # msbuild verbosity level.
    [ValidateSet('quiet','minimal', 'normal', 'detailed', 'diagnostic')]
    [string]$Verbosity = 'minimal',

    # path to msbuild
    [string]$MSBuildFullPath,

    [ValidateSet('win7-x64','linux-x64')]    
    [string]$Runtime = 'win7-x64',

    [bool]$GenerateNuget
)

$ErrorActionPreference = "Stop"
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$NugetFullPath = join-path $PSScriptRoot "nuget.exe"
$SrcRoot = join-path $PSScriptRoot "src\\AutoscaleManager"
$SfProjRoot = join-path $PSScriptRoot "src\\AutoscaleManager\\AutoscaleManager"


if($GenerateNuget -eq $true)
{
   
.\nuget.exe pack .\src\AutoscaleManager\AutoscaleManager\AutoscaleManager.nuspec -basePath out\Release -OutputDirectory out\ -Properties RuntimeIdentifier=$Runtime

exit
}



if ($Target -eq "rebuild") {
    $restore = "-r"
    $buildTarget = "restore;clean;rebuild;package"
} elseif ($Target -eq "clean") {
    $buildTarget = "clean"
}

if($MSBuildFullPath -ne "")
{
    if (!(Test-Path $MSBuildFullPath))
    {
        throw "Unable to find MSBuild at the specified path, run the script again with correct path to msbuild."
    }
}

# msbuild path not provided, find msbuild for VS2017
if($MSBuildFullPath -eq "")
{
    if (${env:VisualStudioVersion} -eq "15.0" -and ${env:VSINSTALLDIR} -ne "")
    {
        $MSBuildFullPath = join-path ${env:VSINSTALLDIR} "MSBuild\15.0\Bin\MSBuild.exe"
    }
}

if($MSBuildFullPath -eq "")
{
    if (Test-Path "env:\ProgramFiles(x86)")
    {
        $progFilesPath =  ${env:ProgramFiles(x86)}
    }
    elseif (Test-Path "env:\ProgramFiles")
    {
        $progFilesPath =  ${env:ProgramFiles}
    }

    $VS2017InstallPath = join-path $progFilesPath "Microsoft Visual Studio\2017"
    $versions = 'Community', 'Professional', 'Enterprise'

    foreach ($version in $versions)
    {
        $VS2017VersionPath = join-path $VS2017InstallPath $version
        $MSBuildFullPath = join-path $VS2017VersionPath "MSBuild\15.0\Bin\MSBuild.exe"

        if (Test-Path $MSBuildFullPath)
        {
            break
        }
    }

    if (!(Test-Path $MSBuildFullPath))
    {
        Write-Host "Visual Studio 2017 installation not found in ProgramFiles, trying to find install path from registry."
        if(Test-Path -Path HKLM:\SOFTWARE\WOW6432Node)
        {
            $VS2017VersionPath = Get-ItemProperty (Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\SxS\VS7 -Name "15.0")."15.0"
        }
        else
        {
            $VS2017VersionPath = Get-ItemProperty (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VS7 -Name "15.0")."15.0"
        }

        $MSBuildFullPath = join-path $VS2017VersionPath "MSBuild\15.0\Bin\MSBuild.exe"
    }
}

if (!(Test-Path $MSBuildFullPath))
{
    throw "Unable to find MSBuild installed on this machine. Please install Visual Studio 2017 or if its installed at non-default location, provide the full ppath to msbuild using -MSBuildFullPath parameter."
}


Set-location -Path $SrcRoot

Set-location -Path $SfProjRoot
Write-Output "Changing the working directory to $SfProjRoot"
Write-Output "Using msbuild from $msbuildFullPath"
$msbuildArgs = @(
    "/nr:false", 
    "/nologo", 
    "$restore"
    "/t:$buildTarget", 
    "/verbosity:$verbosity",  
    "/property:RequestedVerbosity=$verbosity", 
    "/property:Configuration=$configuration",
    "/property:ReferenceRuntimeIdentifier=$Runtime"
    $args)
& $msbuildFullPath $msbuildArgs




Set-location -Path $PSScriptRoot