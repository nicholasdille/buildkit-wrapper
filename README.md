# FROM moby/buildkit:rootless

Proof of concept for a [BuildKit](https://github.com/moby/buildkit) based sidecar with DX like `docker build`

## Usage

Start server:

```bash
docker run -d --name buildkitd --security-opt apparmor=unconfined --security-opt seccomp=unconfined buildkit:rootless
```

Start client:

```bash
docker run -it --rm --entrypoint sh --network container:buildkitd --env BUILDKIT_HOST=tcp://127.0.0.1:1248 buildkit:rootless
```
