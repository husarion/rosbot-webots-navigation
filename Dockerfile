ARG ROS_DISTRO=humble
ARG PREFIX=

FROM husarnet/ros:${PREFIX}${ROS_DISTRO}-ros-base AS package-builder

ARG PREFIX

# Determine Webots version to be used and set default argument
ARG WEBOTS_VERSION=R2023a

# https://github.com/cyberbotics/webots/tags
ARG WEBOTS_REALESE_NAME=R2023a
ARG WEBOTS_PACKAGE_PREFIX=

RUN cd / && apt-get update && apt-get install --yes wget && rm -rf /var/lib/apt/lists/ && \
    wget https://github.com/cyberbotics/webots/releases/download/$WEBOTS_REALESE_NAME/webots-$WEBOTS_VERSION-x86-64$WEBOTS_PACKAGE_PREFIX.tar.bz2 && \
    tar xjf webots-*.tar.bz2 && rm webots-*.tar.bz2

RUN apt-get update -y && apt-get install -y git python3-colcon-common-extensions python3-vcstool python3-rosdep curl

RUN cd / && mkdir webots_assets && cd webots_assets && git clone -n https://github.com/cyberbotics/webots && cd webots && \
    # back to 2023a
    git checkout 3f01381
WORKDIR /ros2_ws

RUN cd  /ros2_ws && \
    git clone -n https://github.com/husarion/webots_ros2.git src/webots_ros2 && \
    cd src/webots_ros2 && \
    # back to 2023a
    git checkout  d2d8f38 && \
    git submodule update --init && cd /ros2_ws && \
    # remove all unnecessery packages
    find src/webots_ros2/webots_ros2_husarion/rosbot* -maxdepth 1 -type d !  \( -name "*_description"  -o -name "*_ros" \) -exec rm -r {} \;

SHELL ["/bin/bash", "-c"]

RUN MYDISTRO=${PREFIX:-ros}; MYDISTRO=${MYDISTRO//-/} && \
    source /opt/$MYDISTRO/$ROS_DISTRO/setup.bash && \
    # without this line (using vulcanexus base image) rosdep init throws error: "ERROR: default sources list file already exists:"
    rm -rf /etc/ros/rosdep/sources.list.d/20-default.list && \
    rosdep init && \
    rosdep update --rosdistro $ROS_DISTRO && \
    rosdep install --ignore-src --from-path src/webots_ros2/ -y --rosdistro $ROS_DISTRO
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && colcon build

FROM husarnet/ros:${PREFIX}${ROS_DISTRO}-ros-base

SHELL ["/bin/bash", "-c"]
ARG ROS_DISTRO
ENV ROS_DISTRO $ROS_DISTRO

COPY --from=package-builder /webots/ /usr/local/webots/
COPY --from=package-builder /webots_assets/webots/projects/appearances/ /usr/local/webots/projects/appearances/
COPY --from=package-builder /webots_assets/webots/projects/devices/orbbec/ /usr/local/webots/projects/devices/orbbec/
COPY --from=package-builder /webots_assets/webots/projects/devices/tdk/ /usr/local/webots/projects/devices/tdk/protos/
COPY --from=package-builder /webots_assets/webots/projects/objects/ /usr/local/webots/projects/objects/
COPY --from=package-builder /webots_assets/webots/projects/objects/backgrounds/ /usr/local/webots/projects/objects/backgrounds/
COPY --from=package-builder /webots_assets/webots/projects/objects/floors/ /usr/local/webots/projects/objects/floors/
COPY --from=package-builder /webots_assets/webots/projects/default/worlds/textures/cubic/ /usr/local/webots/projects/default/worlds/textures/cubic/
COPY --from=package-builder /webots_assets/webots/projects/devices/tdk/ /usr/local/webots/projects/devices/tdk/
COPY --from=package-builder /webots_assets/webots/projects/robots/husarion/ /usr/local/webots/projects/robots/husarion/
COPY --from=package-builder /webots_assets/webots/projects/devices/slamtec/ /usr/local/webots/projects/devices/slamtec/

ENV QTWEBENGINE_DISABLE_SANDBOX=1
ENV WEBOTS_HOME /usr/local/webots
ENV PATH /usr/local/webots:${PATH}

# Disable dpkg/gdebi interactive dialogs
ENV DEBIAN_FRONTEND=noninteractive

# Install Webots runtime dependencies
RUN apt-get update && apt-get install -y \
     wget && \
    rm -rf /var/lib/apt/lists/ && \
    wget https://raw.githubusercontent.com/cyberbotics/webots/master/scripts/install/linux_runtime_dependencies.sh && \
    chmod +x linux_runtime_dependencies.sh && ./linux_runtime_dependencies.sh && rm ./linux_runtime_dependencies.sh && rm -rf /var/lib/apt/lists/

COPY --from=package-builder /ros2_ws /ros2_ws

RUN apt-get update --fix-missing -y && apt-get install -y python3-rosdep && \
    # without this line (using vulcanexus base image) rosdep init throws error: "ERROR: default sources list file already exists:"
    rm -rf /etc/ros/rosdep/sources.list.d/20-default.list && \
    rosdep init && \
    rosdep update --rosdistro $ROS_DISTRO && \
    rosdep install --ignore-src --from-path src/webots_ros2/ -r -y --rosdistro $ROS_DISTRO  && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV USERNAME=root

RUN echo $(dpkg -s ros-$ROS_DISTRO-webots-ros2 | grep 'Version' | sed -r 's/Version:\s([0-9]+.[0-9]+.[0-9]*).*/\1/g') > /version.txt
