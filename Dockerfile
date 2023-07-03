FROM nvidia/cuda:11.8.0-base-ubuntu22.04 as cuda

ENV PYTHON_VERSION=3.10

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get -qq install --no-install-recommends \
    build-essential \
    libsndfile1-dev \
    git \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv \
    python3-pip \
    python3-dev \
    && pip3 install --no-cache-dir --upgrade setuptools \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s -f /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \
    ln -s -f /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
    ln -s -f /usr/bin/pip3 /usr/bin/pip

RUN pip install --upgrade pip

RUN pip3 install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118


FROM cuda as app
# 2. Copy files
COPY . /src

WORKDIR /src
# 3. Install dependencies
COPY /old_setup_files/requirements-pip.txt requirements-pip.txt
RUN pip install -r requirements-pip.txt

# 4. Install notebook
RUN pip install encodec rich-argparse

EXPOSE 8082 7860 8888 3000

# Set up the container startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Start the container
CMD ["/entrypoint.sh"]
