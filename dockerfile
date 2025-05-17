FROM python:3.9-slim-buster

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libffi-dev \
    libssl-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Django app files
COPY manage.py .
COPY mainApp ./mainApp
COPY supershop ./supershop

EXPOSE 8000

# Start Gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:8000", "supershop.wsgi:application"]
