FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Django project files
COPY manage.py .
COPY mainApp ./mainApp
COPY supershop ./supershop

# For static files (if needed)
RUN mkdir -p /app/static

# Expose the port Django will run on
EXPOSE 8000

# Run development server (for production use gunicorn instead)
#CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# ✅ Run migrations and then start the server
CMD ["sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8000"]
