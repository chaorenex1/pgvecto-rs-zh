$ErrorActionPreference = "Stop"

$serviceName = if ($env:SERVICE_NAME) { $env:SERVICE_NAME } else { "postgres" }
$postgresUser = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "postgres" }
$postgresDb = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { "postgres" }

function Invoke-SqlScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    Write-Host "== running $ScriptPath =="
    docker compose exec $serviceName `
        psql -v ON_ERROR_STOP=1 -U $postgresUser -d $postgresDb -f $ScriptPath
}

Invoke-SqlScript "/runtime/sql/inspection.sql"
Invoke-SqlScript "/runtime/sql/extensions/00-run-all.sql"
Invoke-SqlScript "/runtime/sql/extensions/99-cleanup-check.sql"

Write-Host "All inspection and extension smoke tests passed."
