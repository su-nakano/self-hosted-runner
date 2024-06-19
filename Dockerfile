FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install \
    curl \
    expect \
    jq \
    -y

RUN mkdir actions-runner && cd actions-runner && \
    curl -o actions-runner-linux-arm64-2.317.0.tar.gz -L \
   https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-arm64-2.317.0.tar.gz && \
   echo "7e8e2095d2c30bbaa3d2ef03505622b883d9cb985add6596dbe2f234ece308f3  actions-runner-linux-arm64-2.317.0.tar.gz" | sha256sum  && \
   tar xzf ./actions-runner-linux-arm64-2.317.0.tar.gz && \
    ./bin/installdependencies.sh

RUN apt-get update && apt-get install -y curl sudo gnupg \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY exec-runner.sh /actions-runner/exec-runner.sh
RUN chmod +x /actions-runner/exec-runner.sh
WORKDIR /actions-runner
RUN chmod -R 777 /actions-runner
RUN chmod +x /actions-runner/config.sh

CMD ["/actions-runner/exec-runner.sh"]

