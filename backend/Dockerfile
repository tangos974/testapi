FROM python:3.13-alpine3.21 AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install essential tools and Python deps
RUN apk add --no-cache \
    build-base \
    ca-certificates \
    curl \
    && pip install --no-cache-dir --upgrade pip

# Install uv
ADD https://astral.sh/uv/0.5.15/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv \
    && chmod +x /usr/local/bin/uv

# Reduce size
RUN apk del build-base \
    && rm -rf /tmp/* /var/tmp/* /lib/apk/db/*

# Non-root user
RUN adduser -D appuser
USER appuser

WORKDIR /home/appuser

# Copy and install uv dependencies
COPY --chown=appuser:appuser uv.lock .
COPY --chown=appuser:appuser pyproject.toml .
RUN uv sync --frozen

COPY ./app ./app

EXPOSE 80

CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80", "--proxy-headers"]