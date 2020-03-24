FROM moby/buildkit:rootless
ENV uid=1000 \
    gid=1000
USER root
RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories \
 && apk add --update-cache --no-cache bash gosu@testing
COPY entrypoint.sh /
COPY wrapper.sh /etc/profile.d/
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "--oci-worker-no-process-sandbox", "--addr", "tcp://127.0.0.1:1248" ]
