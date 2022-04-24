ARG IMAGE_REPOSITORY=quay.io/eduk8s
FROM ${IMAGE_REPOSITORY}/pkgs-java-tools as java-tools

FROM registry.tanzu.vmware.com/tanzu-application-platform/tap-packages@sha256:681ef8d2e6fc8414b3783e4de424adbfabf2aa0126e34fa7dcd07dab61e55a89

COPY --from=java-tools --chown=1001:0 /opt/jdk11 /opt/java
COPY --from=java-tools --chown=1001:0 /opt/gradle /opt/gradle
COPY --from=java-tools --chown=1001:0 /opt/maven /opt/maven
COPY --from=java-tools --chown=1001:0 /home/eduk8s/. /home/eduk8s/
COPY --from=java-tools --chown=1001:0 /opt/eduk8s/. /opt/eduk8s/

ENV PATH=/opt/java/bin:/opt/gradle/bin:/opt/maven/bin:$PATH \
    JAVA_HOME=/opt/java \
    M2_HOME=/opt/maven

# All the direct Downloads need to run as root as they are going to /usr/local/bin
USER root
# TBS
RUN curl -L -o /usr/local/bin/kp https://github.com/vmware-tanzu/kpack-cli/releases/download/v0.4.2/kp-linux-0.4.2 && \
  chmod 755 /usr/local/bin/kp
# Tanzu CLI
COPY tanzu-framework-linux-amd64.tar /tmp
RUN export TANZU_CLI_NO_INIT=true
RUN cd /tmp && tar -xvf "tanzu-framework-linux-amd64.tar" -C /tmp && \ 
    sudo install "cli/core/v0.11.2/tanzu-core-linux_amd64" /usr/local/bin/tanzu && \ 
    tanzu plugin install --local cli all
# Knative
RUN curl -L -o /usr/local/bin/kn https://github.com/knative/client/releases/download/knative-v1.1.0/kn-linux-amd64 && \
    chmod 755 /usr/local/bin/kn

# pivnet CLI
RUN curl -L -o /usr/local/bin/pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1  && \
    chmod 755 /usr/local/bin/pivnet
    
# Utilities
RUN apt-get update && apt-get install -y unzip

# Install krew
RUN \
( \
  set -x; cd "$(mktemp -d)" && \
  OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
  KREW="krew-${OS}_${ARCH}" && \
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
  tar zxvf "${KREW}.tar.gz" && \
  ./"${KREW}" install krew \
)
RUN echo "export PATH=\"${KREW_ROOT:-$HOME/.krew}/bin:$PATH\"" >> ${HOME}/.bashrc
ENV PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
RUN kubectl krew install tree
RUN kubectl krew install view-secret
RUN kubectl krew install ctx
RUN kubectl krew install ns
RUN kubectl krew install konfig
RUN kubectl krew install eksporter
RUN kubectl krew install slice
RUN kubectl krew install duck
RUN chmod 775 -R $HOME/.krew
RUN apt update
RUN apt install ruby-full -y

# Install CF CLI 
RUN curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v7&source=github" | tar -zx
RUN mv cf /usr/local/bin
RUN sudo curl -o /usr/share/bash-completion/completions/cf7 https://raw.githubusercontent.com/cloudfoundry/cli-ci/master/ci/installers/completion/cf7


# Install GCP CLI
RUN curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-372.0.0-linux-x86_64.tar.gz > /tmp/google-cloud-sdk.tar.gz
RUN mkdir -p /usr/local/gcloud \
    && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
    && /usr/local/gcloud/google-cloud-sdk/install.sh \
    && chmod 775 -R /usr/local/gcloud


# Install AWS CLI
RUN curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/*/dist/aws_completer \
        /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/*/dist/awscli/examples
RUN echo "alias gcloud=/usr/local/gcloud/google-cloud-sdk/bin/gcloud" >> ${HOME}/.bashrc

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install tekton cli
RUN curl -LO https://github.com/tektoncd/cli/releases/download/v0.23.0/tkn_0.23.0_Linux_x86_64.tar.gz \
    && tar xvzf tkn_0.23.0_Linux_x86_64.tar.gz -C /usr/local/bin tkn \
    && chmod 755 /usr/local/bin/tkn

RUN rm -rf /tmp/*

# Install Azure DevOps Build Agent (Optional Use) 

ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        git \
        iputils-ping \
        libcurl4 \
        libicu60 \
        libunwind8 \
        netcat \
        libssl1.0 \
        maven \
        time \
        unzip \
        wget \
        zip \
        tzdata \
        apt-utils \
        apt-transport-https \
        xvfb \
        sudo \
        nodejs \
        gnupg-agent \
        software-properties-common \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/apt/sources.list.d/*

RUN curl https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb > packages-microsoft-prod.deb \
 && dpkg -i packages-microsoft-prod.deb \
 && rm packages-microsoft-prod.deb \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    apt-transport-https \
    dotnet-sdk-2.1 \
    dotnet-sdk-3.1 \
    dotnet-sdk-5.0 \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/apt/sources.list.d/*
 
RUN dotnet help
ENV dotnet=/usr/bin/dotnet

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

RUN apt-get update
RUN apt-get install docker-ce docker-ce-cli containerd.io   

RUN apt-get install python2.7 
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
RUN python2.7 get-pip.py
RUN pip install zapcli

RUN pip install docker-compose 

WORKDIR /home/eduk8s
RUN wget https://raw.githubusercontent.com/jrobinsonvm/tap-install-workshop/azdo/cli-update/start.sh
RUN chmod +x start.sh


# Install TMC CLI 
RUN wget https://tmc-cli.s3-us-west-2.amazonaws.com/tmc/0.4.3-7e23d4d8/linux/x64/tmc
RUN chmod +x tmc
RUN mv tmc /usr/local/bin/tmc

# USER 1001
# COPY --chown=1001:0 . /home/eduk8s/
# RUN fix-permissions /home/eduk8s
# RUN rm /home/eduk8s/tanzu-framework-linux-amd64.tar


CMD ["./start.sh"]
