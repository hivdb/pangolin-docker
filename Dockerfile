FROM public.ecr.aws/lambda/python:3.8 as installer
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ARG MINIMAP2_VER=2.17
RUN yum install -y which tar bzip2 && \
    mkdir -p /opt/minimap2 && \
    curl -sSL https://github.com/lh3/minimap2/releases/download/v${MINIMAP2_VER}/minimap2-${MINIMAP2_VER}_x64-linux.tar.bz2 -o minimap2.tar.bz2 && \
    tar -xf minimap2.tar.bz2 -C /opt/minimap2 --strip-components 1 && \
    rm -f minimap2-${MINIMAP2_VER}_x64-linux.tar.bz2 && \
    ln -s /opt/minimap2/minimap2 /usr/bin
ARG GOFASTA_VER=0.03
RUN curl -sSL https://github.com/cov-ert/gofasta/releases/download/v0.0.3/gofasta-linux-amd64 -o /usr/bin/gofasta && \
    chmod +x /usr/bin/gofasta
ARG PANGOLIN_VER=refs/tags/v3.1.7
ARG SNAKEMAKE_VER=5.13.0
ARG PANGOLEARN_VER=refs/tags/2021-07-09
ARG SCORPIO_VER=refs/tags/v0.3.6
ARG CONSTELLATIONS_VER=refs/tags/v0.0.11
ARG PANGODEST_VER=refs/tags/v1.2.38
RUN pip install --target /python-packages \
        snakemake==${SNAKEMAKE_VER} \
        https://github.com/cov-lineages/pangolin/archive/${PANGOLIN_VER}.tar.gz \
        https://github.com/cov-lineages/pangoLEARN/archive/${PANGOLEARN_VER}.tar.gz \
        https://github.com/cov-lineages/scorpio/archive/${SCORPIO_VER}.tar.gz \
        https://github.com/cov-lineages/constellations/archive/${CONSTELLATIONS_VER}.tar.gz \
        https://github.com/cov-lineages/pango-designation/archive/${PANGODEST_VER}.tar.gz
RUN mv /python-packages/bin /python-scripts

FROM public.ecr.aws/lambda/python:3.8
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

COPY --from=installer /usr/bin/which /usr/bin/which
COPY --from=installer /opt/minimap2 /opt/minimap2
COPY --from=installer /usr/bin/minimap2 /usr/bin/gofasta /usr/bin/
COPY --from=installer /python-scripts/ /var/lang/bin/
COPY --from=installer /python-packages/ /var/lang/lib/python3.8/site-packages/
RUN touch /usr/bin/usher && chmod +x /usr/bin/usher
RUN pangolin -v > /pangolin_version.txt
COPY app.py ./
CMD ["app.main"]
