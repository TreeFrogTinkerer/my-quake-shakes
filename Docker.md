# Docker, Docker, Docker

To use the docker setup you must be slightly comfortable using docker from the command line.  You will need to edit a few files, build the image, and start the container.  There is no reason someone couldn't build the image and upload it to dockerhub either. It just hasn't been done at this time.

> [!NOTE]
> The docker image is set to update the earthquake data / ics file every 2 days.  So every 48 hours from the time you start the docker container and it finishes the script it will wait 48 hours and run again.

# Optional: Build the Docker Image

By default a dockerhub image will be used.  However, if you would like to edit any of the files in the project to suit your specifically you can do so. Once your edits are done you can build

## Step 0A: Clone Repository

`git clone -b dev https://github.com/TreeFrogTinkerer/my-quake-shakes.git`

## Step 0B: Make your Edits

Edit the project to your liking.

## Step 0C: Build the Image

```
cd my-quake-shakes
docker build -t my-quake-shakes-custom .
```

This should process the `Dockerfile` and build the `my-quake-shakes-custom` docker image. You then need to update the `compose.yml` file to point to your custom image.

# Configure Docker Compose File and My Quake Shake Settings

## Step 1: Create & Edit compose.yml File

Using `nano compose.yml` copy and past the following into it

```
services:
  my-quake-shakes:
    image: treefrogtinkerer/my-quake-shakes:latest
    container_name: my-quake-shakes
    volumes:  
      - ./my-quake-shake-volumes/config:/my-quake-shakes/SAIPy/config
      - ./my-quake-shake-volumes/ics-output:/ha-config/www
    deploy:
      resources:
        limits:
          cpus: '2.0'  # Limits the container to 2 cores  
    restart: unless-stopped
```

Alternatively, you can mount to a docker volume rather than the underlying OS

```
   volumes:
        - my-quake-shakes-config:/my-quake-shakes/SAIPy/config
...
volumes:
   my-quake-shakes-config:
```  

You can edit the volume path to another location if you like but the following command will have to be edited.

> [!NOTE]
> SAIPy will use EVERY core you have available. To mitigate some of this impact the default is to allow 2 cpu cores to be used by the container.

> [!TIP]
> To increase the number of cores My Quake Shake/SAIPy are allowed to use change `cpus: '2.0'` line to the max number of cores you'd like to allow it to use.  I set this to 2 cores less than what my processor has.

## Step 2: Copy config files to local volume

Docker will not copy the files from the container to the local disk. So we will just copy them from this repository directly.

```
mkdir -p ./my-quake-shake-volumes/config/
`cp ./config/* ./my-quake-shake-volumes/config/
```

> [!NOTE]
> If you use a Docker Volume instead of the host OS filesytem you will shouldn't need to manually copy the files in `./config` to the volume. However, if things arent working as expected check the volume contents and confirm the files are there and that the `custom-actions.sh` is set to exectable.

## Step 3: Edit Configuration Files

Go through the same steps on the [Configuration Page](Configuration.md) except edit the files in the `./my-quake-shakes/config` folder instead of the standard `./config/` folder

> [!NOTE]
> If you use a Docker Volume instead of the host OS filesytem you will need to edit the files in the volume directly

You can run it using the sample csv files as well if if you like though I'd highly recommend you change the date in `run_dates.csv` so you don't process a few years worth of quakes on the first go.

### Optional: Edit `custom-actions.sh`

Add any actions you want run afterwards. The example is an FTP upload command.

# Start the My Quake Shakes Container

## Step 4: Start the Docker Container

`docker compose up -d`

# Enjoy

Wait for it to run and finish which may take a while depending on your hardware.

## View ics File

The output ics file is written to the host os `./my-quake-shake-volumes/ics-output`.

Review the ics file to see what you've discovered about your choosen location!


