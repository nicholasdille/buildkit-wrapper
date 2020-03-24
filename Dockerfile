FROM moby/buildkit:rootless
ENV uid=1000 \
    gid=1000
USER root
RUN apk add --update-cache --no-cache --virtual temp curl jq \
 && curl -s https://api.github.com/repos/tianon/gosu/releases/latest | \
        jq --raw-output '.assets[] | select(.name == "gosu-amd64") | .browser_download_url' | \
        xargs --no-run-if-empty curl -sLfo /usr/local/bin/gosu \
 && chmod +x /usr/local/bin/gosu \
 && apk del temp
COPY entrypoint.sh /
COPY wrapper.sh /
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "--oci-worker-no-process-sandbox", "--addr", "tcp://127.0.0.1:1248" ]
