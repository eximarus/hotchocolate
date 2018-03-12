param([switch]$DisableBuild, [switch]$RunTests, [switch]$EnableCoverage, [switch]$EnableSonar, [switch]$Publish)

if (!!$env:APPVEYOR_REPO_TAG_NAME) {
    $version = $env:APPVEYOR_REPO_TAG_NAME
}
elseif (!!$env:APPVEYOR_BUILD_VERSION) {
    $version = $env:APPVEYOR_BUILD_VERSION
}

if ($version -ne $null) {
    $env:Version = $version
}

if ($EnableSonar) {

}

if ($DisableBuild -eq $false) {
    dotnet restore src
    msbuild src
}

if ($RunTests -or $EnableCoverage) {
    # Test
    $serachDirs = [System.IO.Path]::Combine($PSScriptRoot, "src", "*", "bin", "Debug", "netcoreapp2.0")
    $runTestsCmd = [System.Guid]::NewGuid().ToString("N") + ".cmd"
    $runTestsCmd = Join-Path -Path $env:TEMP -ChildPath $runTestsCmd
    $testAssemblies = ""
    
    Get-ChildItem ./src/*.Tests | % { $testAssemblies += "dotnet test `"" + $_.FullName + "`" --no-build`n" }
    
    if (!!$testAssemblies) {
        # Has test assemblies {    
        $userDirectory = $env:USERPROFILE
        if ($IsMacOS) {
            $userDirectory = $env:HOME
        }
        
        [System.IO.File]::WriteAllText($runTestsCmd, $testAssemblies)
        Write-Host $runTestsCmd

        if ($EnableCoverage) {
            # Test & Code Coverage
            $nugetPackages = [System.IO.Path]::Combine($userDirectory, ".nuget", "packages")
            
            $openCover = [System.IO.Path]::Combine($nugetPackages, "OpenCover", "*", "tools", "OpenCover.Console.exe")
            $openCover = Resolve-Path $openCover

            $coveralls = [System.IO.Path]::Combine($nugetPackages, "coveralls.io", "*", "tools", "coveralls.net.exe")
            $coveralls = Resolve-Path $coveralls

            & $openCover -register:user -target:"$runTestsCmd" -searchdirs:"$serachDirs" -oldstyle -output:coverage.xml -skipautoprops -returntargetcode -filter:"+[ChilliCream*]*"
            & $coveralls --opencover coverage.xml
        }
        else {
            # Test
            & $runTestsCmd
        }
    }
}

if ($EnableSonar) {

    
}

if ($Publish) {
     
}