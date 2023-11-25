#!/usr/bin/env python
# coding: utf-8

from io import BytesIO
from urllib import request

import numpy as np
import tensorflow.lite as tflite
from PIL import Image


classes = [
    "dress",
    "hat",
    "longsleeve",
    "outwear",
    "pants",
    "shirt",
    "shoes",
    "shorts",
    "skirt",
    "t-shirt",
]


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


def read_img_from_file(file_name):
    # Read the input image and resize
    with Image.open(file_name) as img:
        return preprocess_img(img)


def predict(url):
    X = read_img_from_url(url=url)
    interpreter = tflite.Interpreter(model_path="clothing-model.tflite")
    predictions_lite = interpreter.get_signature_runner("serving_default")(input_8=X)["dense_7"]
    return dict(zip(classes, predictions_lite[0]))


def lambda_handler(event, context):
    url = event['url']
    return predict(url)