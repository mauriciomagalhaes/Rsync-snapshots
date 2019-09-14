#!/usr/bin/env bash
#
# Instalar os pacote curl e jq
# Criar certificado entre a origem e o destino para nao necessitar da senha
#
# 1 - ssh-keygen -t rsa -f ~/.ssh/id_rsa
# 2 - cat ~/.ssh/id_rsa.pub | ssh root@maquina_remota 'cat - >> ~/.ssh/authorized_keys'
# 
#
set -e
set -x
set -u

TODAY=$(date '+%d/%m/%Y - %H:%M:%S')
DATE=$(date '+D%Y-%m-%dT%H_%M_%S')
DIR_BACKUP="root@192.168.122.6:/mnt/FOTOS/FOTOS2/FOTOS DRONE"       # Diretorio a ser bacapeado
DIR_DESTINATION=/mnt/DISCO-BACKUP/BACKUP       # Backup de Destino
LAST_BACKUP=/mnt/DISCO-BACKUP/BACKUP/last                           # link simbolico
FILTER_RANSOMWARES="/opt/scripts/Rsync-snapshots"                   # Filtro de arquivos que não serão copiados
QTD_DIA="+30"                                                       # +X - Acima de X dias / -X Abaixo de X Dias
JQ=$(which jq)
#
while true; do
    if curl --output /dev/null --silent --head --fail https://fsrm.experiant.ca/api/v1/combined; then
        curl -o $FILTER_RANSOMWARES/rans.json https://fsrm.experiant.ca/api/v1/combined && break
    fi
done
#
# Se quiser remover os arquivos thumbs gerados pelo Windows.
# echo "- Thumbs\.db" >> rans.lst
#
$JQ -r .filters[] $FILTER_RANSOMWARES/rans.json > $FILTER_RANSOMWARES/rans.lst
#
sed -i 's/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/\@/\\@/g; s/\$/\\$/g; s/\ /\\ /g; s/\!/\\!/g; s/^/- /g' $FILTER_RANSOMWARES/rans.lst
#
rsync -avPps --filter="merge $FILTER_RANSOMWARES/rans.lst" --link-dest=${LAST_BACKUP} "$DIR_BACKUP" $DIR_DESTINATION/CADU-FOTOS2-${DATE} 
#
unlink ${LAST_BACKUP}
#
ln -s $DIR_DESTINATION/CADU-FOTOS2-${DATE}  ${LAST_BACKUP}
#
# Remover Backups Antigos de Acordo com a quantida de dias, Ajustar na variavel QTD_DIA
#REMOVER=$(find $DIR_DESTINATION -maxdepth 1 -mtime $QTD_DIA -name 'CADU-*')
#for i in $REMOVER; do
#       rm -Rf $i
#done

#SendTelegram(){
#        API_TOKEN=""
#        #ID=""
#        ID=""
#        LOG="/var/log/telegram.log"
#        HORA=$(echo $BACKUP_NAME | cut -c 19-20)
#        HEADER=">> Backup MITRA $HORA"h" 💾 <</n"
#        ListSMB=$(ls -lh "$REMOTE_SMB/$BACKUP_DATE_DIR" | grep $HORA":" | awk '{printf "%1s %s\n", $5," "$9}')
#        if [ -z "$ListSMB" ]; then
#                MSGSMB="Arquivo não encontrado ❌"
#        else
#                MSGSMB="  ✅ "
#        fi
#        MESSAGE="$HEADER/nARQUIVO = $ListSMB $MSGSMB"
#        MESSAGE=`echo $MESSAGE | sed 's/\/n/%0A/g'`
#        URL="https://api.telegram.org/bot${API_TOKEN}/sendMessage?chat_id=${ID}&text=$MESSAGE"
#        COUNT=1
#
#while [ $COUNT -le 20 ]; do
#   echo "$(date +%d/%m/%Y\ %H:%M:%S) - Start message send (attempt $COUNT) ..." >> $LOG
#   #echo "$(date +%d/%m/%Y\ %H:%M:%S) - $MESSAGELOG" >> $LOG
#   #/usr/bin/curl -s "$URL" > /dev/null
#   /usr/bin/curl -s "$URL"
#   RET=$?
#
#   if [ $RET -eq 0 ]; then
#     echo "$(date +%d/%m/%Y\ %H:%M:%S) - Attempt $COUNT executed successfully!" >> $LOG
#     exit 0
#   else
#     echo "$(date +%d/%m/%Y\ %H:%M:%S) - Attempt $COUNT failed!" >> $LOG
#     echo "$(date +%d/%m/%Y\ %H:%M:%S) - Waiting 30 seconds before retry ..." >> $LOG
#     sleep 30
#     (( COUNT++ ))
#   fi
#done
#}



echo "Backup feito com sucesso em ${DIR_DESTINATION} no dia ${TODAY}".

exit

