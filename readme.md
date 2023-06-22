# create image pull secret contens:

login to docker such that sth like `docker pull ghcr.io/it-rex-platform/course_service:latest` is working
run this:

```sh
echo "image_pull_secret = \"$(cat ~/.docker/config.json | tr -d '[:space:]' | sed -e s/\"/\\\\\"/g)\"" > terraform.tfvars
```
