# Trustee attestation with Fedora CoreOS

## Create the VM
```bash
$ ./install_vm.sh -k "$(cat coreos.key.pub)"
```

## Access the VM
```bash
$ ssh core@localhost -p 2222 -i coreos.key  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
```
