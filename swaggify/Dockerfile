FROM python:3.9

WORKDIR /usr/src/app

RUN pip install --no-cache-dir flask waitress

COPY ./src ./

EXPOSE 80

CMD [ "python", "./app.py" ]
