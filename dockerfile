FROM python:3.9-slim-buster

LABEL Name="Python Django Demo App" Version=1.0.0
LABEL org.opencontainers.image.source="https://github.com/benc-uk/python-demoapp"

ARG srcDir=src
WORKDIR /app
COPY $srcDir/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Django application
COPY $srcDir/manage.py .
COPY $srcDir/app ./app

# Expose the default Django port
EXPOSE 8000

# Run Django application using gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:8000", "app.wsgi:application"]
