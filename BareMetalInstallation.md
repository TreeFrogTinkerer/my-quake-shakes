# Bare Metal Installation

Follow the following steps to install, configure, and run on bare metal.

## Step 1: Clone repository

`git clone -b dev https://github.com/TreeFrogTinkerer/my-quake-shakes.git`

## Step 2: Make `install.sh` Executable

```
cd my-quake-shakes
chmod +x install.sh
```

## Step 3: Run Installer
`./install.sh`

# Configuration

A few CSV files need to be edited with your information before getting personalized data.  

[Those steps are detailed in the Configuration.md](Configuration.md)

You can run it using the sample csv files as well if if you like though I'd highly recommend you change the date in `run_dates.csv` so you don't process a few years worth of quakes on the first go.

# Running My Quake Shakes

`./run-mqs.sh`

> [!TIP]
>  By default SAIPy appears to be setup to display the matlabplots automatically and will wait for you to close them before proceeding.  If you are running it via SSH disable X11 forarding and My Quake Shakes will run without the pause on the pop-ups.

The output will be in

`./my-quake-shakes.ics`