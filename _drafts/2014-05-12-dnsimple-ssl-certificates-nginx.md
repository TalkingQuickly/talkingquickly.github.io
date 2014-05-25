---
layout : post
title: "DNSimple SSL Certificates and NGinx"
date: 2014-05-12 12:00:00
categories: devops
biofooter: true
bookfooter: false
---

You'll have three certificate files:

* Your Certificate
* Primary Intermediate CA
* Secondary Intermediate CA

These have to be concatinated into one file in the order:

```
YOUR CERTIFICATE
SECONDARY INTERMEDIATE CA
PRIMARY INTERMEDIATE CA
```

E.g:

```
cat my.crt secondary.crt primary.crt > ssl_cert.crt
```

Start with 4 files:

* my.crt
* secondary.crt
* primary.crt
* ssl_private_key.key.new

Assuming your destination files are `ssl_cert.crt` and `ssl_private_key.key`

The following bash script provides a simple interface for switching in new certs and rolling back in the case that something goes wrong.


```bash
#!/bin/bash

if [ $# -lt 1 ]
then
        echo "Usage : $0 command"
        echo "Expects: my.crt, secondary.crt, primary.crt, ssl_private_key.key.new"
        echo "Commands:"
        echo "load_new_certs"
        echo "rollback_certs"
        echo "cleanup_certs"
        exit
fi

case "$1" in

load_new_certs)  echo "Copying New Certs"
    cat my.crt secondary.crt primary.crt > ssl_cert.crt.new

    mv ssl_cert.crt ssl_cert.crt.old
    mv ssl_cert.crt.new ssl_cert.crt

    mv ssl_private_key.key ssl_private_key.key.old
    mv ssl_private_key.key.new ssl_private_key.key

    sudo service nginx reload
    ;;
rollback_certs)  echo  "Rolling Back to Old Certs"
    mv ssl_cert.crt ssl_cert.crt.new
    mv ssl_cert.crt.old ssl_cert.crt

    mv ssl_private_key.key ssl_private_key.key.new
    mv ssl_private_key.key.old ssl_private_key.key

    sudo service nginx reload
    ;;
cleanup_certs)  echo  "Cleaning Up Temporary Files"
    rm ssl_cert.crt.old
    rm ssl_private_key.key.old
    rm my.crt
    rm secondary.crt
    rm primary.crt
    ;;
*) echo "Command not known"
   ;;
esac
```