# Source ROS setup files
source /ros_ws/devel/setup.bash

# Ensure the scripts are executable
chmod +x /ros_ws/src/terra_utils/scripts/rowfollow_gt.py && \
chmod +x /ros_ws/src/terra_utils/scripts/perception_node_kp.py && \
chmod +x /ros_ws/src/terra_mpc/scripts/reference_path_publisher.py && \
chmod +x /ros_ws/src/terra_mpc/scripts/mpc_node.py

sudo chmod 777 /ros_ws

export ROS_MASTER_URI=http://localhost:11311
export ROS_HOSTNAME=localhost

# Set color prompt
export PS1="\[\e[1;32m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[1;33m\]\w\[\e[0m\]\$ "
export TERM=xterm-256color