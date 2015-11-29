#!/bin/sh
#
# run_rkhunter  --  check the system integrity using rkhunter
# Author: Dr. Andy Spiegl, KasCada Telekommunikation  (www.kascada.com)
# This software is GPL and free to use.
#

############################################
# Have cron call this script, eg. like this:
#  /etc/cron.d/run_rkhunter
############################################
# # Fallthrough in case of errors in this cronfile
# MAILTO=your_address@yourdomain.com
#
# SKRIPT=/usr/local/sbin/kas/run_rkhunter
# PATH=/sbin:/bin:/usr/sbin:/usr/bin
#
# 15   4 * * *  root  test -x $SKRIPT && $SKRIPT 2>&1
############################################

############################################
# History:
#
# v0.1  2005-02-14: first Version, split from run_chkrootkit
# v0.2  2005-02-15: translated into English
# v0.3  2005-02-20: changed some private information
#
############################################

# where to send the output of rkhunter
MAILADDRESSES=rkhunter_errors@yourdomain.com
# use aktelog instead:
#AKTELOG=/usr/local/sbin/aktelog
#AKTELOG_LABEL="rkhunter"

# appending logfile (rotate it!)
LOGFILE=/var/log/mylogdir/rkhunter.log

# rkhunters own logfile (only contains info from last run)
RKLOGFILE=/var/log/rkhunter.log


RKHUNTER=/usr/local/rkhunter/bin/rkhunter
RKHUNTER_OPTS="-c --cronjob --report-warnings-only --skip-application-check --createlogfile --tmpdir /usr/local/rkhunter/lib/rkhunter/tmp"

# try to get a secure tempfile
if [ -x /bin/tempfile ]; then
	TMPLOGFILE1=`/bin/tempfile -p rkhu.`
	TMPLOGFILE2=`/bin/tempfile -p rkhu.`
else
	TMPLOGFILE1=/var/tmp/rkhunter.tmp1.$$
	TMPLOGFILE2=/var/tmp/rkhunter.tmp2.$$
	# avoid symlink attacks
	rm -fr $TMPLOGFILE1 $TMPLOGFILE2
	touch $TMPLOGFILE1 $TMPLOGFILE2
fi


# first update the rkhunter hashes
echo "=======Updating=================================" >> $LOGFILE
/bin/date >> $LOGFILE
$RKHUNTER --update 2>&1 >> $TMPLOGFILE1
if egrep -q "(Error|outdated)" $TMPLOGFILE1 ; then
	echo . >> $TMPLOGFILE1
	echo "WARNING: rkhunter couldn't update its hashes which will" >> $TMPLOGFILE1
	echo "most likely lead to errors now." >> $TMPLOGFILE1
fi
cat $TMPLOGFILE1 >> $LOGFILE

# now start checking the server
echo "=======Checking=================================" >> $LOGFILE
/bin/date >> $LOGFILE
$RKHUNTER $RKHUNTER_OPTS >> $TMPLOGFILE2

/bin/cat $RKLOGFILE >> $LOGFILE
echo done. >> $LOGFILE

if [ -s $TMPLOGFILE2 ]; then
	(
		echo __Start__: Output of rkhunter at `/bin/date`;
		echo "=======Updating=================================";
		/bin/cat $TMPLOGFILE1 ;
		echo "=======Checking=================================";
		/bin/cat $TMPLOGFILE2 ;
		echo __End__ of rkhunter output
	) | mail -s "rkhunter output" $MAILADDRESSES
	#  ) | $AKTELOG $AKTELOG_LABEL
fi

rm -f $TMPLOGFILE1 $TMPLOGFILE2

