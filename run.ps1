#!/bin/bash

# Read Last Run CSV and process dates to download in this run
$run_data = Import-Csv -Path "run_dates.csv" | Select-Object -Last 1
$run_data | Format-Table
$csv_last_date = $run_data.last_day_processed

$date = [datetime]::ParseExact($csv_last_date, "yyyy-MM-dd", $null)



# Add or subtract days and export as string in YYYY-MM-DD format)
$usgs_start_date=(([datetime]::ParseExact($csv_last_date, "yyyy-MM-dd", $null)).AddDays(1)).ToString("yyyy-MM-dd")
$usgs_stop_date=(Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
$today=(Get-Date).ToString("yyyy-MM-dd")


$home_range_data = Import-Csv -Path "home_range.csv" | Select-Object -Last 1
$home_range_data | Format-Table

# Read home_range.csv to get location and radius to download USGS events
$home_lat=$home_range_data.latitude
$home_long=$home_range_data.longitude
$home_radius=$home_range_data.'radius-km'

# Download USGS events using the above settings



$usgs_api_url = "https://earthquake.usgs.gov/fdsnws/event/1/query?format=csv&starttime="+$usgs_start_date+"&endtime="+$usgs_stop_date+"&latitude="+$home_lat+"&longitude="+$home_long+"&maxradiuskm="+$home_radius
Invoke-WebRequest -Uri $usgs_api_url -OutFile usgs_downloaded_data.csv
#wget $usgs_api_url -O usgs_downloaded_data.csv

# Write a New Run line break to the log file for easier finding of run time blocks
"----------------------------- New Run -----------------------------" >> "my_quake_shakes.log"

# Cycle through the USGS downloaded events using headers with gawk. For each event pass it to the SAIpy based python script to process the event
# Each run of python script is one event and closed after wards keeping ram as minimal usage as possible and predictible

$usgs_event_data = Import-Csv -Path "usgs_downloaded_data.csv"
#$usgs_event_data | Format-Table

foreach ($event in $usgs_event_data) {
    Write-Host "run python"
	$start = (Get-Date).ToString("MMMM d HH:mm:ss yyyy")
	$start + " - Initiated Processing Event: " + $event.id >> "my_quake_shakes.log"
	
	uv run python my_quake_shakes.py -d $event.time -m $event.mag -p $event.place -n $event.net -id $event.id
	
	$end = (Get-Date).ToString("MMMM d HH:mm:ss yyyy")
	$end + " - Finshed Processing Event: " + $event.id >> "my_quake_shakes.log"

}
<#
gawk --csv '
    FNR == 1 {
        # Loop through columns and map column name -> index number
        for (i = 1; i <= NF; i++) {
            header[$i] = i
        }
        next
    }
    {
        # Get the Date/Time now to log as event processing start time in the logs
        now = strftime("%c", systime())
 
        # Write current Date/Time to the log
        print now " - Initiated Processing Event: " $header["id"] >> "my_quake_shakes.log"
      
        # Assemble the bash command in a gawk run-able syntax to run the python script in its virtual environment
        cmd = ".venv/bin/python my_quake_shakes.py " \
            "-d \"" $header["time"] "\" " \
            "-m \"" $header["mag"] "\" " \
            "-p \"" $header["place"] "\" " \
            "-n \"" $header["net"] "\" " \
            "-id \"" $header["id"] "\""

        # Run the command from with gawk loop
        system(cmd)

        # Get the Date/Time now to log as event processing end time in the logs
        now = strftime("%c", systime())

        # Write current Date/Time to the log
        print now " - Finshed Processing Event: " $header["id"] >> "my_quake_shakes.log"
        
        # Close the command that ran python
        close(cmd)
    }
' usgs_downloaded_data.csv
#>

# Update the last run csv file to allow next run to be only new data since last run
$date_line = $today+","+$usgs_stop_date
$date_line >> run_dates.csv