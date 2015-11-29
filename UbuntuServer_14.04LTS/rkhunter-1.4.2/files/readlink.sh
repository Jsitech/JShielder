#!/bin/sh

#
# This is a short script to get the full pathname of a link file.
# It has the same effect as the Linux 'readlink -f' command. The
# script was written because some systems have no 'readlink' command,
# and others have no '-f' option for readlink. As such we use the 'ls'
# and 'awk' commands to get the link target.
#
# We check the 'pwd' command because the shell builtin command will
# usually print out the current directory, which may be a link, rather
# than the true working directory. The (typically) '/bin/pwd' command
# itself shows the true directory.
#
# A soft (symbolic) link has two parts to it:
#
#       linkname -> target
#
# Usage: readlink.sh [-f] <linkname> [pwd command]
#


#
# We don't actually do anything with the '-f' option
# if it is used.
#

test "$1" = "-f" && shift

LINKNAME=$1
PWD_CMD=$2

test -z "${PWD_CMD}" -o ! -x "${PWD_CMD}" && PWD_CMD="pwd"


#
# If we were given just a filename, then prepend
# the current directory to it.
#

if [ -z "`echo \"${LINKNAME}\" | grep '/'`" ]; then
	DIR=`${PWD_CMD}`
	test "${DIR}" = "/" && DIR=""

	LINKNAME="${DIR}/${LINKNAME}"
fi


#
# Now do some tests on the link name.
#

if [ -d "${LINKNAME}" ]; then
	FNAME=""
	DIR="${LINKNAME}"
else
	#
	# We have been given a pathname to a file. Separate
	# out the filename and the directory.
	#

	FNAME=`echo "${LINKNAME}" | sed -e 's:^.*/\([^/]*\)$:\1:'`
	DIR=`echo "${LINKNAME}" | sed -e 's:/[^/]*$::'`


	# Check if it is a top-level name.

	if [ -z "${DIR}" ]; then
		if [ ! -e "${LINKNAME}" ]; then
			DIR="${LINKNAME}"
		else
			DIR="/"
		fi
	fi

	if [ ! -d "${DIR}" ]; then
		echo "Directory ${DIR} does not exist." >&2
		echo "${LINKNAME}"
		exit
	fi
fi


#
# Get the true directory path.
#

DIR=`cd ${DIR}; ${PWD_CMD}`


#
# If we were only given a directory name, then return
# its true path.
#

if [ -z "${FNAME}" ]; then
	echo "${DIR}"
	exit
fi


#
# Now we loop round while we have a link.
#

RKHLINKCOUNT=0
ORIGLINK="${LINKNAME}"

while test -h "${DIR}/${FNAME}"; do
	#
	# Get the link directory, and the target.
	#

	LINKNAME="${DIR}"
	FNAME=`ls -ld "${DIR}/${FNAME}" | awk '{ print $NF }'`


	#
	# If the target is just a filename, then we
	# prepend the link directory path. If it isn't
	# just a filename, then we have a pathname. That
	# now becomes our new link name.
	#

	if [ -z "`echo \"${FNAME}\" | grep '^/'`" ]; then
		LINKNAME="${LINKNAME}/${FNAME}"
	else
		LINKNAME="${FNAME}"
	fi


	#
	# Once again, extract the file name and the directory
	# path, and then get the real directory path name.
	#

	FNAME=`echo "${LINKNAME}" | sed -e 's:^.*/\([^/]*\)$:\1:'`
	DIR=`echo "${LINKNAME}" | sed -e 's:/[^/]*$::'`

	DIR=`cd ${DIR}; ${PWD_CMD}`

	RKHLINKCOUNT=`expr ${RKHLINKCOUNT} + 1`

	if [ ${RKHLINKCOUNT} -ge 64 ]; then
		echo "Too many levels of symbolic links (${RKHLINKCOUNT}): ${ORIGLINK}" >&2
		echo "${ORIGLINK}"
		exit
	fi
done


#
# At this point we have a pathname to a file, which is not
# a link. To ensure we have the true pathname, we once again
# extract the directory.
#

FNAME=`echo "${LINKNAME}" | sed -e 's:^.*/\([^/]*\)$:\1:'`
DIR=`echo "${LINKNAME}" | sed -e 's:/[^/]*$::'`

test -n "${DIR}" && DIR=`cd ${DIR}; ${PWD_CMD}`

echo "${DIR}/${FNAME}"

exit
