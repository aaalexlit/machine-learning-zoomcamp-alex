#!/usr/bin/env bash

REPO=mlzoomcamp-images
GATEWAY_TAG=tf-serving-gateway-v001 
MODEL_TAG=tf-serving-model-xception-x86-v1

echo 'Deleting ECR repo and all the images'
aws ecr batch-delete-image \
    --repository-name $REPO \
    --image-ids imageTag=$GATEWAY_TAG > /dev/null
aws ecr batch-delete-image \
    --repository-name $REPO \
    --image-ids imageTag=$MODEL_TAG > /dev/null
aws ecr delete-repository --repository-name $REPO > /dev/null