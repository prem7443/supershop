FROM python:3.9-slim-buster

WORKDIR /app

# Copy and install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Django app files
COPY manage.py .
COPY mainApp ./mainApp
COPY supershop ./supershop

EXPOSE 8000

CMD ["gunicorn", "-b", "0.0.0.0:8000", "supershop.wsgi:application"]
