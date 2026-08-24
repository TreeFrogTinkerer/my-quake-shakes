# Configuring My Quake Shakes

Once installed you need to set some configurations for you to get usable data.  This is almost entirely done via CSV files in the repository along with a big of research on IRIS / Google.

# Home Range

The `home_range.csv` file is where set the center of your search for earthquake events and the radius around it to search.  My Quake Shakes ship with Mt St Helens as the location to test with.

> [!IMPORTANT]
> Only the last entry in home_range.csv is read. You can add as many as you like but it will only use the bottom most.

> [!NOTE]
> In theory to run multiple locales you can clone the repo multiple times and set `home_range.csv` in each one. Or edit the code to add multi-location option.

![Screenshot of home_range.csv](documentation_images/home_range.png)

Create a simple entry with the `latitude` & `longitude` of your location you wish to monitor.  In the `radius_km` field enter the radius in kilometers from the eenter point to search for earthquake events. The `notes` section isn't used by the script but is just a method of giving a human readable title to a location.

Save.



