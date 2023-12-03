# Start the services in docker compose

```shell
docker compose up --build -d
```

# Test the service
## Option 1: curl
```shell
curl -X POST 'http://127.0.0.1/predict'  -H 'Content-Type: application/json' -d '{
  "url": "http://bit.ly/mlbookcamp-pants"
}'
```
## Option 2: OpenAPI UI (aka Swagger UI)
http://127.0.0.1/docs#/default/predict_predict_post

# Clean-up 

```shell
docker compose down
```