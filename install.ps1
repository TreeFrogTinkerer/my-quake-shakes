#!/bin/bash
# Install uv so we can install a python 3.11 virtual environment for SAIPy 

$uv_check = Get-Command uv -ErrorAction SilentlyContinue

if (!$uv_check){
	powershell.exe -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
	Write-Host "uv has been installed. Close powershell, reopen, and rerun installer to continue"
}
else{

# Clone the SAIPy project
git clone https://github.com/srivastavaresearchgroup/SAIPy.git

# Move My Quake Shakes project files into th SAIPy folder 
# Copy and name correctly the template based csvs into the SAIPy folder
# Could likely make this not needed but this is how it was built and isn't much of an issue at the moment so not putting time into changing it
Move-Item -Path "run.ps1" -Destination ".\SAIPy"
Copy-Item -Path "stations-template.csv" -Destination ".\SAIPy\stations.csv"
Copy-Item -Path "home_range-template.csv" -Destination ".\SAIPy\home_range.csv"
Move-Item -Path "my_quake_shakes.py" -Destination ".\SAIPy"
Move-Item -Path "run_dates.csv" -Destination ".\SAIPy"

# Change directories into the SAIPy location
cd SAIPy

# Install a python 3.11/pip enabled virtual environment
uv venv --python 3.11 --seed

# Activate the virtual environment
.venv\Scripts\activate

# Update the official setup.py file with the exact packages we need to run on python 3.11 / newer version of pip
sed -i "s/tensorflow>=2.8.0/tensorflow==2.15.0/g" setup.py
sed -i 's/+cu113//g' setup.py

# Install SAIPy
python -m pip install .

# Install / Confirm My Quake Shake modules needed for python
python -m pip install requests lxml icalendar

# Exit the virtual environmnet now that is configured
deactivate
}