#!/bin/sh

echo "📦 Running database migrations..."
python manage.py migrate --noinput

echo "📁 Collecting static files..."
python manage.py collectstatic --noinput

echo "🚀 Starting Gunicorn server..."
exec gunicorn supershop.wsgi:application --bind 0.0.0.0:8000
