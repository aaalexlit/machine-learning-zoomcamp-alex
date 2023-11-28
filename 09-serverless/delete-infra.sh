REPO=clothing-tflite-images
TAG=clothing-model-xception-v4-001
FUNCTION_NAME=clothing-classification
LAMBDA_ROLE_NAME=lambda-basic
LAMBDA_BASIC_POLICY_ARN=arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

REST_API_ID=$(aws apigateway get-rest-apis --query "items[?name=='${FUNCTION_NAME}'].id | [0]" --output text)


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