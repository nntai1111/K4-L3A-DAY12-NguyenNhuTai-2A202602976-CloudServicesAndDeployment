FROM python:3.11-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --timeout 120 --retries 10 --prefix=/install -r requirements.txt

FROM python:3.11-slim AS runtime

RUN useradd --create-home --uid 10001 appuser

WORKDIR /app
COPY --from=builder /install /usr/local
COPY app ./app
COPY utils ./utils

USER appuser

ENV PORT=8000
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import os,urllib.request; p=os.environ.get('PORT','8000'); urllib.request.urlopen('http://127.0.0.1:%s/health'%p, timeout=3).read()" || exit 1

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
