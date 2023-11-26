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

