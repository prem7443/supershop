FROM python:3.9-slim-buster

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /app

# Add system dependencies for pip packages
RUN apt-get update && apt-get install -y \
    gcc \
    libffi-dev \
    libssl-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Show full error if pip install fails
RUN pip install --no-cache-dir -r requirements.txt || (echo "❌ Failed pip install" && cat requirements.txt)

COPY manage.py .
COPY mainApp ./mainApp
COPY supershop ./supershop

EXPOSE 8000

CMD ["gunicorn", "-b", "0.0.0.0:8000", "supershop.wsgi:application"]
