#!/bin/bash
echo "Running migrations..."
python manage.py migrate
echo "Starting Django..."
exec python manage.py runserver 0.0.0.0:8000
