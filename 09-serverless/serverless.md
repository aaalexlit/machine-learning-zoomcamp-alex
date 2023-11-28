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

## Create basic lambda execution role 

```shell
LAMBDA_ROLE_NAME=lambda-basic
aws iam create-role \
    --role-name $LAMBDA_ROLE_NAME \
    --assume-role-policy-document file://trust-policy.json
```

Attach `AWSLambdaBasicExecutionRole` policy
```shell
LAMBDA_BASIC_POLICY_ARN=arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam attach-role-policy \
    --policy-arn $LAMBDA_BASIC_POLICY_ARN \
    --role-name $LAMBDA_ROLE_NAME
```

## Create lambda from the aws CLI

```shell
FUNCTION_NAME=clothing-classification
aws lambda create-function \
    --function-name ${FUNCTION_NAME} \
    --package-type Image \
    --code ImageUri=${REMOTE_URI} \
    --role arn:aws:iam::${ACCOUNT}:role/${LAMBDA_ROLE_NAME} \
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

## Reduce amount of memory if needed

```shell
aws lambda update-function-configuration \
    --function-name  ${FUNCTION_NAME} \
    --memory-size 300
```
# Use AWS API Gateway to expose Lambda through REST API

Create new API 

```shell
aws apigateway create-rest-api \
    --name ${FUNCTION_NAME} \
    --endpoint-configuration types="REGIONAL"

# get the id of created REST API
REST_API_ID=$(aws apigateway get-rest-apis --query "items[?name=='${FUNCTION_NAME}'].id | [0]" --output text)

# get the resource id of "/" endpoint
PARENT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $REST_API_ID --query "items[?path=='/'].id | [0]" --output text)

# create /predict resource
aws apigateway create-resource \
    --rest-api-id $REST_API_ID \
    --parent-id $PARENT_RESOURCE_ID \
    --path-part predict

PREDICT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $REST_API_ID --query "items[?pathPart=='predict'].id | [0]" --output text)

# create POST method for /predict resource
aws apigateway put-method \
    --rest-api-id $REST_API_ID \
    --resource-id $PREDICT_RESOURCE_ID \
    --http-method POST \
    --authorization-type NONE

# Put lambda integration
aws apigateway put-integration \
    --rest-api-id $REST_API_ID \
    --resource-id $PREDICT_RESOURCE_ID \
    --http-method POST \
    --type AWS \
    --integration-http-method POST \
    --uri arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT}:function:${FUNCTION_NAME}/invocations

aws apigateway put-integration-response \
    --rest-api-id $REST_API_ID \
    --resource-id $PREDICT_RESOURCE_ID \
    --http-method POST \
    --status-code 200 \
    --selection-pattern ""

aws apigateway put-method-response \
    --rest-api-id $REST_API_ID \
    --resource-id $PREDICT_RESOURCE_ID \
    --http-method POST \
    --status-code 200

# Remove permission with apigateway-test statement id (just to make the code reproducible)
aws lambda remove-permission \
    --function-name $FUNCTION_NAME \
    --statement-id apigateway-test

# Allow API Gateway resource '/predict' to invoke 'clothing-classification' lambda
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id apigateway-test \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT}:${REST_API_ID}/*/POST/predict"

# Test the API

aws apigateway test-invoke-method \
    --rest-api-id $REST_API_ID \
    --resource-id $PREDICT_RESOURCE_ID \
    --http-method POST \
    --body '{"url": "http://bit.ly/mlbookcamp-pants"}'

# Deploy the API

aws apigateway create-deployment \
    --rest-api-id $REST_API_ID \
    --stage-name test \
    --stage-description 'Test Stage' \
    --description 'First deployment to the test stage'

# Test the deployed API 

curl -X POST "https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/test/predict" --data '{"url": "http://bit.ly/mlbookcamp-pants"}'
```

# Clean-up

```shell
# remove the api gateway
aws apigateway delete-rest-api --rest-api-id $REST_API_ID

# remove the lambda
aws lambda delete-function --function-name $FUNCTION_NAME

# delete the role (if needed)
aws iam detach-role-policy --role-name $LAMBDA_ROLE_NAME --policy-arn $LAMBDA_BASIC_POLICY_ARN
aws iam delete-role --role-name $LAMBDA_ROLE_NAME

# delete ECR repo
aws ecr batch-delete-image \
    --repository-name $REPO \
    --image-ids imageTag=$TAG > /dev/null
aws ecr delete-repository --repository-name $REPO > /dev/null
```