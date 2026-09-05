#!/bin/bash

# Read Last Run CSV and process dates to download in this run
csv_last_date=$(awk -F, 'END {print $2}' run_dates.csv)
usgs_start_date=$(date -d "$csv_last_date + 1 days" +%F)
usgs_stop_date=$(date -d "yesterday" +%F)
today=$(date +%F)

# Read home_range.csv to get location and radius to download USGS events
home_lat=$(awk -F',' 'NR > 1 { print $1}' home_range.csv)
home_long=$(awk -F',' 'NR > 1 { print $2}' home_range.csv)
home_radius=$(awk -F',' 'NR > 1 { print $3}' home_range.csv)

# Download USGS events using the above settings
usgs_api_url="https://earthquake.usgs.gov/fdsnws/event/1/query?format=csv&starttime=${usgs_start_date}&endtime=${usgs_stop_date}&latitude=${home_lat}&longitude=${home_long}&maxradiuskm=${home_radius}"
wget $usgs_api_url -O usgs_downloaded_data.csv

# Write a New Run line break to the log file for easier finding of run time blocks
echo "----------------------------- New Run -----------------------------" >> "my_quake_shakes.log"

# Cycle through the USGS downloaded events using headers with gawk. For each event pass it to the SAIpy based python script to process the event
# Each run of python script is one event and closed after wards keeping ram as minimal usage as possible and predictible
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

# Update the last run csv file to allow next run to be only new data since last run
echo $today","$usgs_stop_date >> run_dates.csv

# Run custom action script at the end of this script
./custom-actions.sh

# Puts computer to sleep once the script has run - systemd hosts
# sleep 30s
# systemctl suspend