# Use a smaller base image
FROM ubuntu:22.04

# Install system packages and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    build-essential \
    pkg-config \
    wget \
    curl \
    nano \
    cmake \
    git \
    dkms \
    gcc \
    g++ \
    make \
    python3 \
    python3-pip \
    python3-venv \
    gnupg \
    libhdf5-dev \
    libssl-dev \
    libffi-dev \
    libpq-dev \
    libxml2 \
    libgl1-mesa-glx \
    libprotobuf-dev \
    protobuf-compiler \
    apt-transport-https \
    ca-certificates \
    gnupg-agent && \
    rm -rf /var/lib/apt/lists/*

# Add repositories
RUN add-apt-repository ppa:cappelikan/ppa && \
    add-apt-repository ppa:canonical-kernel-team/ppa && \
    apt-get update

# Copy and install Python packages
COPY requirements.txt /tmp/
RUN pip install --upgrade pip && \
    pip install jupyter && \
    pip install -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Install CUDA 12.3
RUN wget https://developer.download.nvidia.com/compute/cuda/12.3.0/local_installers/cuda-repo-ubuntu2204-12-3-local_12.3.0-545.23.06-1_amd64.deb && \
    dpkg -i cuda-repo-ubuntu2204-12-3-local_12.3.0-545.23.06-1_amd64.deb && \
    cp /var/cuda-repo-ubuntu2204-12-3-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && \
    apt-get -y install cuda-toolkit-12-3 && \
    rm -f cuda-repo-ubuntu2204-12-3-local_12.3.0-545.23.06-1_amd64.deb

# Install cuDNN  9.3.0.75
# You can download the file from NVIDIA or click the link:
# https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/cudnn-linux-x86_64-9.3.0.75_cuda12-archive.tar.xz
# After downloading the file to your PC, you can move the file to the folder containing the Dockerfile and build the Docker image.
COPY cudnn-linux-x86_64-9.3.0.75_cuda11-archive.tar.xz /tmp/
RUN tar -xvf /tmp/cudnn-linux-x86_64-9.3.0.75_cuda11-archive.tar.xz -C /tmp && \
    cp -r /tmp/cudnn-linux-x86_64-9.3.0.75_cuda11-archive/include/cudnn*.h /usr/local/cuda-12.3/include && \
    cp -r /tmp/cudnn-linux-x86_64-9.3.0.75_cuda11-archive/lib/libcudnn* /usr/local/cuda-12.3/lib64 && \
    chmod a+r /usr/local/cuda-12.3/include/cudnn*.h /usr/local/cuda-12.3/lib64/libcudnn* && \
    rm -rf /tmp/cudnn-linux-x86_64-9.3.0.75_cuda12-archive*

# Install TensorRT 10.1.0
RUN wget https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.1.0/tars/TensorRT-10.1.0.27.Linux.x86_64-gnu.cuda-12.4.tar.gz && \
    tar -xzvf TensorRT-10.1.0.27.Linux.x86_64-gnu.cuda-12.4.tar.gz && \
    mv TensorRT-10.1.0.27 /usr/local/TensorRT && \
    cd /usr/local/TensorRT/python && \
    pip install tensorrt-10.1.0-cp310-none-linux_x86_64.whl \
    tensorrt_dispatch-10.1.0-cp310-none-linux_x86_64.whl \
    tensorrt_lean-10.1.0-cp310-none-linux_x86_64.whl && \
    rm -f TensorRT-10.1.0.27.Linux.x86_64-gnu.cuda-12.4.tar.gz

# Set environment variables for CUDA
ENV PATH=/usr/local/cuda-12.3/bin:/usr/local/TensorRT/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda-12.3/lib64:/usr/local/TensorRT/lib:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda-12.3

# Set working directory
WORKDIR /workspace

# Expose port for Jupyter Notebook
EXPOSE 8888

# Command to start Jupyter Notebook
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
