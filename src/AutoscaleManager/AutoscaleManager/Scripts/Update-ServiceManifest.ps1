#
# Updates the ServiceManifest file to replace NodeManager.exe with NodeManager for Linux deployments.
#
Param (
    [string]
    $packageRoot
)
$ErrorActionPreference = 'Stop'
$manifestFiles = (Get-ChildItem -Path $packageRoot -Filter ServiceManifest.xml -Recurse)

foreach ($fileInfo in $manifestFiles)
{
    $file = $fileInfo.FullName
    Write-Host "Working on file" $file
    $content = (Get-Content -Path $file -Raw -Encoding UTF8)
    $newContent = $content.Replace(".exe", "")

    if ($content -ne $newContent)
    {
        Set-Content -Path $file -Value $newContent  -Encoding UTF8
    }
}