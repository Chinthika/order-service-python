FROM python:3.9-slim

WORKDIR /app

# Set Python path to include current directory
ENV PYTHONPATH=/app

# Copy requirements file
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set New Relic config file as an environment variable
ENV NEW_RELIC_CONFIG_FILE=newrelic.ini

# Command to run the application
ENTRYPOINT ["newrelic-admin","run-program","uvicorn","main:app","--host","0.0.0.0","--port","8000"]

EXPOSE 8000
