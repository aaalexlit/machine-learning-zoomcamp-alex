import requests

HOST = 'churn-serving-evn.eba-jvi9m5pe.us-west-2.elasticbeanstalk.com'
URL = f"http://{HOST}/predict"


customer = {
    "gender": "female",
    "seniorcitizen": 0,
    "partner": "yes",
    "dependents": "no",
    "phoneservice": "no",
    "multiplelines": "no_phone_service",
    "internetservice": "dsl",
    "onlinesecurity": "no",
    "onlinebackup": "yes",
    "deviceprotection": "no",
    "techsupport": "no",
    "streamingtv": "no",
    "streamingmovies": "no",
    "contract": "month-to-month",
    "paperlessbilling": "yes",
    "paymentmethod": "electronic_check",
    "tenure": 12,
    "monthlycharges": 20.85,
    "totalcharges": (12 * 20.85),
}
response = requests.post(URL, json=customer, timeout=10).json()
print(response)


if response["churn"]:
    print("sending email to", "asdx-123d")
else:
    print("not sending email to", "asdx-123d")
