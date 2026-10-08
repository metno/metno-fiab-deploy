FROM node:24.18.0-slim AS frontend-builder

WORKDIR /fiab/frontend
COPY forecast-in-a-box/frontend/package.json forecast-in-a-box/frontend/package-lock.json ./
RUN npm ci
COPY forecast-in-a-box/frontend/ ./
RUN npm run prodbuild


FROM ubuntu:26.04

RUN apt-get update && \
    apt-get install -y \
        curl ca-certificates \
        git \
        build-essential \
        libgfortran5 libgomp1 \
        gdal-bin libgdal-dev \
        libudunits2-dev \
        libglib2.0-0t64 \
        gosu
ENV UDUNITS2_XML_PATH=/usr/share/xml/udunits/udunits2.xml

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

RUN useradd --system --user-group --create-home --shell /bin/false fiab
USER fiab

COPY --chown=fiab:fiab forecast-in-a-box/backend/ /fiab/backend/
COPY --chown=fiab:fiab forecast-in-a-box/install/ /fiab/install/
COPY --chown=fiab:fiab --from=frontend-builder /fiab/frontend/dist /fiab/backend/src/forecastbox/static

WORKDIR /fiab/backend/


RUN uv sync --extra runtime --all-packages
# Temporary fix because of upstream bug
RUN sed -i -E 's/manylinux2014_sbsa/manylinux2014_aarch64/'  .venv/lib/python3.13/site-packages/nvidia_cusparselt_cu13-0.8.1.dist-info/WHEEL

# ptxas needs to be available _before_ cascade creates its environment, for some reason
RUN uv pip install --target /fiab/tools/   --index-strategy unsafe-best-match   "nvidia-cuda-nvcc-cu12==12.9.86"
ENV TRITON_PTXAS_PATH=/fiab/tools/nvidia/cuda_nvcc/bin/ptxas

RUN mkdir -p /home/fiab/.fiab/data_dir
RUN echo "$(date +%s):d0.0.1" > /home/fiab/.fiab/pylock.toml.timestamp

# COPY --chown=fiab:fiab config.toml /home/fiab/.fiab/config.toml

COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Switch back to root so the entrypoint can fix ownership of mounted
# volumes before dropping privileges back to fiab via gosu.
USER root

EXPOSE 8000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["uv", "run", "--no-sync", "python", "-m", "forecastbox.entrypoint.main"]
