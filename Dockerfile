FROM python:3.12-alpine

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Використовуємо ARG для отримання змінних під час збірки
ARG POSTGRES_HOST
ARG POSTGRES_PORT=5432
ARG POSTGRES_NAME
ARG POSTGRES_USER
ARG POSTGRES_PASSWORD

# Встановлюємо ENV змінні з ARG
ENV POSTGRES_HOST=${POSTGRES_HOST}
ENV POSTGRES_PORT=${POSTGRES_PORT}
ENV POSTGRES_NAME=${POSTGRES_NAME}
ENV POSTGRES_USER=${POSTGRES_USER}
ENV POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

COPY . .
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
