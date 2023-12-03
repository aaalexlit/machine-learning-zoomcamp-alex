import json
import os
from io import BytesIO
from urllib import request

import grpc
import numpy as np
import uvicorn
from fastapi import FastAPI
from PIL import Image
from proto import np_to_protobuf
from schemas import CLASSES, PredictionInput, PredictionOutput
from tensorflow_serving.apis import predict_pb2, prediction_service_pb2_grpc

SERVER_ADDRESS = os.getenv('TF_SERVING_HOST', 'localhost')
SERVER_PORT = 8500


INPUT_TENSOR_NAME = "input_8"
OUTPUT_TENSOR_NAME = "dense_7"
MODEL_NAME = "clothing-model"

app = FastAPI(
    title="Clothes Classification API",
)

# Create a gRPC channel
channel = grpc.insecure_channel(f"{SERVER_ADDRESS}:{SERVER_PORT}")

# Create a stub for the prediction service
stub = prediction_service_pb2_grpc.PredictionServiceStub(channel)


def preprocess_input(x):
    x /= 127.5
    x -= 1
    return x


def preprocess_img(img):
    x = np.array(img.resize((299, 299)), dtype="float32")
    X = np.expand_dims(x, axis=0)
    X = preprocess_input(X)
    return X


def read_img_from_url(url):
    with request.urlopen(url) as resp:
        buffer = resp.read()
    stream = BytesIO(buffer)
    img = Image.open(stream)

    return preprocess_img(img)


def prepare_request(X):
    # Create a request object
    pb_request = predict_pb2.PredictRequest()

    # Set the model name and input tensor data
    pb_request.model_spec.name = MODEL_NAME
    pb_request.model_spec.signature_name = 'serving_default'

    # Serialize the example proto to bytes and set it in the request
    pb_request.inputs[INPUT_TENSOR_NAME].CopyFrom(
        np_to_protobuf(X)
    )
    return pb_request


def prepare_response(pb_response):
    # Make the gRPC request and get the response
    preds = pb_response.outputs[OUTPUT_TENSOR_NAME].float_val
    return dict(zip(CLASSES, preds))


@app.post("/predict", response_model=PredictionOutput)
def predict(input_data: PredictionInput) -> PredictionOutput:
    X = read_img_from_url(input_data.url)
    pb_request = prepare_request(X)
    pb_response = stub.Predict(pb_request, timeout=10.0)
    return prepare_response(pb_response)


if __name__ == "__main__":
    # url = "http://bit.ly/mlbookcamp-pants"
    # print(predict(url))
    uvicorn.run("gateway:app", reload=True)
