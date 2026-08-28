Some caveats about this tool are:
* It uses local AI models so is very resourced intensive on your CPU / RAM
 * It can be run on NVIDIA GPUs though this repo isn't setup to do so because frankly I don't have one and was able to get it to run acceptably on a CPU only machine
 * You will need at least 8 GB of RAM FREE for this tool the way My Quake Shake has broken it up
* The models are stored in Keras2 which isn't compatible with the current version of all the tools that are auto installed
  * I found it easiest to use Python 3.11 and just downgrade TensorFlow to 2.15.0
  * I found using uv to install the Python 3.11 environment simplest