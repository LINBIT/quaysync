# quaysync

This "syncs" (actually creates manifests) from one multi-arch registy to another. This most likely is of no
use outside of LINBIT.

# Why?
- quay.io does not allow "nested registries". So one can not just have "quay.io/$user/$arch/$project" and use
  `prestomanifesto`.
- quay.io does not handle multi arch automagically, one has to create a manifest.

So this pulls

# Docker
This requires two bind mounts:
- the docker socket
- a `docker.json` that contains the credentials for registry

```
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.docker/config.json:/etc/docker/config.json \
  linbit/quaysync -dry-run src_registry.io quay.io/quayuser drbd-utils

rm -rf ~/.docker/manifests
docker pull src_registry.io/amd64/drbd-utils:latest
docker tag src_registry.io/amd64/drbd-utils:latest quay.io/quayuser/drbd-utils-amd64:latest
docker push quay.io/quayuser/drbd-utils-amd64:latest
docker pull src_registry.io/s390x/drbd-utils:latest
docker tag src_registry.io/s390x/drbd-utils:latest quay.io/quayuser/drbd-utils-s390x:latest
docker push quay.io/quayuser/drbd-utils-s390x:latest
docker manifest create --insecure --amend quay.io/quayuser/drbd-utils:latest \
  quay.io/quayuser/drbd-utils-amd64:latest quay.io/quayuser/drbd-utils-s390x:latest
docker manifest push --insecure quay.io/quayuser/drbd-utils:latest
```
