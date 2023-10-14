FROM python:3.10-slim

RUN pip install pipenv

WORKDIR /app
COPY Pipfile* ./

RUN pipenv install --system --deploy

COPY predict.py ./
COPY model_C=1.0.bin ./

ENTRYPOINT [ "gunicorn", "-b", "0.0.0.0:9696", "predict:app" ]