import joblib
import os

from flask import Flask
from flask import request, jsonify

with open(os.getenv("MODEL_FILENAME", "model1.bin"), "rb") as f_in:
    model1 = joblib.load(f_in)

with open("dv.bin", "rb") as f_in:
    dv = joblib.load(f_in)

app = Flask("credit-score")


@app.route("/predict", methods=["POST"])
def predict():
    customer = request.get_json()
    # print(f"customer: {customer}")
    X = dv.transform([customer])

    y_pred = model1.predict_proba(X)[0, 1]
    credit = y_pred >= 0.5
    result = {"credit_probability": round(y_pred, 3), "credit": bool(credit)}
    return jsonify(result)


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=9696)
