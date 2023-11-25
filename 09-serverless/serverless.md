to test lambda function

enter python interpreter

```shell
python
```

import

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