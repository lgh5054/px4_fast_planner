#!/bin/bash

CATKIN_WS=${HOME}/catkin_ws
CATKIN_SRC=${HOME}/catkin_ws/src

if [ ! -d "$CATKIN_WS"]; then
	echo "Creating $CATKIN_WS ... "
	mkdir -p $CATKIN_SRC
fi

if [ ! -d "$CATKIN_SRC"]; then
	echo "Creating $CATKIN_SRC ..."
fi

# Configure catkin_Ws
cd $CATKIN_WS
catkin init
catkin config --merge-devel
catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release

####################################### Setup PX4 v1.10.1 #######################################

# 
# Setup script for PX4 firmware and sitl development eco-system 
# Author: Tarek Taha, Mohamed Abdelkader
# References: http://dev.px4.io/master/en/setup/dev_env_linux_ubuntu.html#sim_nuttx
#


# Installing initial dependencies
sudo apt --quiet -y install \
    ca-certificates \
    gnupg \
    lsb-core \
    wget \
    ;
# script directory
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# check requirements.txt exists (script not run in source tree)
REQUIREMENTS_FILE="px4_requirements.txt"
if [[ ! -f "${DIR}/${REQUIREMENTS_FILE}" ]]; then
	echo "FAILED: ${REQUIREMENTS_FILE} needed in same directory as setup_px4.sh (${DIR})."
	return 1
fi

echo "Installing PX4 general dependencies"

sudo apt-get update -y --quiet
sudo DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
	astyle \
	build-essential \
	ccache \
	clang \
	clang-tidy \
	cmake \
	cppcheck \
	doxygen \
	file \
	g++ \
	gcc \
	gdb \
	git \
	lcov \
	make \
	ninja-build \
	python3 \
	python3-dev \
	python3-pip \
	python3-setuptools \
	python3-wheel \
	rsync \
	shellcheck \
	unzip \
	xsltproc \
	zip \
	;

# Python3 dependencies
echo
echo "Installing PX4 Python3 dependencies"
pip3 install --user -r ${DIR}/px4_requirements.txt

echo "arrow" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
		gstreamer1.0-plugins-bad \
		gstreamer1.0-plugins-base \
		gstreamer1.0-plugins-good \
		gstreamer1.0-plugins-ugly \
		libeigen3-dev \
		libgazebo9-dev \
		libgstreamer-plugins-base1.0-dev \
		libimage-exiftool-perl \
		libopencv-dev \
		libxml2-utils \
		pkg-config \
		protobuf-compiler \
		;


#Setting up PX4 Firmware
if [ ! -d "${HOME}/Firmware" ]; then
    cd ${HOME}
    git clone https://github.com/PX4/Firmware
else
    echo "Firmware already exists. Just pulling latest upstream...."
    cd ${HOME}/Firmware
    git pull
fi
cd ${HOME}/Firmware
make clean && make distclean
git checkout v1.10.1 && git submodule init && git submodule update --recursive
cd ${HOME}/Firmware/Tools/sitl_gazebo/external/OpticalFlow
git submodule init && git submodule update --recursive
cd ${HOME}/Firmware/Tools/sitl_gazebo/external/OpticalFlow/external/klt_feature_tracker
git submodule init && git submodule update --recursive
# NOTE: in PX4 v1.10.1, there is a bug in Firmware/Tools/sitl_gazebo/include/gazebo_opticalflow_plugin.h:43:18
# #define HAS_GYRO TRUE needs to be replaced by #define HAS_GYRO true
sed -i 's/#define HAS_GYRO.*/#define HAS_GYRO true/' ${HOME}/Firmware/Tools/sitl_gazebo/include/gazebo_opticalflow_plugin.h
cd ${HOME}/Firmware
DONT_RUN=1 make px4_sitl gazebo

#Copying this to  .bashrc file
grep -xF 'source ~/Firmware/Tools/setup_gazebo.bash ~/Firmware ~/Firmware/build/px4_sitl_default' ${HOME}/.bashrc || echo "source ~/Firmware/Tools/setup_gazebo.bash ~/Firmware ~/Firmware/build/px4_sitl_default" >> ${HOME}/.bashrc
grep -xF 'export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:~/Firmware' ${HOME}/.bashrc || echo "export ROS_PACKAGE_PATH=\$ROS_PACKAGE_PATH:~/Firmware" >> ${HOME}/.bashrc
grep -xF 'export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:~/Firmware/Tools/sitl_gazebo' ${HOME}/.bashrc || echo "export ROS_PACKAGE_PATH=\$ROS_PACKAGE_PATH:~/Firmware/Tools/sitl_gazebo" >> ${HOME}/.bashrc
grep -xF 'export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:/usr/lib/x86_64-linux-gnu/gazebo-9/plugins' ${HOME}/.bashrc || echo "export GAZEBO_PLUGIN_PATH=\$GAZEBO_PLUGIN_PATH:/usr/lib/x86_64-linux-gnu/gazebo-9/plugins" >> ${HOME}/.bashrc

source ${HOME}/.bashrc


####################################### mavros_controllers setup #######################################
#Adding mavros_controllers-1
if [ ! -d "$CATKIN_SRC/mavros_controllers-1" ]; then
    echo "Cloning the mavros_controllers-1 repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/mzahana/mavros_controllers-1.git
    cd ../
else
    echo "mavros_controllers-1 already exists. Just pulling ..."
    cd $CATKIN_SRC/mavros_controllers-1
    git pull
    cd ../ 
fi
# checking out branch compatible with fast planner
cd $CATKIN_SRC/mavros_controllers-1
git checkout fast_planner_interface

#Adding catkin_simple
if [ ! -d "$CATKIN_SRC/catkin_simple" ]; then
    echo "Cloning the catkin_simple repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/catkin/catkin_simple
    cd ../
else
    echo "catkin_simple already exists. Just pulling ..."
    cd $CATKIN_SRC/catkin_simple
    git pull
    cd ../ 
fi

#Adding eigen_catkin
if [ ! -d "$CATKIN_SRC/eigen_catkin" ]; then
    echo "Cloning the eigen_catkin repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/ethz-asl/eigen_catkin
    cd ../
else
    echo "eigen_catkin already exists. Just pulling ..."
    cd $CATKIN_SRC/eigen_catkin
    git pull
    cd ../ 
fi

#Adding eigen_catkin
if [ ! -d "$CATKIN_SRC/mav_comm" ]; then
    echo "Cloning the mav_comm repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/ethz-asl/mav_comm
    cd ../
else
    echo "mav_comm already exists. Just pulling ..."
    cd $CATKIN_SRC/mav_comm
    git pull
    cd ../ 
fi


####################################### Fast-planner setup #######################################
# Required for Fast-Planner
sudo apt install ros-melodic-nlopt libarmadillo-dev -y

#Adding Fast-Planner
if [ ! -d "$CATKIN_SRC/Fast-Planner" ]; then
    echo "Cloning the Fast-Planner repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/mzahana/Fast-Planner.git
    cd ../
else
    echo "Fast-Planner already exists. Just pulling ..."
    cd $CATKIN_SRC/Fast-Planner
    git pull
    cd ../ 
fi

# Checkout ROS Mellodic branch 
cd $CATKIN_SRC/Fast-Planner
git checkout changes_for_ros_melodic

####################################### Building catkin_ws #######################################
cd $CATKIN_WS
catkin build multi_map_server
catkin build
source $CATKIN_WS/devel/setup.bash

grep -xF 'source $HOME/catkin_ws/devel/setup.bash' ${HOME}/.bashrc || echo "source $HOME/catkin_ws/devel/setup.bash" >> $HOME/.bashrc