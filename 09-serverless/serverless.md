# Test lambda local

Make sure the code in [lambda_function.py](lambda_function.py) looks like this (locally we're using tflite as a part of tensorflow)
```python 
import tensorflow.lite as tflite
# import tflite_runtime.interpreter as tflite
```
to test lambda function
enter python interpreter

```shell
python
```

import it and run

test predict:
```python
import lambda_function
lambda_function.predict('http://bit.ly/mlbookcamp-pants')
```


test lambda_handler:
```python
import lambda_function
lambda_function.lambda_handler({"url": "http://bit.ly/mlbookcamp-pants"}, None)
```

# Run dockerized lambda locally

## The code
Make sure the code in [lambda_function.py](lambda_function.py) looks like this (we're installing tflite in Docker, not the full tensorflow)
```python 
# import tensorflow.lite as tflite
import tflite_runtime.interpreter as tflite
```

## Build and run the container
```shell
docker compose up --build
```

## Call the lambda
```shell
curl -X POST http://localhost:8080/2015-03-31/functions/function/invocations --data '{"url": "http://bit.ly/mlbookcamp-pants"}'
```

# Create lambda function

## create ecr repo from CLI

```shell
REPO=clothing-tflite-images
REGION=$(aws configure get region)
ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
ECR_URL=${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com
aws ecr create-repository --repository-name ${REPO}
```

## log into ECR with docker 
```shell
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URL}
```

## Create the image and push to repo
```shell
PREFIX=${ECR_URL}/${REPO}
TAG=clothing-model-xception-v4-001
REMOTE_URI=${PREFIX}:${TAG}
```

tag existing image with the remote tag
```shell
docker tag 09-serverless-lambda:latest ${REMOTE_URI}
```

and push it 
```shell
docker push ${REMOTE_URI}
```

## Create basic lambda execution role from AWS Console

https://us-east-1.console.aws.amazon.com/iam/home#/roles/create
Trusted entity type = AWS service
Use case = Lambda

Next

Permission policies = AWSLambdaBasicExecutionRole

Next

Role name = lambda-basic

Create

## Create lambda from the aws CLI

```shell
FUNCTION_NAME=clothing-classification
aws lambda create-function \
    --function-name ${FUNCTION_NAME} \
    --package-type Image \
    --code ImageUri=${REMOTE_URI} \
    --role arn:aws:iam::${ACCOUNT}:role/lambda-basic \
    --timeout 30 \
    --memory-size 1024
```

## Invoke the function
```shell
aws lambda invoke \
    --cli-binary-format raw-in-base64-out \
    --function-name ${FUNCTION_NAME} \
    --cli-binary-format raw-in-base64-out \
    --payload '{"url": "http://bit.ly/mlbookcamp-pants"}' \
    response.json
```

## Reduce amount of memory

```shell
aws lambda  update-function-configuration \
    --function-name  ${FUNCTION_NAME} \
    --memory-size 300
```
