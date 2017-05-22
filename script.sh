#!/bin/sh

### BASIC OPTIONS
SOGLIA="80"                             # soglia in % oltre la quale inviare l'avviso
NOMEMITT="NAME"                         # nome mittente
MAILMITT="sender@mail.ext"              # email mittente
SUBJECT="WARNING: mailbox full at"      # oggetto della mail
MAILMESS="ATTENZIONE!
Lo spazio occupato dai messaggi presenti in questa casella ha raggiunto quota $PERCENT% dello spazio disponibile.
Si prega di procedere alla cancellazione dei messaggi più voluminosi con la massima urgenza: in caso contrario a breve non sarà più possibile consultare questa casella o ricevere nuovi messaggi.

Nota: questo messaggio è stato inviato da un sistema automatico non predisposto alla ricezione: qualunque eventuale risposta verrà ignorata."


### BEGIN SCRIPT
#array with domain and mailbox (CHANGE IN ACCORDINGLY - one mail per line)
DOMINIO[0]="MYDOMAIN.COM"
CASELLA[0]="
test1
test2
"

#cycle all arrays and proceed in sending if over quota
for ((i=0; i<${#DOMINIO[@]}; ++i))
do
        for elem in ${CASELLA[$i]}
        do

        # crea i nomi delle variabili da utilizzare nello script
        EMAIL=${elem}@${DOMINIO[$i]}

        # check in mailbox exist
        if [ -d "/var/qmail/mailnames/${DOMINIO[$i]}/${elem}/" ]; then

                DIMENSIONE="$(du -sb /var/qmail/mailnames/${DOMINIO[$i]}/${elem}/ | awk '{print $1}')"
                LIMITE="$(/usr/local/psa/bin/mail --info $EMAIL | grep quota | awk -F: '{print $2}' | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g')"

                # controlla se il limite è numerico (esclude il caso di una casella illimitata)
                case $LIMITE in
                (*[0-9]*|'')

                        PERCENT=$(($DIMENSIONE*100/$LIMITE))

                        # controlla se $PERCENT > $SOGLIA e quindi inviare l'avviso
                        if [ $PERCENT -gt $SOGLIA ]; then

cat << EOF | /usr/libexec/dovecot/dovecot-lda -d $EMAIL
Return-Path: $NOMEMITT <$MAILMITT>
From: $NOMEMITT <$MAILMITT>
Subject: $SUBJECT $PERCENT%
Content-Type: text/plain; charset=UTF-8; format=flowed
Content-Transfer-Encoding: 8bit

$MAILMESS
EOF

                        fi
                esac
        fi
        done
done

