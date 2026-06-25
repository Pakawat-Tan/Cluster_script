# ใช้ NVIDIA CUDA runtime base image
FROM nvidia/cuda:12.5.1-cudnn-runtime-ubuntu22.04

# Metadata labels
LABEL maintainer="Pakawat Tanyaphirom <Pakawat.tan@outlook.com>" \
      version="3.3" \
      description="All-in-One Optimized ML/DL Image with Global Jupyter Shortcut" \
      author="Pakawat Tanyaphirom"

# ตั้งค่า Environment เพื่อให้ทำงานเสถียรบนสิทธิ์จำกัดของ Slurm
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda-12.5 \
    PATH=/usr/local/cuda-12.5/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/cuda-12.5/lib64:$LD_LIBRARY_PATH \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DEFAULT_TIMEOUT=100

# 1. ติดตั้ง System Packages และ Python 3.10
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common wget curl git ca-certificates libgl1 libglib2.0-0 libgomp1 && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3.10-dev python3.10-venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /workspace
RUN chmod -R 777 /workspace

# ==============================================================================
# 2. Setup Environmentที่ 1: สำหรับสาย PyTorch 2.4 (เป็นโฮสต์คุม Jupyter)
# ==============================================================================
RUN python3.10 -m venv /opt/pytorch_env && \
    /opt/pytorch_env/bin/pip install -U "pip<24.1" setuptools wheel && \
    /opt/pytorch_env/bin/pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu124 && \
    /opt/pytorch_env/bin/pip install numpy pandas matplotlib seaborn plotly scikit-learn tqdm opencv-python && \
    /opt/pytorch_env/bin/pip install ultralytics roboflow supervision && \
    /opt/pytorch_env/bin/pip install notebook jupyter ipykernel ipywidgets && \
    /opt/pytorch_env/bin/python -m ipykernel install --name=pytorch-env --display-name="Python 3 (PyTorch 2.4 + CV)"

# ==============================================================================
# 3. Setup Environmentที่ 2: สำหรับสาย TensorFlow 2.20 + Ultralytics + NLP + AutoML
# ==============================================================================
RUN python3.10 -m venv /opt/tf_env && \
    /opt/tf_env/bin/pip install -U "pip<24.1" setuptools wheel && \
    /opt/tf_env/bin/pip install "numpy<2.0.0" "idna==3.7" && \
    /opt/tf_env/bin/pip install https://storage.googleapis.com/tensorflow/versions/2.20.0/tensorflow-2.20.0-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl && \
    /opt/tf_env/bin/pip install keras protobuf tensorboard && \
    /opt/tf_env/bin/pip install ultralytics && \
    /opt/tf_env/bin/pip install pandas matplotlib seaborn plotly scikit-learn tqdm opencv-python roboflow supervision && \
    /opt/tf_env/bin/pip install xgboost lightgbm catboost && \
    /opt/tf_env/bin/pip install transformers gensim textblob nltk spacy && \
    /opt/tf_env/bin/pip install https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.7.1/en_core_web_sm-3.7.1-py3-none-any.whl && \
    /opt/tf_env/bin/pip install TPOT optuna dask-ml ray && \
    /opt/tf_env/bin/python -c "import nltk; nltk.download('punkt'); nltk.download('stopwords'); nltk.download('wordnet'); nltk.download('omw-1.4')" || true && \
    /opt/tf_env/bin/pip install ipykernel ipywidgets && \
    /opt/tf_env/bin/python -m ipykernel install --name=tf-env --display-name="Python 3 (TF 2.20 + Ultralytics + NLP)"

# ==============================================================================
# 4. สร้าง Symlink เชื่อมโยงคำสั่ง Jupyter ออกมาให้ระบบหลักใช้งานได้โดยตรง
# ==============================================================================
RUN ln -s /opt/pytorch_env/bin/jupyter /usr/local/bin/jupyter && \
    ln -s /opt/pytorch_env/bin/jupyter-notebook /usr/local/bin/jupyter-notebook

# ==============================================================================
# 5. ทำความสะอาดแคชระบบลบเฉพาะ __pycache__ 
# ==============================================================================
RUN find /opt/pytorch_env/lib/python3.10/dist-packages -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/tf_env/lib/python3.10/dist-packages -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    rm -rf /root/.cache

EXPOSE 8888

# แก้ไขคำสั่งเริ่มต้นให้ใช้สิทธิ์ทางลัดได้ทันที
CMD ["jupyter-notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]