##
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
##

##
#  Builds the source code and generates application package.
#  You can also open the solution file in Visual Studio 2019 and build.
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
.\nuget.exe pack .\src\AutoscaleManager\AutoscaleManager\AutoscaleManagerWindows.nuspec -basePath .\out\Release\win7-x64 -OutputDirectory out\NugetPackages 
.\nuget.exe pack .\src\AutoscaleManager\AutoscaleManager\AutoscaleManagerLinux.nuspec -basePath .\out\Release\linux-x64 -OutputDirectory out\NugetPackages 
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

# msbuild path not provided, find msbuild for VS2019
if($MSBuildFullPath -eq "")
{
    if (${env:VisualStudioVersion} -eq "16.0" -and ${env:VSINSTALLDIR} -ne "")
    {
        $MSBuildFullPath = join-path ${env:VSINSTALLDIR} "MSBuild\Current\Bin\MSBuild.exe"
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

    $VS2019InstallPath = join-path $progFilesPath "Microsoft Visual Studio\2019"
    $versions = 'Community', 'Professional', 'Enterprise'

    foreach ($version in $versions)
    {
        $VS2019VersionPath = join-path $VS2019InstallPath $version
        $MSBuildFullPath = join-path $VS2019VersionPath "MSBuild\Current\Bin\MSBuild.exe"

        if (Test-Path $MSBuildFullPath)
        {
            break
        }
    }

    if (!(Test-Path $MSBuildFullPath))
    {
        Write-Host "Visual Studio 2019 installation not found in ProgramFiles, trying to find install path from registry."
        if(Test-Path -Path HKLM:\SOFTWARE\WOW6432Node)
        {
            $VS2019VersionPath = Get-ItemProperty (Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\SxS\VS7 -Name "16.0")."16.0"
        }
        else
        {
            $VS2019VersionPath = Get-ItemProperty (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VS7 -Name "16.0")."16.0"
        }

        $MSBuildFullPath = join-path $VS2019VersionPath "MSBuild\Current\Bin\MSBuild.exe"
    }
}

if (!(Test-Path $MSBuildFullPath))
{
    throw "Unable to find MSBuild installed on this machine. Please install Visual Studio 2019 or if its installed at non-default location, provide the full ppath to msbuild using -MSBuildFullPath parameter."
}


Set-location -Path $SrcRoot

$nugetArgs = @(
    "restore")

Write-Output "Changing the working directory to $SrcRoot"
& $NugetFullPath $nugetArgs
if ($lastexitcode -ne 0) {
    Set-location -Path $PSScriptRoot
    throw ("Failed " + $NugetFullPath + " " + $nugetArgs)
}

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