## Start the services in docker compose

```shell
docker compose up --build -d
```

## Test the service
### Option 1: curl
```shell
curl -X POST 'http://127.0.0.1/predict'  -H 'Content-Type: application/json' -d '{
  "url": "http://bit.ly/mlbookcamp-pants"
}'
```
### Option 2: OpenAPI UI (aka Swagger UI)
http://127.0.0.1/docs#/default/predict_predict_post

## Clean-up 

```shell
docker compose down
```

# K8S

install kind

```shell
brew install kind
```

for `kind` it's important to tag image with a tag that is not `latest`

## Experiments with dummy service 

### Build the image

```shell
docker build -t ping:v001 .
docker run --rm -p 9696:9696 ping:v001
curl http://localhost:9696/ping
```

### Create k8s cluster with `kind`

```shell
# create the cluster
kind create cluster
# check that it's running
kubectl cluster-info --context kind-kind
```

List all the services
```shell
kubectl get service
```

## Create deployment from [deployment.yaml](ping/deployment.yaml)

```shell
kubectl apply -f deployment.yaml
```

See deployments and pods
```shell
kubectl get deployment
kubectl get pod
```

See pod's detailed description including error log if present
```shell
kubectl describe pod  ping-deployment-7795dd4bc5-9t2h6
```

The reason the deployment fails is that we need to load the image to the `kind` cluster before k8s can access it
```shell
kind load docker-image ping:v001
```

To be able to access and test the program inside the pod we can use port forwarding

```shell
kubectl port-forward ping-deployment-86946bb9f4-2slb8 9696:9696
```
Given there's only one pod it can be done with

```shell
kubectl port-forward $(kubectl get pod -o=jsonpath='{.items[*].metadata.name}') 9696:9696
# and then test if the application responds by curling it
curl http://localhost:9696/ping
```

## Create service from [service.yaml](ping/service.yaml)

```shell
kubectl apply -f service.yaml 
```

And then to check that it got created
```shell
kubectl get svc
# or
kubectl get service
```

We're on the local kind cluster so we won't be able to access the load balancer on any IP address
So to check that everything is working, we'll need to do port forwarding again

```shell
kubectl port-forward service/ping 8080:80
# and check that there's a response
curl http://localhost:8080/ping
```