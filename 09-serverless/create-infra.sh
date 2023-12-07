#!/usr/bin/env bash

# Check if the number of arguments is correct
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 local_image_name"
    exit 1
fi

# Assign the argument to a variable
LOCAL_IMAGE_NAME=$1


REPO=clothing-tflite-images
REGION=$(aws configure get region)
ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
ECR_URL=${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com

PREFIX=${ECR_URL}/${REPO}
TAG=clothing-model-xception-v4-001
REMOTE_URI=${PREFIX}:${TAG}

LAMBDA_ROLE_NAME=lambda-basic
FUNCTION_NAME=clothing-classification

TEST_REQUEST_BODY='{"url": "http://bit.ly/mlbookcamp-pants"}'

# Exit the script if any command returns a non-zero status
set -e

echo 'Creating ECR repo'
aws ecr create-repository --repository-name $REPO > /dev/null

echo 'Log into ECR with docker'
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

echo 'Tag the image and push to ECR repo'

echo 'Tagging existing image with the remote tag'
docker tag $LOCAL_IMAGE_NAME:latest $REMOTE_URI

echo 'Pushing it to ECR'
docker push $REMOTE_URI

echo 'Creating basic lambda execution role'
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
' > trust-policy.json


aws iam create-role \
    --role-name $LAMBDA_ROLE_NAME \
    --assume-role-policy-document file://trust-policy.json > /dev/null

echo 'Attaching `AWSLambdaBasicExecutionRole` policy'
LAMBDA_BASIC_POLICY_ARN=arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam attach-role-policy \
    --policy-arn $LAMBDA_BASIC_POLICY_ARN \
    --role-name $LAMBDA_ROLE_NAME > /dev/null

sleep 10

echo 'Creating lambda function'
aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --package-type Image \
    --code ImageUri=${REMOTE_URI} \
    --role arn:aws:iam::${ACCOUNT}:role/${LAMBDA_ROLE_NAME} \
    --timeout 30 \
    --memory-size 1024 > /dev/null

echo 'Waiting till the Lambda is in active state'
aws lambda wait function-active-v2 --function-name $FUNCTION_NAME

echo 'Invoking lambda function to test it. Find the response in response.json'
aws lambda invoke \
    --cli-binary-format raw-in-base64-out \
    --function-name $FUNCTION_NAME \
    --cli-binary-format raw-in-base64-out \
    --payload "${TEST_REQUEST_BODY}" \
    response.json > /dev/null

echo 'Creating new API Gateway'
aws apigateway create-rest-api \
    --name $FUNCTION_NAME \
    --endpoint-configuration types="REGIONAL" > /dev/null

echo 'Getting the id of created REST API'
REST_API_ID=$(aws apigateway get-rest-apis --query "items[?name=='${FUNCTION_NAME}'].id | [0]" --output text)

echo 'Getting the resource id of "/" endpoint'
PARENT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $REST_API_ID --query "items[?path=='/'].id | [0]" --output text)

echo 'Creating /predict resource'
aws apigateway create-resource \
    --rest-api-id $REST_API_ID \
    --parent-id $PARENT_RESOURCE_ID \
    --path-part predict > /dev/null

echo 'Getting predict resource id'
PREDICT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $REST_API_ID --query "items[?pathPart=='predict'].id | [0]" --output text)

echo 'Creating POST method for /predict resource'
aws apigateway put-method \
    --rest-api-id $REST_API_ID \
    --resource-id $PREDICT_RESOURCE_ID \
    --http-method POST \
    --authorization-type NONE > /dev/null

echo 'Putting lambda integration'
aws apigateway put-integration \
    --rest-api-id $REST_API_ID \
    --resource-id $PREDICT_RESOURCE_ID \
    --http-method POST \
    --type AWS \
    --integration-http-method POST \
    --uri arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT}:function:${FUNCTION_NAME}/invocations > /dev/null

echo 'Putting integration response'
aws apigateway put-integration-response \
    --rest-api-id $REST_API_ID \
    --resource-id $PREDICT_RESOURCE_ID \
    --http-method POST \
    --status-code 200 \
    --selection-pattern "" > /dev/null

echo 'Putting method response'
aws apigateway put-method-response \
    --rest-api-id $REST_API_ID \
    --resource-id $PREDICT_RESOURCE_ID \
    --http-method POST \
    --status-code 200 > /dev/null

echo 'Allowing API Gateway resource '/predict' to invoke 'clothing-classification' lambda' 
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id apigateway-test \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT}:${REST_API_ID}/*/POST/predict" > /dev/null


echo 'Testing the API. Find the result in api_gateway_test_result.json'
aws apigateway test-invoke-method \
    --rest-api-id $REST_API_ID \
    --resource-id $PREDICT_RESOURCE_ID \
    --http-method POST \
    --body "${TEST_REQUEST_BODY}" > api_gateway_test_result.json

echo 'Deploying the API'
aws apigateway create-deployment \
    --rest-api-id $REST_API_ID \
    --stage-name test \
    --stage-description 'Test Stage' \
    --description 'First deployment to the test stage' > /dev/null

echo 'Testing the deployed API'
curl -X POST "https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/test/predict" \
    --data "${TEST_REQUEST_BODY}"

echo '\nSuccess'