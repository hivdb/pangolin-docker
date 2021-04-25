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
COPY pangolin pangolin
ARG SNAKEMAKE_VER=5.13.0
ARG PANGOLEARN_VER=2021-04-23
RUN pip install --target /python-packages \
        snakemake==${SNAKEMAKE_VER} \
        pangolin/ \
        https://github.com/cov-lineages/pangoLEARN/archive/refs/tags/${PANGOLEARN_VER}.tar.gz
RUN mv /python-packages/bin /python-scripts

FROM public.ecr.aws/lambda/python:3.8
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

COPY --from=installer /usr/bin/which /usr/bin/which
COPY --from=installer /opt/minimap2 /opt/minimap2
COPY --from=installer /usr/bin/minimap2 /usr/bin/gofasta /usr/bin/
COPY --from=installer /python-scripts/ /var/lang/bin/
COPY --from=installer /python-packages/ /var/lang/lib/python3.8/site-packages/
RUN pangolin -v > /pangolin_version.txt
COPY app.py ./
CMD ["app.main"]


# FROM covlineages/pangolin:latest
# RUN pangolin -v > /pangolin_version
# ADD entrypoint.sh make_reports.py /usr/bin/
# RUN chmod +x /usr/bin/entrypoint.sh /usr/bin/make_reports.py
# ADD https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip /tmp/awscli.zip
# RUN cd /tmp && unzip awscli.zip && aws/install && rm -rf awscli.zip aws
# ENTRYPOINT /usr/bin/entrypoint.sh
