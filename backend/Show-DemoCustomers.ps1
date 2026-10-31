$ErrorActionPreference = 'Stop'
$repo = Join-Path $PSScriptRoot '../.local/m2'
$driver = Get-ChildItem (Join-Path $repo 'org/xerial/sqlite-jdbc') -Filter '*.jar' -Recurse | Select-Object -First 1
$logging = Get-ChildItem (Join-Path $repo 'org/slf4j/slf4j-api') -Filter '*.jar' -Recurse | Sort-Object FullName -Descending | Select-Object -First 1
if (-not $driver -or -not $logging) { throw 'Start the backend once to download the SQLite driver.' }
$java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin/java.exe' } else { 'java' }
$classpath = $driver.FullName + ';' + $logging.FullName
foreach ($module in @('logback-classic','logback-core')) {
  $loggerJar = Get-ChildItem (Join-Path $repo "ch/qos/logback/$module") -Filter '*.jar' -Recurse | Sort-Object FullName -Descending | Select-Object -First 1
  if ($loggerJar) { $classpath += ';' + $loggerJar.FullName }
}
& $java --class-path $classpath (Join-Path $PSScriptRoot 'tools/InspectEmployeeDatabase.java') (Join-Path $PSScriptRoot '.data/employee-demo.sqlite')
if ($LASTEXITCODE -ne 0) { throw 'SQLite viewer failed. Check the error above.' }

