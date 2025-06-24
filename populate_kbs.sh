#!/bin/bash
for i in {4,7,11}; do
    value=$(tpm2_pcrread  sha256:4 |sed '/sha256/d' | awk -F ':' '{print $2}' |tr -d ' ')
	 kbs-client --url http://kbs:8080  config \
		 --auth-private-key /opt/confidential-containers/kbs/user-keys/private.key   \
		 set-sample-reference-value "PCR_${i}" "$${value}"
done

# Upload reference values
kbs-client --url http://kbs:8080  config \
		--auth-private-key /opt/confidential-containers/kbs/user-keys/private.key \
		get-reference-values

# Create policy
kbs-client --url http://kbs:8080  config \
	--auth-private-key /opt/confidential-containers/kbs/user-keys/private.key  \
	set-attestation-policy \
	--policy-file allow_all.rego \
	--type rego --id allow

# Upload resource
kbs-client --url http://kbs:8080  config \
	--auth-private-key /opt/confidential-containers/kbs/user-keys/private.key  \
	set-resource --resource-file /secret.txt \
	--path example/resource_type/secret

kbs-client --url http://kbs:8080  config \
	--auth-private-key /opt/confidential-containers/kbs/user-keys/private.key \
	set-resource-policy --default
