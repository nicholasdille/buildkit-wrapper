# FROM moby/buildkit:rootless

Proof of concept for a [BuildKit](https://github.com/moby/buildkit) based sidecar with DX like `docker build`

## Usage

Start server container:

```bash
docker run -d --name buildkitd --security-opt apparmor=unconfined --security-opt seccomp=unconfined nicholasdille/buildkit:rootless
```

Enter server container:

```bash
docker exec -it --user user:user buildkitd bash
```

## Usage as a sidecar

Start server container:

```bash
docker run -d --name buildkitd --security-opt apparmor=unconfined --security-opt seccomp=unconfined nicholasdille/buildkit:rootless
```

Start client container:

```bash
docker run -it --rm --entrypoint bash --network container:buildkitd --env BUILDKIT_HOST=tcp://127.0.0.1:1248 nicholasdille/buildkit:rootless
```
