#!/bin/sh

# Only set EnvDir here
EnvDir=/usr/local/untd/apps/dba_tools/etc/app

#Check environment file
if [ ! -f "${EnvDir}/innobackupex.env" ]
then
echo "Innobackupex env file ${EnvDir}/innobackupex.env not found"
exit 1
fi

#Check user running this script
user=`id | sed -e 's/^uid=[0-9]*(\([^)]*\)).*$/\1/'`
if [ "$user" != "mysql" ]; then
   echo "Run as mysql. You are \"$user\"";
   exit 1
fi

source ${EnvDir}/innobackupex.env

#Check variables
if [ -z ${Hostname+x} ]; then
echo "Please set Hostname variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${BackupDir+x} ]; then
echo "Please set BackupDir variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${LogDir+x} ]; then
echo "Please set LogDir variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${DefaultsFile+x} ]; then
echo "Please set DefaultsFile variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${User+x} ]; then
echo "Please set User variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${Password+x} ]; then
echo "Please set Password variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${StatsHost+x} ]; then
echo "Please set StatsHost variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${StatsDb+x} ]; then
echo "Please set StatsDb variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${StatsUsername+x} ]; then
echo "Please set StatsUsername variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${StatsPassword+x} ]; then
echo "Please set StatsPassword variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${StatsTable+x} ]; then
echo "Please set StatsTable variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${Email+x} ]; then
echo "Please set Email variable in ${EnvDir}/innobackupex.env"
exit 1
elif [ -z ${PidFile+x} ]; then
echo "Please set PidFile variable in ${EnvDir}/innobackupex.env"
exit 1
fi

#Set pid file
trap "rm -f -- '$PidFile'" EXIT
echo $$ > "$PidFile"

#Few other variables needed by script
Me=`basename "$0"`
CurDate=`date +%Y%m%d%H%M%S`
InnobackupBinary=/usr/bin/innobackupex
FullDir=${BackupDir}/${CurDate}_FULL
IncrDir=${BackupDir}/${CurDate}_INCR
FullLog=/tmp/innobackupex_full.log
IncrLog=/tmp/innobackupex_incr.log
LogFile=${LogDir}/${Me}_${CurDate}

#Check for process already running
for pid in $(pidof -x ${Me}); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : $Me : Process is already running with PID $pid"
        exit 1
    fi
done

full()
{
BackupFullCommand="${InnobackupBinary} --no-timestamp --slave-info --user=${User} --password=${Password} --defaults-file=${DefaultsFile} --compress ${FullDir}"
$BackupFullCommand > $FullLog 2>&1
if [ -z "`tail -1 ${FullLog}|grep 'completed OK!'`" ]; then
#Backup failed, save the log file
cp $FullLog $LogFile
echo -e "Mysql full backup failed on $Hostname \nVerify Log file for errors - $LogFile" | mailx -s "[$Hostname] Mysql full backup failed" $Email
exit 1
fi
}

incr()
{
CheckLastFull=`ls -lrth ${BackupDir} | grep 'FULL'`
if [ $? -ne 0 ]; then
echo "No Full backups found"
exit 1
fi
# Get last full backup dir
IncrBaseDir=${BackupDir}/`ls -lrth ${BackupDir} | grep 'FULL' | tail -1 | awk {'print $NF'}`
BackupIncrCommand="${InnobackupBinary} --no-timestamp --slave-info --user=${User} --password=${Password} --defaults-file=${DefaultsFile} --compress --incremental $IncrDir --incremental-basedir=$IncrBaseDir"
$BackupIncrCommand > $IncrLog 2>&1
if [ -z "`tail -1 ${IncrLog}|grep 'completed OK!'`" ]; then
#Backup failed, save the log file
cp $IncrLog $LogFile
echo -e "Mysql incremental backup failed on $Hostname \nPossible reason could be one of these \n1.Failure of last full backup \n2.Cannot connect to Mysql host \n\nVerify Log file for errors - $LogFile" | mailx -s "[$Hostname] Mysql incremental backup failed" $Email
exit 1
fi
}

if [ "$1" == "--incr" ]; then
BackupType=INCR
incr
else
BackupType=FULL
full
fi

#Backup succeeded, save details to stats db
mysql -u${StatsUsername} -p${StatsPassword} -h${StatsHost} -D${StatsDb} 2>/dev/null <<EOFMYSQL
insert into ${StatsTable}(host,backup_date,backup_type) values ('$Hostname',now(),'$BackupType');
EOFMYSQL
if [ "$?" != "0" ];
then
echo "Failed to store Mysql backup stats"
exit 1
fi
