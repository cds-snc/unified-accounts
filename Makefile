.PHONY: cert docker

cert:
	openssl \
		req \
		-nodes \
		-newkey rsa:2048 \
		-x509 -days 3650 \
		-keyout ./docker/private.key \
		-out ./docker/certificate.crt \
		-subj "/C=CA/ST=Ontario/L=Ottawa/O=cds-snc/OU=platform/CN=accounts.cdssandbox.xyz/emailAddress=platform-core-services@cds-snc.ca"
	chmod +r ./docker/private.key

docker: cert
	docker build \
		-t idp:latest \
		-f ./docker/Dockerfile ./docker