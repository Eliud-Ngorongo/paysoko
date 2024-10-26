# Stage 1: Build stage
FROM python:3.14-rc-slim AS builder

# Set working directory
WORKDIR /app

# Copy only requirements to install dependencies
COPY requirements.txt .

# Install dependencies in a virtual environment to avoid polluting the global environment
RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime stage
FROM python:3.14-rc-slim

# Create a non-root user and set the working directory
RUN useradd -m eliud
WORKDIR /app

# Copy the virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy the application code from the build stage
COPY . .

# Use the virtual environment's Python as the default
ENV PATH="/opt/venv/bin:$PATH"

# Change ownership of the app folder to the non-root user
RUN chown -R eliud /app

# Switch to the non-root user
USER eliud

# Start the application
CMD ["python", "app.py"]
