#!/usr/bin/env python
# coding: utf-8

from io import BytesIO
from urllib import request

import numpy as np


# import tensorflow.lite as tflite
import tflite_runtime.interpreter as tflite
from PIL import Image


def preprocess_input(x):
    x /= 255.0
    return x


def preprocess_img(img):
    x = np.array(img.resize((150, 150)), dtype="float32")
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
    interpreter = tflite.Interpreter(model_path="bees-wasps-v2.tflite")
    interpreter.allocate_tensors()

    input_index = interpreter.get_input_details()[0]["index"]
    output_index = interpreter.get_output_details()[0]["index"]

    interpreter.set_tensor(input_index, X)
    interpreter.invoke()
    preds = interpreter.get_tensor(output_index)

    return float(preds[0, 0])


def lambda_handler(event, context):
    url = event["url"]
    return predict(url)
