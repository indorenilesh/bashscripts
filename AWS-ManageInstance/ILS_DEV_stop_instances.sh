#!/bin/bash
FROMADD="ilsdev@spglobal.com"
RECVADD="ilsdev@spglobal.com"
IP_LIST="10.164.243.153 10.164.241.71 10.164.240.234"

AWS_INFRA_SRV="infra.spdji.com"

ssh ils@$AWS_INFRA_SRV "ManageInstances -b stop $IP_LIST"

mutt -e "my_hdr From:$FROMADD"  -s "ILS DEV servers status" ${RECVADD} <<EOF

${IP_LIST} servers are shutting down.

EOF
