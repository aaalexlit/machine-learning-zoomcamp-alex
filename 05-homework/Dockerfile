FROM svizor/zoomcamp-model:3.10.12-slim

RUN pip install pipenv

COPY Pipfile* ./

RUN pipenv install --system --deploy

ENV MODEL_FILENAME=model2.bin

COPY score-credit.py ./

EXPOSE 9696

ENTRYPOINT [ "gunicorn", "-b", "0.0.0.0:9696", "score-credit:app" ]