# Stage 1: OS-level dependencies and tools (i..e uv and ca-certificates)
FROM python:3.13-alpine3.21 AS builder

# Install needed tools and minimal Python3 packages
RUN apk add --no-cache \
    ca-certificates \
    curl

# Install uv
ADD https://astral.sh/uv/0.5.15/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv \
    && chmod +x /usr/local/bin/uv

# Remove curl needed only for uv instal
RUN apk del curl

# Non-root user
RUN adduser -D appuser
WORKDIR /home/appuser

# Stage 2: Code-level dependencies
FROM builder AS dependencies

# Install dependencies as root
COPY uv.lock pyproject.toml ./
RUN uv sync --frozen

# Was needed for secure & trusted uv installs
RUN apk del ca-certificates

# Stage 3: Runtime
FROM dependencies AS runtime

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
USER appuser

COPY ./app ./app

EXPOSE 80

CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80", "--proxy-headers"]