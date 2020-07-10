# temp

## Overview
This model makes it possible to ArUco marker detection and pose estimation on the Raspberry Pi using Simulink. Using this model, data on the number and position of AR markers can be directly imported into Simulink.

AR marker detection technology including ArUco is used for attitude control of robots and drones.

## Requires
* Simulink Support Package for Raspberry Pi Hardware
* OpenCV (on the Raspberry Pi)

## Compatibility
Created with
* MATLAB R2020a
* Raspberry Pi 3B+ / 4B (recommended)
* OpenCV 3.4.10
* Logitech C270 HD webcam

## How to use
### Preparation
OpenCV must be installed to run this model on the Raspberry Pi. In addition, a calibration data file is required for pose estimation. Follow the steps below to prepare them.
- ####  Installing OpenCV

  **1. Install dependencies**

  The following commands will update and upgrade any existing packages, followed by installing dependencies. Some libraries are installed when you build environment on the Raspberry Pi with Simulink support package.
  ```
  $ sudo apt-get update
  $ sudo apt-get upgrade
  $ sudo apt-get install build-essential cmake pkg-config
  $ sudo apt-get install libjpeg-dev libtiff5-dev libjasper-dev libpng12-dev
  $ sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
  $ sudo apt-get install libxvidcore-dev libx264-dev
  $ sudo apt-get install libgtk2.0-dev libgtk-3-dev
  $ sudo apt-get install libcanberra-gtk*
  $ sudo apt-get install libatlas-base-dev gfortran
  $ sudo apt-get install python2.7-dev python3-dev
  ```

  **2. Download the OpenCV source code**

  Download both the "opencv" and "opencv_contrib" repositories. In the following command, OpenCV version is `3.4.10`. Replace it with the version you will use.
  ```
  $ cd ~
  $ wget -O opencv.zip https://github.com/opencv/opencv/archive/3.4.10.zip
  $ unzip opencv.zip
  $ wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/3.4.10.zip
  $ unzip opencv_contrib.zip
  ```

  **3. Build and install the OpenCV**

  You are ready to build. Run the build with the following command. Replace the version you will use. The following command has `NEON` and `VFPV3` flags enabled and `TBB` and `OPENMP` flags for parallelization enabled.
  ```
  $ cd ~/opencv-3.4.10/
  $ mkdir build
  $ cd build
  $ cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib-3.4.10/modules \
      -D ENABLE_NEON=ON \
      -D ENABLE_VFPV3=ON \
      -D BUILD_TESTS=OFF \
      -D WITH_OPENMP=ON \
      -D BUILD_OPENMP=ON \
      -D WITH_TBB=ON \
      -D BUILD_TBB=ON \
      -D INSTALL_PYTHON_EXAMPLES=OFF \
      -D OPENCV_ENABLE_NONFREE=ON \
      -D CMAKE_SHARED_LINKER_FLAGS=-latomic \
      -D BUILD_EXAMPLES=OFF ..
  ```
  **Note:** *`cmake` will download the necessary libraries. Sometimes the download fails. In that case, the build will fail. It is recommended that you will check "CMakeDownloadLog.txt" in the build folder.*
  ```
  $ make -j4
  ```

  And then, use the following command to complete the installation.
  ```
  $ sudo make install
  $ sudo ldconfig
  ```

- #### Making calibration file

  **1. Print chessboard pattern**

  Print the checkerboard used for calibration. It can be downloaded from this link.
  \
  [Input chessboard pattern (opencv.org)](https://docs.opencv.org/2.4/_downloads/pattern.png)
  \
  It does not matter if the scale is changed a little during printing. However, each grid must be square. Stick the printed paper on the flat plate with tension.

  **2. Collect images**

  Collect images for the camera calibration. Move the chess board or camera to collect images at various distances and angles. About **20 images** are required for calibration.\
  There is a python script for taking images in the calibration folder. If you want to save an image with a resolution of "*640 x 480*" to the "*data*" folder, execute the following command.

  ```
  $ python save_snapshots.py --folder data --dwidth 640 --dheight 480
  ```
  Press the **spacebar** to save the camera image, press the **q** key to exit.

  *The original of this script from : [ tizianofiorenzani / how_do_drones_work ](https://github.com/tizianofiorenzani/how_do_drones_work)*

  **3. Make calibration file**

  Create a data file for calibration with the collected images. If you have a "*25mm*" square chess board image saved in the "*data*" folder and you want to save the calibration data in "*calibration.yml*", run the command as follows:
  ```
  $ python calibrate.py --square_size=25.0 --file_name='calibration.yml' './data/*.jpg'
  ```
  You will see that the calibration data file is created in current folder.

  *The original of this script from : [OpenCV: Open Source Computer Vision Library](https://github.com/opencv/opencv)*

### Getting started
 - #### Get AR marker
   Create an AR marker to be detected. You can get the marker image data from this link.
   \
  [ArUco markers generator!](https://chev.me/arucogen/)

 - #### Marker detection
   1. Open the "*ArUcoSampleModel.slx*" model and double-click the "*ArUco*" block to open the "*block parameter*".

   2. In "*General configuration*", match the setting of AR marker size and dictionary created with "Get Marker" section.

   3. Open the "*Camera*" tab and set the "*camera source*" and "*resolution*" to the same as when calibrating. Click OK to close the settings.

   4. Open the model's "*configuration parameters*" and change settings as needed. For example, Device Address, Username, etc.

   5. Click "*Monitor & tune*" on the model's "*Hardware*" tab to start model. You will see the marker detection in the launched View screen. And then, you can check the ID and corner data received on the display block.

   **Note :** *The status signal is 1 (true) while the marker is detected and 0 (false) otherwise.*

 - #### Pose estimation
   1. Carry out steps 1 to 3 in the "*Marker detection*" section.

   2. Under "*Detecting Data*" on the "*Output*" tab, select the check box for "*Enable vectors data*".

   3. If you move to the "*Camera*" tab, you can confirm that the "*Calibration source*" item of "*Source*" is increasing. Enter the **full path** of the calibration data file on the Raspberry Pi here. Click OK to close the settings.

   4. You will see that the block icon has changed to Pose estimation and "*rvecs*" and "*tvecs*" are added to the block output. Connect the "*Display block*" to the two outputs. Reconnect the line connecting to "*SDL Video Display*" to the "*image*" output port.

   5. Click "*Monitor & tune*" on the model's "*Hardware*" tab to start model. You will see the pose estimation in the launched View screen! And then, you can check the rvecs and tvecs data received on the display block.

   **Note :** *rvecs is the rotation data of the markers and tvecs is the position data.*

## Limitation
- #### Image viewer processing load
  "*SDL Video Display*" block consumes a lot of CPU resources of Raspberry Pi. It is recommended to use the block only for debugging. Remove when implementing the control.
- #### Image viewer resolution
  Due to the communication capacity constraint between Simulink and Raspberry Pi, the number of pixels of SDL Video Display will be limited to 0.5M pixels at maximum while maintaining the aspect ratio. However, this limitation does not affect the marker detection, it will be processed at the configured resolution.
- #### Detection speed
  The update rate of marker detection is limited to 5Hz(0.2sec) under the condition of detecting 5 markers with 640x480 resolution. The update rate depends on the resolution and the number of markers detecting.

## Troubleshoot
- #### "/usr/bin/ld: cannot find -lSDL" error is occurred during build
  It is displayed because there is no corresponding library in Raspberry Pi. Run the following command on the Raspberry Pi to add the library.
  ```
  $ sudo apt-get install libsdl-dev
  ```
