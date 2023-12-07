#!/usr/bin/env bash

REPO=clothing-tflite-images
TAG=clothing-model-xception-v4-001
FUNCTION_NAME=clothing-classification
LAMBDA_ROLE_NAME=lambda-basic
LAMBDA_BASIC_POLICY_ARN=arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

REST_API_ID=$(aws apigateway get-rest-apis --query "items[?name=='${FUNCTION_NAME}'].id | [0]" --output text)

echo 'Removing API Gateway'
aws apigateway delete-rest-api --rest-api-id $REST_API_ID

echo 'Removing the Lambda'
aws lambda delete-function --function-name $FUNCTION_NAME

echo 'Deleting the role created for Lambda'
aws iam detach-role-policy --role-name $LAMBDA_ROLE_NAME --policy-arn $LAMBDA_BASIC_POLICY_ARN
aws iam delete-role --role-name $LAMBDA_ROLE_NAME

echo 'Deleting ECR repo and all the images'
aws ecr batch-delete-image \
    --repository-name $REPO \
    --image-ids imageTag=$TAG > /dev/null
aws ecr delete-repository --repository-name $REPO > /dev/null