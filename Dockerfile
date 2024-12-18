# Start with a base image
FROM python:3.10-slim

# Set PYTHONPATH to include the python_utils directory
ENV PYTHONPATH="/app/lib/python_utils:/app/lib"

# Update apt repository and install necessary dependencies, including ffmpeg
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    python3 \
    python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app


# Copy all files into the Docker image
COPY bin /app/bin
COPY lib /app/lib
COPY conf /app/conf
COPY requirements.txt /app/requirements.txt
COPY Dockerfile /app/Dockerfile


# Install Python dependencies
RUN pip3 install --upgrade pip && pip3 install -r requirements.txt --root-user-action=ignore

# Debug: List all files in /app and verify the content of lib/python_utils
RUN ls -la /app && ls -la /app/lib && ls -la /app/lib/python_utils

# Debug: Verify requirements.txt is in the container
RUN cat /app/requirements.txt

# Debug: Verify Python environment and MoviePy installation
RUN python3 -c "import sys; print(sys.version)"
RUN python3 -c "import site; print(site.getsitepackages())"
RUN python3 -c "import moviepy; print('MoviePy is correctly installed')"


