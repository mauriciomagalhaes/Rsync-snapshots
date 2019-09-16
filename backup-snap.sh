#!/usr/bin/env bash
#
# Instalar os pacote curl e jq
# Criar certificado entre a origem e o destino para nao necessitar da senha
#
# 1 - ssh-keygen -t rsa -f ~/.ssh/id_rsa
# 2 - cat ~/.ssh/id_rsa.pub | ssh root@maquina_remota 'cat - >> ~/.ssh/authorized_keys'
# 
# set -e
# set -x
# set -u
#
JQ=$(which jq)
DU=$(which du)
#
NAMEPREFIX="BACKUP"
TODAY=$(date '+%d/%m/%Y - %H:%M:%S')
DATE=$(date '+D%Y-%m-%dT%H_%M_%S')
#DIR_BACKUP="root@192.168.122.6:/mnt/FOTOS/FOTOS2/FOTOS DRONE"        # Diretorio a ser bacapeado
DIR_BACKUP="/home/mauricio/FOTOS"                                     # Diretorio a ser bacapeado
DIR_DESTINATION="/home/mauricio/BACKUP"                               # Backup de Destino
LAST_BACKUP="$DIR_DESTINATION/last"                                   # link simbolico
#FILTER_RANSOMWARES="/opt/scripts/Rsync-snapshots"
FILTER_RANSOMWARES="/home/mauricio"                                   # Filtro de arquivos que não serão copiados
RETENCAO="+30"                                                        # +X - Acima de X dias / -X Abaixo de X Dias
#
# Remover Backups Antigos de Acordo com a quantida dias de Retenção, Ajustar na variavel RETENCAO
#
REMOVER=$(find $DIR_DESTINATION -maxdepth 1 -mtime $RETENCAO -name 'CADU-*')
for i in $REMOVER; do
       rm -Rf $i
done
#
while true; do
    if curl --output /dev/null --silent --head --fail https://fsrm.experiant.ca/api/v1/combined; then
        curl -o $FILTER_RANSOMWARES/rans.json https://fsrm.experiant.ca/api/v1/combined && break
    fi
done
#
# Remover os arquivos thumbs gerados pelo Windows.
# echo "- Thumbs\.db" >> rans.lst
#
$JQ -r .filters[] $FILTER_RANSOMWARES/rans.json > $FILTER_RANSOMWARES/rans.lst
#
sed -i 's/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/\@/\\@/g; s/\$/\\$/g; s/\ /\\ /g; s/\!/\\!/g; s/^/- /g' $FILTER_RANSOMWARES/rans.lst
#
rsync -avPps --log-file=$DIR_DESTINATION/rsync.log --filter="merge $FILTER_RANSOMWARES/rans.lst" --link-dest=${LAST_BACKUP} "$DIR_BACKUP" $DIR_DESTINATION/$NAMEPREFIX-${DATE} 
#
unlink ${LAST_BACKUP}
#
ln -s $DIR_DESTINATION/$NAMEPREFIX-${DATE}  ${LAST_BACKUP}
#
$DU -sh --exclude=last --exclude=*.log $DIR_DESTINATION/* > $DIR_DESTINATION/backup.log
mapfile -t REGISTROS < $DIR_DESTINATION/backup.log
#
for i in "${REGISTROS[@]}"; do
      d=$(echo $i | awk '{print $2}')
      if [ $d == $DIR_DESTINATION/$NAMEPREFIX-${DATE} ]; then
        INCREMENTAL=$(echo $i | awk '{print $1}')
      fi
done
#
FINAL=$(date '+%d/%m/%Y - %H:%M:%S')
TAMREAL=$(du -sh $DIR_DESTINATION/$NAMEPREFIX-${DATE} | awk '{print $1}')
TAMTOTAL=$(du -sh $DIR_DESTINATION | awk '{print $1}')
#
echo "Backup realizado com sucesso!"
echo "Início:       ${TODAY}"
echo "Término:      ${FINAL}"
echo "Total Real:   ${TAMREAL}"                                                           # Tamanho Real da Origem
echo "Incremental   ${INCREMENTAL}        $DIR_DESTINATION/$NAMEPREFIX-${DATE}"           # Tamanho da último Backup Incremental     
echo "Total Disco:  ${TAMTOTAL}     $DIR_DESTINATION"                                     # Tamanho do Backup armazenado no disco local
#
SendTelegram(){
    #API_TOKEN=""
    #ID1=""
    #ID2=""
    HEADER=">> Backup Rsync $FINAL 💾 <</n"
    MESSAGE="$HEADER/n ▫️ Inicio: ${TODAY}/n ▫️ Término: ${FINAL}/n ▫️ Total Real: ${TAMREAL}/n ▫️ Incremental: ${INCREMENTAL}/n ▫️ Total Disco: ${TAMTOTAL}/n"
    MESSAGE=`echo $MESSAGE | sed 's/\/n/%0A/g'`
    URL1="https://api.telegram.org/bot${API_TOKEN}/sendMessage?chat_id=${ID1}&text=$MESSAGE"
    URL2="https://api.telegram.org/bot${API_TOKEN}/sendMessage?chat_id=${ID2}&text=$MESSAGE"
    curl -s "$URL1" > /dev/null
    #curl -s "$URL2" > /dev/null
}
#
SendTelegram
#
exit