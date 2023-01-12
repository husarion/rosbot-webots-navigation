ARG ROS_DISTRO=humble

FROM husarnet/ros:$ROS_DISTRO-ros-base AS package-builder

# Determine Webots version to be used and set default argument
ARG WEBOTS_VERSION=R2023a
ARG WEBOTS_PACKAGE_PREFIX=

RUN cd / && apt-get update && apt-get install --yes wget && rm -rf /var/lib/apt/lists/ && \
    wget https://github.com/cyberbotics/webots/releases/download/$WEBOTS_VERSION/webots-$WEBOTS_VERSION-x86-64$WEBOTS_PACKAGE_PREFIX.tar.bz2 && \
    tar xjf webots-*.tar.bz2 && rm webots-*.tar.bz2

RUN apt-get update -y && apt-get install -y git python3-colcon-common-extensions python3-vcstool \
                                            ros-$ROS_DISTRO-webots-ros2 ros-$ROS_DISTRO-robot-localization \
    && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN cd / && mkdir webots_assets && cd webots_assets && git clone https://github.com/husarion/webots.git webots -b husarion
WORKDIR /ros2_ws

RUN cd  /ros2_ws && \
    git clone https://github.com/husarion/webots_ros2.git src/webots_ros2 -b $ROS_DISTRO && \
    cd src/webots_ros2 && \
    git submodule update --init webots_ros2_husarion/rosbot_ros && \
    git submodule update --init webots_ros2_husarion/rosbot_xl_ros && \
    cd /ros2_ws

SHELL ["/bin/bash", "-c"]
RUN vcs import src < src/webots_ros2/webots_ros2_husarion/rosbot_xl_ros/rosbot_xl/rosbot_xl_hardware.repos && \
    vcs import src < src/webots_ros2/webots_ros2_husarion/rosbot_xl_ros/rosbot_xl/rosbot_xl_simulation.repos

RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
    colcon build --packages-select  webots_ros2_husarion \
                                    webots_ros2_driver \
                                    webots_ros2_msgs \
                                    rosbot_description \
                                    rosbot_bringup \
                                    rosbot_xl_description  \
                                    ros_components_description
FROM husarnet/ros:$ROS_DISTRO-ros-base

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
RUN apt-get update && apt-get install --yes wget && rm -rf /var/lib/apt/lists/ && \
  wget https://raw.githubusercontent.com/cyberbotics/webots/master/scripts/install/linux_runtime_dependencies.sh && \
  chmod +x linux_runtime_dependencies.sh && ./linux_runtime_dependencies.sh && rm ./linux_runtime_dependencies.sh && rm -rf /var/lib/apt/lists/

WORKDIR /ros2_ws
RUN apt-get update -y && apt-get install -y git wget ros-$ROS_DISTRO-ros-base ros-$ROS_DISTRO-webots-ros2 \
        ros-$ROS_DISTRO-xacro ros-$ROS_DISTRO-robot-localization ros-$ROS_DISTRO-laser-filters python3-pillow \
    && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=package-builder /ros2_ws /ros2_ws

ENTRYPOINT [ "/ros_entrypoint.sh" ]
