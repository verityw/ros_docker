# Start from debian
FROM ubuntu:focal-20220426

ENV DEBIAN_FRONTEND noninteractive
# ENV TZ=America/Boston

# Update so we can download packages
RUN apt update
#Set the ROS distro
ENV ROS_DISTRO noetic

# Add the ROS keys and package
RUN apt install -y \
    lsb-release \
    curl \
    gnupg
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s "https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc" | apt-key add -

# Install ROS
RUN apt update
RUN apt install -y \
    ros-$ROS_DISTRO-desktop-full \
    python3-rosdep

# Set up ROS
RUN rosdep init
RUN rosdep update

# Install VNC and things to install noVNC
RUN apt install -y \
    tigervnc-standalone-server \
    wget \
    git \
    unzip

# Download NoVNC and unpack
ENV NO_VNC_VERSION 1.3.0
RUN wget -q https://github.com/novnc/noVNC/archive/v$NO_VNC_VERSION.zip
RUN unzip v$NO_VNC_VERSION.zip
RUN rm v$NO_VNC_VERSION.zip
RUN git clone https://github.com/novnc/websockify /noVNC-$NO_VNC_VERSION/utils/websockify

# Install a window manager
RUN apt install -y \
    openbox \
    x11-xserver-utils \
    xterm \
    dbus-x11

# Install the racecar simulator
RUN apt install -y \
    ros-$ROS_DISTRO-tf2-geometry-msgs \
    ros-$ROS_DISTRO-ackermann-msgs \
    ros-$ROS_DISTRO-joy \
    ros-$ROS_DISTRO-map-server \
    build-essential \
    cython
ENV SIM_WS /opt/ros/sim_ws
RUN mkdir -p $SIM_WS/src
RUN git clone https://github.com/mit-racecar/racecar_simulator.git
RUN mv racecar_simulator $SIM_WS/src
RUN /bin/bash -c 'source /opt/ros/$ROS_DISTRO/setup.bash; cd $SIM_WS; catkin_make; catkin_make install;'

# Add the ROS master
ENV ROS_MASTER_URI http://racecar:11311

# Set the locale and keyboard
RUN apt install -y \
    locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen
RUN DEBIAN_FRONTEND=noninteractive \
    apt install -y \
    console-setup

# Install some cool programs
RUN apt install -y \
    sudo \
    vim \
    emacs \
    nano \
    gedit \
    screen \
    tmux \
    iputils-ping \
    feh

# Fix some ROS things
run apt install -y \
    python3-pip \
    ros-$ROS_DISTRO-compressed-image-transport \
    libfreetype6-dev
RUN pip3 install -U pip
RUN pip3 install imutils
RUN pip3 install -U matplotlib

# Kill the bell!
RUN echo "set bell-style none" >> /etc/inputrc

# Copy in the entrypoint
COPY ./entrypoint.sh /usr/bin/entrypoint.sh
COPY ./xstartup.sh /usr/bin/xstartup.sh

# Copy in default config files
COPY ./config/bash.bashrc /etc/
COPY ./config/screenrc /etc/
COPY ./config/vimrc /etc/vim/vimrc
ADD ./config/openbox /etc/X11/openbox/
COPY ./config/XTerm /etc/X11/app-defaults/
COPY ./config/default.rviz /opt/ros/$ROS_DISTRO/share/rviz/

# Creat a user
RUN useradd -ms /bin/bash racecar
RUN echo 'racecar:racecar@mit' | chpasswd
RUN adduser racecar sudo
USER racecar
WORKDIR /home/racecar
