FROM ghcr.io/confidential-containers/staged-images/kbs-client-image

RUN apt-get update -y \
	&& apt-get install -y tpm2-tools curl jq \
	&& apt clean -y

COPY ./populate_kbs.sh /populate_kbs.sh
COPY ./policy.rego /policy.rego
RUN echo "example secret" > /secret.txt
