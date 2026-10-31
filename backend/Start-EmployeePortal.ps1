$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not $env:JAVA_HOME -and (Test-Path 'C:\Program Files\Java\jdk-21')) {
  $env:JAVA_HOME = 'C:\Program Files\Java\jdk-21'
}
$maven = Join-Path $PSScriptRoot '../.local/tools/apache-maven-3.9.11/bin/mvn.cmd'
if (-not (Test-Path $maven)) { $maven = 'mvn' }
& $maven '-Dmaven.repo.local=../.local/m2' '-Dapp.main-class=com.ingrowwth.homeloan.EmployeePortal' spring-boot:run
if ($LASTEXITCODE -ne 0) { throw 'Employee server stopped with an error. Read the startup output above.' }
