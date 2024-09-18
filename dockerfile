# Use a smaller base image
FROM ubuntu:22.04

# Metadata labels
LABEL maintainer="Pakawat Tanyaphirom <Pakawat.tan@outlook.com>"
LABEL version="1.5"
LABEL description="This is a Docker image for running Python 3.9 with TensorFlow and Jupyter Notebook."
LABEL author="Pakawat Tanyaphirom"

# Set noninteractive mode for apt-get to avoid timezone prompt
ENV DEBIAN_FRONTEND=noninteractive
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

# Add repository and install Python 3.9
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.9 python3.9-venv python3.9-dev python3.9-distutils && \
    rm -rf /var/lib/apt/lists/*

# Install pip for Python 3.8
RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python3.9 get-pip.py && \
    rm get-pip.py

# Copy and install Python packages
COPY requirements.txt /tmp/
RUN python3.9 -m pip install --upgrade pip && \
    python3.9 -m pip install jupyter && \
    python3.9 -m pip install -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Install CUDA 12.5 Update 1
RUN wget https://developer.download.nvidia.com/compute/cuda/12.5.1/local_installers/cuda-repo-ubuntu2204-12-5-local_12.5.1-555.42.06-1_amd64.deb && \
    dpkg -i cuda-repo-ubuntu2204-12-5-local_12.5.1-555.42.06-1_amd64.deb && \
    cp /var/cuda-repo-ubuntu2204-12-5-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && \
    apt-get -y install cuda-toolkit-12-5 && \
    rm -f cuda-repo-ubuntu2204-12-5-local_12.5.1-555.42.06-1_amd64.deb

# Install libcublas 12.5.3.2
# You can download the file from NVIDIA or click the link:
# https://developer.download.nvidia.com/compute/cuda/redist/libcublas/linux-x86_64/
# After downloading the file to your PC, you can move the file to the folder containing the Dockerfile and build the Docker image.
COPY libcublas-linux-x86_64-12.5.3.2-archive.tar.xz /tmp/
RUN tar -xvf /tmp/libcublas-linux-x86_64-12.5.3.2-archive.tar.xz -C /tmp && \
    cp -r /tmp/libcublas-linux-x86_64-12.5.3.2-archive/include/* /usr/local/cuda-12.5/include && \
    cp -r /tmp/libcublas-linux-x86_64-12.5.3.2-archive/lib/* /usr/local/cuda-12.5/lib64 && \
    chmod a+r /usr/local/cuda-12.5/include/*.h /usr/local/cuda-12.5/lib64/* && \
    rm -rf /tmp/libcublas-linux-x86_64-12.5.3.2-archive.tar.xz

# Install cuDNN 8.9.7
# You can download the file from NVIDIA or click the link:
# https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.7/local_installers/12.x/cudnn-linux-x86_64-8.9.7.29_cuda12-archive.tar.xz/
# After downloading the file to your PC, you can move the file to the folder containing the Dockerfile and build the Docker image.
COPY cudnn-linux-x86_64-8.9.7.29_cuda12-archive.tar.xz /tmp/
RUN tar -xvf /tmp/cudnn-linux-x86_64-8.9.7.29_cuda12-archive.tar.xz -C /tmp && \
    cp -r /tmp/cudnn-linux-x86_64-8.9.7.29_cuda12-archive/include/cudnn*.h /usr/local/cuda-12.5/include && \
    cp -r /tmp/cudnn-linux-x86_64-8.9.7.29_cuda12-archive/lib/libcudnn* /usr/local/cuda-12.5/lib64 && \
    chmod a+r /usr/local/cuda-12.5/include/cudnn*.h /usr/local/cuda-12.5/lib64/libcudnn* && \
    rm -rf /tmp/cudnn-linux-x86_64-8.9.7.29_cuda12-archive.tar.xz

# Install TensorRT 10.4.0
RUN wget https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.4.0/tars/TensorRT-10.4.0.26.Linux.x86_64-gnu.cuda-12.6.tar.gz && \
    tar -xzvf TensorRT-10.4.0.26.Linux.x86_64-gnu.cuda-12.6.tar.gz && \
    mv TensorRT-10.4.0.26 /usr/local/TensorRT && \
    cd /usr/local/TensorRT/python && \
    python3.9 -m pip install tensorrt-10.4.0-cp39-none-linux_x86_64.whl  \
    tensorrt_dispatch-10.4.0-cp39-none-linux_x86_64.whl \
    tensorrt_lean-10.4.0-cp39-none-linux_x86_64.whl && \
    rm -f TensorRT-10.4.0.26.Linux.x86_64-gnu.cuda-12.6.tar.gz

# Set environment variables for CUDA
ENV PATH=/usr/local/cuda-12.5/bin:/usr/local/TensorRT/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda-12.5/lib64:/usr/local/TensorRT/lib:/usr/local/cuda/extras/CUPTI/lib64
ENV CUDA_HOME=/usr/local/cuda-12.5

# Set working directory
WORKDIR /workspace

# Expose port for Jupyter Notebook
EXPOSE 8888

# Command to start Jupyter Notebook
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
