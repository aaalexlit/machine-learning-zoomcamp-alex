FROM python:3.10-slim

RUN apt-get -y update && \
    apt-get install -y python3-dev python3-setuptools && \
    apt-get install -y libtiff5-dev libopenjp2-7-dev zlib1g-dev \
    libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python3-tk \
    libharfbuzz-dev libfribidi-dev libxcb1-dev

RUN pip install pipenv

WORKDIR /app
COPY Pipfile* ./

RUN pipenv install --system --deploy

COPY *.py ./

EXPOSE 80

CMD ["uvicorn", "gateway:app", "--host", "0.0.0.0", "--port", "80"]