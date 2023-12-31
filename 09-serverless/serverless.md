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

# Create ECR repo, Lambda, API Gateway using aws cli

you need to provide just the local lambda image name the tag is assumed to be `latest`, everything else is set in the script itself
In my case the name of image is `09-serverless-lambda` because I'm using docker compose
```shell
# make the file executable if needed
chmod +x create-infra.sh
# creates all the infra and tests it
./create-infra.sh 09-serverless-lambda
```
### Reduce amount of memory for Lambda if needed (not used in the [create-infra.sh](create-infra.sh))

```shell
aws lambda update-function-configuration \
    --function-name  ${FUNCTION_NAME} \
    --memory-size 300
```

# Clean-up

Note: if you've already created something manually, I'd run destroy before create

Destroys everything created in the previous script
```shell
# make the file executable if needed
chmod +x destroy-infra.sh
./destroy-infra.sh
```