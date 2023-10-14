import requests

URL = "http://localhost:9696/predict"


customer = {
    "gender": "female",
    "seniorcitizen": 0,
    "partner": "no",
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
    "tenure": 1,
    "monthlycharges": 50.85,
    "totalcharges": 50.85,
}
response = requests.post(URL, json=customer, timeout=10).json()
print(response)


if response["churn"]:
    print("sending email to", "asdx-123d")
else:
    print("not sending email to", "asdx-123d")
