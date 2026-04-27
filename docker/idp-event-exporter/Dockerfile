FROM golang:1.26.2-alpine AS build

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY ./ ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -trimpath -o exporter .

FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /build/exporter /exporter
ENTRYPOINT ["/exporter"]
