#!/bin/bash
# Install uv so we can install a python 3.11 virtual environment for SAIPy 
#sudo apt install uv

# Copy the testing source for debian Trixie so we can...
sudo cp testing.list /etc/apt/sources.list.d

# ... Install gawk 5.3 -- with built in csv support
sudo apt update
sudo apt install -t testing gawk

# Clone the SAIPy project
git clone https://github.com/srivastavaresearchgroup/SAIPy.git

# Move My Quake Shakes project files into th SAIPy folder 
# Copy and name correctly the template based csvs into the SAIPy folder
# Could likely make this not needed but this is how it was built and isn't much of an issue at the moment so not putting time into changing it
mv run.sh ./SAIPy
cp stations-template.csv ./SAIPy/stations.csv
cp home_range-template.csv ./SAIPy/home_range.csv
mv my_quake_shakes.py ./SAIPy
mv run_dates.csv ./SAIPy
mv hooks.json ./SAIPy

# Make the run.sh executible
chmod +x ./SAIPy/run.sh

# Change directories into the SAIPy location
cd SAIPy

# Install a python 3.11/pip enabled virtual environment
uv venv --python 3.11 --seed

# Activate the virtual environment
source .venv/bin/activate

# Update the official setup.py file with the exact packages we need to run on python 3.11 / newer version of pip
sed -i "s/tensorflow>=2.8.0/tensorflow==2.15.0/g" setup.py
sed -i 's/+cu113//g' setup.py

# Install SAIPy
python3 -m pip install .

# Install / Confirm My Quake Shake modules needed for python
python -m pip install requests lxml icalendar

# Exit the virtual environmnet now that is configured
deactivate

# Remove testing branch after gawk installed
sudo rm /etc/apt/sources.list.d/testing.list
sudo apt update