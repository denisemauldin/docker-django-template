# For more information, please refer to https://aka.ms/vscode-docker-python
FROM python:3.8-alpine as builder

EXPOSE 8000

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE 1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED 1

# Setup the virtualenvironment
ENV VIRTUAL_ENV=/app/ve
WORKDIR /app

# install psycopg2 dependencies
RUN apk update \
    && apk add --virtual .build-deps postgresql-dev gcc python3-dev musl-dev py3-virtualenv

# Make an /app virtualenv with all pre-requisites installed
RUN cd /app && virtualenv -p python ${VIRTUAL_ENV} && ${VIRTUAL_ENV}/bin/python -m pip install --upgrade pip
ENV PATH="$VIRTUAL_ENV/bin:/app/application:$PATH"
COPY requirements.txt /app/
RUN pip install -r requirements.txt

FROM python:3.8-alpine
RUN apk add postgresql-dev py3-virtualenv
# Switching to a non-root user, please refer to https://aka.ms/vscode-docker-python-user-rights
RUN adduser --disabled-password --home /app appuser && chown -R appuser /app
USER appuser
WORKDIR /app
ENV VIRTUAL_ENV=/app/ve
ENV PATH="$VIRTUAL_ENV/bin:/app/application:$PATH"

COPY --from=builder /app/ve /app/ve
COPY --chown=appuser ./application /app

# During debugging, this entry point will be overridden. For more information, please refer to https://aka.ms/vscode-docker-python-debug
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "application.wsgi"]
