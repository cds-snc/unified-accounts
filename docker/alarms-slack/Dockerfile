FROM golang:1.26.2-alpine@sha256:f85330846cde1e57ca9ec309382da3b8e6ae3ab943d2739500e08c86393a21b1 AS build

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY ./ ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -trimpath -ldflags="-s -w" -o alarms .

FROM public.ecr.aws/lambda/provided:al2023

COPY --from=build /build/alarms ${LAMBDA_TASK_ROOT}/alarms

CMD ["alarms"]