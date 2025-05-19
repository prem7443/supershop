# Use the official Python 3.10 image from Docker Hub
FROM python:3.10

# Set the working directory inside the container to /app
WORKDIR /app

# Copy the requirements.txt file into the container
COPY requirements.txt .

# Install the dependencies inside the container
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire Django project into the container
COPY . .


# This will place static files into the STATIC_ROOT directory you set in settings.py
RUN python manage.py collectstatic --noinput

# Expose port 8000 to the outside world (or any other port you want Django to run on)
EXPOSE 8000

# Set the default command to run the Django development server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
