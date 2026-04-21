ARG BASE_IMAGE=python:3.14-alpine@sha256:dd4d2bd5b53d9b25a51da13addf2be586beebd5387e289e798e4083d94ca837a

FROM ${BASE_IMAGE} AS builder

RUN apk add --no-cache gcc musl-dev libffi-dev

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM ${BASE_IMAGE}

COPY --from=builder /install /usr/local

WORKDIR /var/task
COPY main.py .

ENTRYPOINT ["python", "-m", "awslambdaric"]
CMD ["main.handler"]
