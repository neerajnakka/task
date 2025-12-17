$url = "http://strapi-ecs-alb-1068211494.ap-south-1.elb.amazonaws.com"
Write-Host "🚀 Starting Traffic Spike to $url..."

$startTime = Get-Date

# Send 500 requests in pseudo-parallel chunks
1..50 | ForEach-Object {
    $batch = $_
    Write-Host "  - Sending Batch $batch (10 requests)..."
    1..10 | ForEach-Object {
        Start-Job -ScriptBlock {
            param($u)
            try { $r = Invoke-WebRequest -Uri $u -UseBasicParsing; return $r.StatusCode } catch { return $_.Exception.Message }
        } -ArgumentList $url | Out-Null
    }
    # Wait for this small batch to create load without killing local network
    Start-Sleep -Milliseconds 500
}

Write-Host "✅ All batches launched. Waiting for jobs to complete..."
Get-Job | Receive-Job -Wait -AutoRemoveJob | Group-Object | Select-Object Name, Count | Format-Table -AutoSize

$duration = (Get-Date) - $startTime
Write-Host "🏁 Traffic Spike Completed in $($duration.TotalSeconds) seconds."
