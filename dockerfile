FROM python:3.9-slim-buster

LABEL Name="Python Django Demo App" Version=1.0.0
LABEL org.opencontainers.image.source="https://github.com/benc-uk/python-demoapp"

WORKDIR /app

# Install dependencies
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Django application files
COPY src/manage.py .
COPY src/app ./app

EXPOSE 8000

CMD ["gunicorn", "-b", "0.0.0.0:8000", "app.wsgi:application"]
