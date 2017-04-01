
innobackupex.sh
===============

``innobackupex.sh`` - Mysql full and incremental backup script using innobackupex.

Syntax
======

::

 Usage: innobackupex.sh

Set following variables in *innobackupex.env* file

::

 Hostname - hostname of the mysql server.
 BackupDir - location of backup directory, Subdirectories would be created as ${CurDate}_FULL, ${CurDate}_INCR for full and incremental backups respectively.
 LogDir - Location to store backup logs incase backup fails. Logfile saved as scriptname_${CurDate}.
 DefaultsFile - location of Mysql my.cnf file
 User - Mysql DB user used to backup database.
 Password - Password for above mentioned db user.
 Email - email to send backup failure alerts, multiple email id's seperated by comma.
 PidFile - pid file to be generated while backup script is running.

 StatsHost - Mysql hostname to store backup stats
 StatsDb - Mysql DB name for backup stats
 StatsUsername - Mysql user to connect to above database.
 StatsPassword - Password for above mentioned db user
 StatsTable - table name to store DB backup stats, DDL provided below.
 
StatsTable DDL :
----------------

::

 create table mysql_backup_stats(
 id int auto_increment primary key,
 host varchar(50) not null,
 backup_date datetime not null,
 backup_type varchar(10) not null,
 create_sysdate datetime default CURRENT_TIMESTAMP,
 update_sysdate datetime default CURRENT_TIMESTAMP);
 create unique index mysql_backup_stats_n1 on mysql_backup_stats(host,backup_date,backup_type);
