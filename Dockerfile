# ─── Stage 1 : builder ────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

# Patch glibc (CVE-2026-4437, CVE-2026-4046)
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY src/requirements.in .

RUN pip install --upgrade pip pip-tools \
 && pip-compile requirements.in --output-file requirements.lock \
 && pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.lock \
 && find /wheels -name "wheel-*.whl" -delete


# ─── Stage 2 : runtime ────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

# Patch glibc (CVE-2026-4437, CVE-2026-4046)
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Hardening : utilisateur non-root dédié
RUN groupadd --gid 1001 appgroup \
 && useradd --uid 1001 --gid appgroup --no-create-home --shell /sbin/nologin appuser

WORKDIR /app

COPY --from=builder /wheels /wheels
COPY --from=builder /build/requirements.lock /app/requirements.lock

RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.lock \
 && rm -rf /wheels /app/requirements.lock

# Code source et données
COPY src/ ./src/
COPY data/ ./data/

# Hardening : appartenance à appuser, pas de droit d'écriture sur le code
RUN chown -R appuser:appgroup /app \
 && chmod -R 550 /app/src \
 && chmod -R 440 /app/data \
 && chmod 550 /app/data

ENV STREAMLIT_BROWSER_GATHER_USAGE_STATS=false \
    STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_SERVER_PORT=8501 \
    STREAMLIT_SERVER_ADDRESS=0.0.0.0 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MPLCONFIGDIR=/tmp/matplotlib

USER appuser

EXPOSE 8501

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8501/_stcore/health')"

ENTRYPOINT ["python", "-m", "streamlit", "run", "src/Home.py", "--server.port=8501"]
