# Use an official ROS Noetic full desktop image as the base
FROM osrf/ros:noetic-desktop-full

# Avoid prompts from APT during build by specifying non-interactive as the frontend
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

# Set the location of the Gazebo Plugin Path
ENV GAZEBO_PLUGIN_PATH=/usr/lib/x86_64-linux-gnu/gazebo-11/plugins:$GAZEBO_PLUGIN_PATH

# Define user-related arguments to create a non-root user inside the container
ARG USERNAME=tommaselli
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create a new group and user, setup directories, and install sudo
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir /home/$USERNAME/.config && chown $USER_UID:$USER_GID /home/$USERNAME/.config \
    && apt-get update \
    && apt-get install -y sudo \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# Install Git
RUN apt-get update && apt-get install -y git-all && rm -rf /var/lib/apt/lists/*

# Install various packages for development with ROS and other tools
RUN apt-get update && \
    apt-get install -y \
       libgl1-mesa-glx libgl1-mesa-dri mesa-utils psmisc curl gnupg2 lsb-release nano \
       ros-noetic-rviz wget build-essential python3-catkin-tools liburdfdom-dev liboctomap-dev \
       libassimp-dev ros-noetic-tf2-tools ros-noetic-usb-cam ros-noetic-perception \
       ros-noetic-cv-bridge ros-noetic-teleop-twist-keyboard python3-opencv python3 python3-pip \
       python-numpy ros-noetic-hector-gazebo-plugins ros-noetic-velodyne ros-noetic-velodyne-simulator \
       ros-noetic-velodyne-description ros-noetic-pointcloud-to-laserscan ros-noetic-twist-mux \
       ros-noetic-robot-localization ros-noetic-gazebo-plugins ros-noetic-rqt-multiplot \
       python3-colcon-common-extensions ffmpeg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install NVIDIA container runtime and CUDA
RUN curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | apt-key add - && \
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && \
    curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | tee /etc/apt/sources.list.d/nvidia-container-runtime.list && \
    apt-get update && apt-get install -y nvidia-container-toolkit && \
    wget https://developer.download.nvidia.com/compute/cuda/12.4.1/local_installers/cuda_12.4.1_550.54.15_linux.run && \
    chmod +x cuda_12.4.1_550.54.15_linux.run && ./cuda_12.4.1_550.54.15_linux.run --silent --toolkit --override && \
    rm cuda_12.4.1_550.54.15_linux.run && apt-get update && rm -rf /var/lib/apt/lists/*

# Install additional packages and set up environment
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git nano rsync vim tree curl wget unzip htop tmux xvfb patchelf \
    ca-certificates bash-completion libjpeg-dev libpng-dev ffmpeg cmake swig libssl-dev \
    libcurl4-openssl-dev libopenmpi-dev python3-dev zlib1g-dev qtbase5-dev qtdeclarative5-dev \
    libglib2.0-0 libglu1-mesa-dev libgl1-mesa-dev libvulkan1 libgl1-mesa-glx libosmesa6 libosmesa6-dev \
    libglew-dev mesa-utils && \
    apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* && \
    mkdir /root/.ssh

# Install Miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && rm ~/miniconda.sh && \
    . /opt/conda/etc/profile.d/conda.sh && conda init && conda clean -ya
ENV PATH /opt/conda/bin:$PATH
SHELL ["/bin/bash", "-c"]

# Configure the conda environment
COPY nvidia_icd.json /usr/share/vulkan/icd.d/nvidia_icd.json
COPY environment.yaml /root
RUN conda update conda && \
    conda env update -n base -f /root/environment.yaml && \
    rm /root/environment.yaml && \
    conda clean -ya && pip cache purge

# Install specific Python packages
RUN pip install gym==0.21.0

# Add CUDA to PATH
ENV PATH=/usr/local/cuda/bin:$PATH

# Customize the bash prompt and terminal settings for root user
RUN echo 'export PS1="\[\e[1;32m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[1;33m\]\w\[\e[0m\]\$ "' >> /root/.bashrc && \
    echo "export TERM=xterm-256color" >> /etc/bash.bashrc && \
    echo 'export SVGA_VGPU10=0 \
export LIBGL_ALWAYS_SOFTWARE=0 \
export LIBGL_DEBUG=verbose \
export LD_LIBRARY_PATH=/usr/lib/nvidia-535:$LD_LIBRARY_PATH' >> /root/.bashrc

# Copy custom entrypoint script and .bashrc configuration
COPY config/entrypoint.sh /entrypoint.sh
COPY config/bashrc /home/${USERNAME}/.bashrc

# Set correct ownership of files
RUN chown $USER_UID:$USER_GID /home/$USERNAME/.bashrc && \
    chown -R root:root /opt/ros/noetic && \
    chmod -R 755 /opt/ros/noetic

# Final build success message
RUN echo "Successfully built ROS TD-MPC2 Docker image!"

# Set the custom script to be the container's entrypoint
ENTRYPOINT [ "/bin/bash", "/entrypoint.sh" ]

# Default command when the container is run, if no other commands are specified
CMD [ "bash" ]


