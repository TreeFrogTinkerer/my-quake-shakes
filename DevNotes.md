# Dev Notes Notes

I'm calling these dev notes as for anyone who wants to work on this repo but it could just as well be labeled "More Technical Notes" on what decisions were made or known quirks and why.

> [!IMPORTANT]
> This is NOT reliable enough for any critical application.  Events can be missed, AI model can silently fail, and the author of My Quake Shakes was not involved in the SAIPy project and therefore cannot guarantee the results of this application.  Use at your own risk.  It is largely for curiosity rather than deep scientific research or actual warning system of any sort.

# SAIPy Notes - Really it is all based on this

This project is very cool and I do not begin to act like I understand what it is doing on the back end.  However, there are some quirks of running it I did learn that are applicable here and/or directly influenced the development of My Quake Shakes.

1) As it uses local AI models it is **VERY** resourced intensive on your CPU / RAM
  * It uses **EVERY CORE** @ 100% on the machine I built this on.  I'm not sure what it does to higher spec'ed machines but my guess is it will use ALL the CPU to speed it up if not using GPU acceleration with pytorch
2) It is slightly older and the models are in Keras2 format not the current Keras3 format
  * I don't really know the difference only that current installs of pythong and pytorch, etc do not like running easily
3) RAM usage is directly proportional to two aspects:
    * Raw Data Sample size in minutes
      * It takes about ~3GB per 15 minutes of samples 
      * So if you wangt to run 30 minute samples you will need ~6GB of RAM available
    * How many samples are run per python script
      * python does NOT realease ram until the process closes
      * Effectively this meant that if I ran 3 samples in a single python script it would end up using ~9GB of RAM to process all samples
      * This is fine for a small number but as earthquake events are not predictiable to number of days it was a challenge to make this loop and not eat up more RAM than a machine has

## RAM Usage Management

Two design descisions were made to manage the amount of RAM needed and more importantly make that number predictible.

### 15 Minute Events

The first was to use USGS as data seed and only process 15 minute blocks of time around the official USGS events.  This allows the amount of ram per 'sample' to be around 3GB. The trade off is that it will not process any events outside of those time periods so if a sensor detects a quake/shake that isn't time related to an official earthquake it will not show up the output.

This is ok as the intention of this project is not to process local data exclusively to 'detect earthwuakes' but rather to understand how much it shook at a location closer to my location rather than the epicenter.

However, this was incomplete in resolving the issue as if a single day had 10 events it still required 30GB of free RAM. And if there were 15 events in a day it would need 45GB of RAM.  It is not predictable in the amount of RAM needed **ESPECIALLY** on units longer than a day. Like a week.

### Bash bashed USGS Loop

I first tried a loop within python but as stated above the RAM would just increment with each new sample.  I tried making it launch extrenal process but it turns out SAIPy already yses that trick so it would let it complete in my seperate process. And the other option was complicated I didn't try hard to get to work.  LAstly, I tried to force garbage collection in python to resolve the issue. None were fully successful. 

Enter bash.

Buy moving the USGS download, parsing, loop, and last start date into the bash layer **EACH SAMPLE** runs in it's own python process that now closes between each sample. Meaning the RAM usage was now predictable and linerly related to the sample length.  So as long as you stick to a 15 minute sample it seems the RAM usage never gets above about 4GB rolling and on going.

I used gawk to parse the csv and therefore launch the python script as well.

## Keras Model Version / Install Options

Now I don't even start to understand Keras and it's versions. What I know is the SAIPy models are in Keras2 and the current versions installed via normal apt etc in Debian don't play well with the install script in SAIPy but also Keras2 version.  The newer librarys want Keras3.  I was unable to located a straight forward way to conver them I was confident in but discovered I could get all relevant package versions as long as I stuck with python 3.11. So that is what I did.  

My Quake Shakes uses uv to install a virtual python 3.11 environment where it installs all the correcgt pacakges.  The installer also edits 2 lines in the setup.sh script SAIPy comes with for sytax and version reasons.  These are the sed -i lines.  Primariy they make the TensorFlow version 2.15.0 exactly as it still supports Keras2 and removes the incorrect nomeclature for current pip around the PyTorch package version.

As part of that it removes the nomeneclature for NVIDIA card support and instead runs solely in CPU and RAM.  It looks like some of the NVIDIA packages may still get installed but I do not have a NVIDIA GPU to test on so I can't say for certain. In theorry it should be able to run on NVIDIA GPUs.

## gawk 5.3

Debian Trixie in it's normal apt repo only has gawk 5.2 but built in csv support does not come until version 5.3. Luckily, it is available in the testing repo. So the install script adds this repo, installs gawk 5.3 and removes the testing repo from the OS before it exits. This helsp to not leave the system having 200 something off upgrades but all of the testing repo variety

## Logging

Logging exists but is not as robust as I'd like it to be.  All logs go into a same file that I expect will grow quite large through time.  My attempts to make dynamic log name and pass it to the python routine were short lived and a failure.  They are worth doing but also not worth holding up the release for this at the moment.

Currently the log notes the start of a sample process, the end time of a sample process, and if the sample failed to download from IRIS/EARTHSCOPE.  HOWEVER, if there is an error in the python file running it is silent and doesn't show it at this time. In the log. It will show it in the console output.

## Run Dates

Similiarly to the above the script doesn't check or confirm if the samples processed correctly before marking the date run in the csv file.  So if all samples fail IRIS/EARTHSCOPE download it will still be marked as complete and can lead to false negatives.
