param([string]$DatabasePath = '', [int]$Port = 8080)
$ErrorActionPreference = 'Stop'
$projectDir = Split-Path $PSScriptRoot -Parent
$backendDir = Join-Path $projectDir 'backend'
if (-not $env:JAVA_HOME -and (Test-Path 'C:\Program Files\Java\jdk-21')) {
    $env:JAVA_HOME = 'C:\Program Files\Java\jdk-21'
}
$bundledMaven = Join-Path $projectDir '.local\tools\apache-maven-3.9.11\bin\mvn.cmd'
$mavenCommand = if (Test-Path $bundledMaven) { $bundledMaven } else { 'mvn' }
if ($DatabasePath) {
    $env:EMPLOYEE_DATABASE = [System.IO.Path]::GetFullPath($DatabasePath)
}
Write-Host 'Starting Java employee portal with SQLite. Press Ctrl+C to stop.'
Push-Location $backendDir
try {
    $runArguments = @("-Dmaven.repo.local=$projectDir\.local\m2", '-Dapp.main-class=com.ingrowwth.homeloan.EmployeePortal', "-Dspring-boot.run.arguments=--spring.profiles.active=local --server.port=$Port", 'spring-boot:run')
    if ((Test-Path $bundledMaven) -and $env:JAVA_HOME) {
        $mavenHome = Split-Path (Split-Path $bundledMaven -Parent) -Parent
        $launcher = (Get-ChildItem (Join-Path $mavenHome 'boot\plexus-classworlds-*.jar') | Select-Object -First 1).FullName
        & "$env:JAVA_HOME\bin\java.exe" "-Dmaven.multiModuleProjectDirectory=$backendDir" "-Dmaven.home=$mavenHome" "-Dclassworlds.conf=$mavenHome\bin\m2.conf" -classpath $launcher org.codehaus.plexus.classworlds.launcher.Launcher @runArguments
    } else {
        & $mavenCommand @runArguments
    }
    if ($LASTEXITCODE -ne 0) { throw "Backend exited with code $LASTEXITCODE" }
} finally {
    Pop-Location
}
