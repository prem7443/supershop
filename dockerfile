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
COPY manage.py ./
COPY mainApp ./mainApp
COPY supershop ./supershop

# For static files (optional)
RUN mkdir -p /app/static

# Copy and enable entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set entrypoint (runs migrate + starts server)
ENTRYPOINT ["/app/entrypoint.sh"]

# Expose port
EXPOSE 8000
