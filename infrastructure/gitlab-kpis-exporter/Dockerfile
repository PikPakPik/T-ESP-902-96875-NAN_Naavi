FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the exporter script
COPY exporter.py .

# Make the script executable
RUN chmod +x exporter.py

# Expose the metrics port
EXPOSE 8080

# Run the exporter
CMD ["python", "-u", "exporter.py"]
