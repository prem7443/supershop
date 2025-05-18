#!/bin/bash
set -e

echo "🔄 Running migrations..."
python manage.py migrate

echo "🚀 Starting server..."
exec python manage.py runserver 0.0.0.0:8000
