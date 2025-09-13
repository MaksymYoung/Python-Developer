# Базовий образ Python
FROM python:3.11-slim

# Встановити залежності системні
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Встановлюємо робочу директорію
WORKDIR /app

# Копіюємо файли requirements.txt у контейнер
COPY requirements.txt /app/

# Встановлюємо Python-залежності
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь проєкт
COPY . /app/

# Виставляємо змінну оточення для Python
ENV PYTHONUNBUFFERED=1

# Команда для запуску сервера (можна замінити на gunicorn для продакшена)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
