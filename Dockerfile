FROM covlineages/pangolin:latest
RUN pangolin -v > /pangolin_version
ADD entrypoint.sh make_reports.py /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh /usr/bin/make_reports.py
ADD https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip /tmp/awscli.zip
RUN cd /tmp && unzip awscli.zip && aws/install && rm -rf awscli.zip aws
ENTRYPOINT /usr/bin/entrypoint.sh
