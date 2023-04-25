FROM amd64/centos:8

COPY cli /root/warp/

RUN set -x \
	&& cd /etc/yum.repos.d/ \
    && sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* \
    && curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.tencent.com/repo/centos8_base.repo \
	&& yum clean all \
	&& yum makecache \
    && yum install epel-release -y 

WORKDIR /root/warp/

RUN set -x \
    && rpm -ivh http://pkg.cloudflareclient.com/cloudflare-release-el8.rpm \
    && yum install screen socat cloudflare-warp -y \
    && chmod +x run.sh \
    && screen -dmS warp warp-svc && sleep 3 \
    && warp-cli --accept-tos register  && warp-cli --accept-tos set-mode proxy