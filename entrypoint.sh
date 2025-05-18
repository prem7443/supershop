#!/bin/bash

# Exit on any error
set -e

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Start Gunicorn
echo "Starting Gunicorn..."
exec gunicorn your_project_name.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 3
