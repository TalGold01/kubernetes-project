# FIX: Use Amazon ECR Public to avoid Docker Hub Rate Limiting
FROM public.ecr.aws/docker/library/python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose port 80
EXPOSE 80

# Start command
CMD ["python", "app.py"]