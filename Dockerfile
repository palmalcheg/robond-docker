# Kudos to DOROWU for his amazing VNC 16.04 KDE image
FROM dorowu/ubuntu-desktop-lxde-vnc
LABEL maintainer "bpinaya@wpi.edu"

RUN sh -c 'echo "deb http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security universe" > /etc/apt/sources.list.d/ubuntu-security.list'
RUN apt-get update && apt-get install -y  dirmngr

RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

# Adding keys for ROS
RUN apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
#RUN curl http://packages.ros.org/ros/ubuntu/dists/bionic/Release.gpg | apt-key add -

# Installing ROS
RUN apt-get update && apt-get install -y ros-melodic-desktop-full ros-melodic-moveit \
		wget git nano
RUN rosdep init && rosdep update

# Update Gazebo 9
RUN sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
RUN wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -
RUN apt-get update && apt-get install -y gazebo9 libignition-common

RUN sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EB3E94ADBE1229CF
RUN apt-get update && apt-get -y install code

RUN useradd -ms /bin/bash -G sudo -p rosdev rosdev
ADD /sudoers.txt /etc/sudoers
RUN chmod 440 /etc/sudoers

USER rosdev
WORKDIR /home/rosdev
ENV HOME  /home/rosdev


# Creating ROS_WS
RUN mkdir -p ~/ros_ws/src

# Set up the workspace
RUN /bin/bash -c "source /opt/ros/melodic/setup.bash && \
                  cd ~/ros_ws/ && \
                  catkin_make && \
                  echo 'export GAZEBO_MODEL_PATH=~/ros_ws/src/kinematics_project/kuka_arm/models' >> ~/.bashrc && \
                  echo 'source ~/ros_ws/devel/setup.bash' >> ~/.bashrc"

# Installing repo required for homework
RUN cd ~/ros_ws/src && git clone https://palmalcheg:iB3XLmh7@github.com/palmalcheg/RoboND-Kinematics-Project.git ~/ros_ws/src/kinematics_project   \
		&& git clone https://palmalcheg:iB3XLmh7@github.com/ros-planning/moveit_visual_tools.git ~/ros_ws/src/mvt

# Updating ROSDEP and installing dependencies
RUN cd ~/ros_ws && rosdep update && rosdep install --from-paths src --ignore-src --rosdistro=melodic -y

# Adding scripts and adding permissions
RUN cd ~/ros_ws/src/kinematics_project/kuka_arm/scripts && \
		chmod +x target_spawn.py && \
		chmod +x IK_server.py && \
		chmod +x safe_spawner.sh

# Sourcing
RUN /bin/bash -c "source /opt/ros/melodic/setup.bash && \
                  cd ~/ros_ws/ && rm -rf build devel && \
                  catkin_make"

# Dunno about this one tbh
RUN /bin/bash -c "echo 'export GAZEBO_MODEL_PATH=~/ros_ws/src/kinematics_project/kuka_arm/models' >> ~/.bashrc && \
                  echo 'source ~/ros_ws/devel/setup.bash' >> ~/.bashrc"

RUN code --install-extension ms-vscode.cpptools && code  --install-extension ajshort.ros
ENV USER rosdev
ENV PASSWORD rosdev
