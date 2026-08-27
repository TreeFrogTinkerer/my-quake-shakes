############## - Imports for argument passing/parsing and assigning the variables from the arguments passed
import sys
import argparse

parser = argparse.ArgumentParser(description="SAIpy based script that takes the station information and run information via arguments.")

parser.add_argument("-d", "--date", help="Event DateTime", required=True)
parser.add_argument("-m", "--magnitude", help="Event Magnitude", required=True)
parser.add_argument("-p", "--place", help="Event Place", required=True)
parser.add_argument("-n", "--network", help="Event Network", required=True)
parser.add_argument("-id", help="Event ID", required=True)

args = parser.parse_args()

usgs_stop_date = args.date
description = args.place
time_value = args.date
mag_value = args.magnitude
event_id_raw = args.id
network = args.network
event_id = event_id_raw.removeprefix(network)
event_url=f"https://pnsn.org/event/{event_id}"

############## - Imports and setup for the USGS & station information portion of the script
#import requests
import csv
from datetime import datetime, timezone, timedelta, date
import time

############### - Imports and setup for the SAIpy portion of the script
import os
import torch
import obspy
from obspy.clients.fdsn import Client
from obspy import UTCDateTime
from saipy.data.realdata import *
from saipy.utils.packagetools import *

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
dirmodel = '../saipy/saved_models/'

################ - Import for ICS creation
from icalendar import Calendar, Event

ics_path = "/var/www/my-quake-shakes.ics"

################ - Check / Create the USGS ics Calendar file
try:
    with open(ics_path, "rb") as fcal:
        calendar = Calendar.from_ical(fcal.read())
except FileNotFoundError: 
    # If file doesn't exist, create a new calendar template
    calendar = Calendar()
    calendar.add('prodid', '-//My Quake Shakes//EN')
    calendar.add('version', '2.0')

################ -

# IRIS/Earthscope Retry Settings
max_attempts = 3
delay = 2  # seconds

# Flag to set to write the event to the ics file
write_event = False

# Change datetime to math-able format
dt = datetime.fromisoformat(time_value.replace('Z', '+00:00'))

# Calculate start and end date/times for local sensor processing
start_dt = dt - timedelta(hours=0, minutes=7)
end_dt = dt + timedelta(hours=0, minutes=8)

# Calculate start and end times for sesnsed events to show them after the USGS event
# This helps maintain order in the ics display
sensor_start_dt = dt + timedelta(milliseconds=1)
sensor_stop_dt = dt - timedelta(minutes=5)

# Format to SAIpy / Obspy Date/Time Format
start_output_str = start_dt.isoformat(timespec='milliseconds').replace('+00:00', 'Z')
end_output_str = end_dt.isoformat(timespec='milliseconds').replace('+00:00', 'Z')

######### Write Event Data to the ics summary variable. 
# This variable will be appended with sensor information if detected
# And only written to the ics file if a sesnor detects anything
event_summary=f"🎯: {mag_value} "

# Start / Stop time for the event in Obspy format -- same for all stations
start_time_send = UTCDateTime(start_output_str)
end_time_send = UTCDateTime(end_output_str)

# Time format for titles
starttime_str = start_time_send.strftime("%Y-%m-%d %H:%M:%S")
day = start_time_send.strftime("%Y%m%d")
stime = start_time_send.strftime("%H%M%S")

# Monitor Process variables -- same for all stations
lw = 30
dw = 5

# Output path for SAIpy based graphs and CSV -- the output is disabled but the it can be enabled in the command below so this variable is left in
output_path = '../results/results_IRIS_v2'        

# For each location station to process from CSV
with open('stations.csv', mode='r', newline='', encoding='utf-8') as file:
    stations = list(csv.DictReader(file))

for station in stations:

        # Extrqact station information into easier to use variables from the stations.csv
        wsp_word=station['wsp']
        network_word=station['network']
        station_word=station['station']
        location_word=station['location']
        channel_word=station['channel']
        station_human_readable_name=station['station_hr_name']

        # Download data for the event from the stations from the wsp
        print(f"\n** Downloading data: station {station['station']}, date {starttime_str}... **")

        # This is the retry loop for the wsp download. Sometimes the download will fail for some random reason and this loop prevents the whole script from dying.
        for attempt in range(max_attempts):
            try:
                print(f"Attempt {attempt + 1} of {max_attempts}...")
                stream = waveform_download(wsp=wsp_word, net=network_word, sta=station_word, loc=location_word, chan=channel_word, starttime=start_time_send, endtime=end_time_send)
                break  # Success! Exit the loop.
            except BaseException as e:
                print(f"Failed due to: {e}")
                if attempt < max_attempts - 1:
                    time.sleep(delay)
        else:
            # Write to log file if all 3 attempts fail
            with open("my_quake_shakes.log", "a") as file:
                file.write("FAILED: All attempts at downloading sensor data  for event FAILED. Event UNPROCCESSED.\n")
            print("All attempts failed.")

        # Filter bp 1-45 Hz and resampling (100 Hz, if necessary)
        print("** Preprocessing data... **")
        prepro_stream, prepro_wave_array = preprocessing(stream)
        print(prepro_stream)

        # The 'main' SAIpy call using all the above information and variables. The enable SAIpy output set save_result to True
        outputs = monitor(prepro_stream, prepro_wave_array, device,
                                            station['station'], day, stime,
                                            len_win=lw, detection_windows=dw,
                                            model_path=dirmodel,
                                            save_result=False,
                                            outpath=output_path)
        
        # Extract magnitudes from the SAIpy output
        mag_out = outputs.get("magnitudes")

        # If no magnitudes are found mark the event as undetected
        if not mag_out:
            print("Undetected")
            mag_print = "Undetectable"
        # If magnitudes are found combine them into a single string sepearted by slashes
        # SAIpy may find multiple spikes or events during the 15 minutes vs the official record
        # This combining shows all the data without having to 'decide' what is what ie reduce falst negatives
        else:
            string_mags = [str(num) for num in mag_out]
            #mag_strings = mag_out.astype(str)
            mag_print = "/".join(string_mags)

        # If an event has been detected append the event information to the ics summary field and set the flag to write the ics at the end of the loop
        if mag_print != "Undetectable":
            event_summary+=f"🫨: {mag_print} [{network_word} {station_word}] "
            write_event = True


# If an event was detected with SAIpy at the processed sensors then write the event to the calendar variable. Otherwise do not.
if write_event:
    new_event = Event()
    new_event.add('summary', event_summary)
    new_event.add('description', description)
    new_event.add('location', event_url)
    ics_start=datetime.fromisoformat(time_value)
    new_event.add('dtstart', ics_start)

    # Append the event component to the calendar object
    calendar.add_component(new_event)

########### - Append/Writes all found events to the ics file

with open(ics_path, "wb") as fcal:
    fcal.write(calendar.to_ical())

