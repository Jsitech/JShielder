#!/bin/sh

################################################################################
#
#  Rootkit Hunter installer
# --------------------------
#
# Copyright Michael Boelen ( michael AT rootkit DOT nl )
# See LICENSE file for use of this software
#
################################################################################

INSTALLER_NAME="Rootkit Hunter installer"
INSTALLER_VERSION="1.2.21"
INSTALLER_COPYRIGHT="Copyright 2018, Michael Boelen"
INSTALLER_LICENSE="

This software was developed by the Rootkit Hunter project team.
For reporting bugs, patches, comments and questions, please go to:
http://rkhunter.sourceforge.net

Rootkit Hunter comes with ABSOLUTELY NO WARRANTY. This is free
software, and you are welcome to redistribute it under the terms
of the GNU General Public License. See LICENSE for details.
"

APPNAME="rkhunter"
APPVERSION="1.4.6"
RKHINST_OWNER="0:0"
RKHINST_MODE_EX="0700"
RKHINST_MODE_RW="0600"
RKHINST_MODE_RWR="0644"
RKHINST_LAYOUT="default"
RKHINST_ACTION=""
RKHINST_ACTION_SEEN=0
ERRCODE=0
OVERWRITE=0
STRIPROOT=""

RPM_USING_ROOT=0
TGZ_USING_ROOT=0
TXZ_USING_ROOT=0
DEB_USING_ROOT=0

umask 027

OPERATING_SYSTEM=`uname`
UNAMEM=`uname -m`

if [ "${OPERATING_SYSTEM}" = "SunOS" ]; then
	if [ -z "$RANDOM" ]; then
		# If the 'which' output contains a space, then it is probably an error.
		if [ -n "`which bash 2>/dev/null | grep -v ' '`" ]; then
			exec bash $0 $*
		elif [ -n "`which ksh 2>/dev/null | grep -v ' '`" ]; then
			exec ksh $0 $*
		else
			echo "Unable to find the bash or ksh shell to run the installer. Exiting."
			exit 1
		fi

		exit 0
	fi

	# We need /usr/xpg4/bin before other directories on Solaris.
	PATH="/usr/xpg4/bin:${PATH}" 
fi


showHelp() { # Show help / version
	echo "${INSTALLER_NAME} ${INSTALLER_VERSION}"
	echo ""
	echo "Usage: $0 <parameters>"
	echo ""
	echo "Ordered valid parameters:"
	echo '  --help (-h)      : Show this help.'
	echo "  --examples       : Show layout examples."
	echo '  --layout <value> : Choose installation template.'
	echo "                     The templates are:"
        echo '                      - default: (FHS compliant; the default)'
        echo "                      - /usr"
        echo "                      - /usr/local"
	echo "                      - oldschool: old version file locations"
	echo "                      - custom: supply your own installation directory"
	echo "                      - RPM: for building RPM's. Requires \$RPM_BUILD_ROOT."
	echo "                      - DEB: for building DEB's. Requires \$DEB_BUILD_ROOT."
	echo "                      - TGZ: for building Slackware TGZ's. Requires \$TGZ_BUILD_ROOT."
	echo "                      - TXZ: for building Slackware TXZ's. Requires \$TXZ_BUILD_ROOT."
	echo '  --striproot      : Strip path from custom layout (for package maintainers).'
	echo "  --install        : Install according to chosen layout."
	echo "  --overwrite      : Overwrite the existing configuration file."
	echo "                     (Default is to create a separate configuration file.)"
	echo "  --show           : Show chosen layout."
	echo "  --remove         : Uninstall according to chosen layout."
	echo "  --uninstall      : Alias for the '--remove' option."
	echo "  --version        : Show the installer version."
	echo ""

	return
}

showExamples() { # Show examples
	echo "${INSTALLER_NAME}"
	echo ""
	echo "Examples:"
	echo "1. Show layout, files in /usr:"
	echo "        installer.sh --layout /usr --show"
	echo ""
	echo "2. Install in /usr/local:"
	echo "        installer.sh --layout /usr/local --install"
	echo ""
	echo '3. Install in chosen (custom) directory /opt:'
	echo "        installer.sh --layout custom /opt --install"
	echo ""
	echo "4. Install in temporary directory /tmp/rkhunter/usr/local,"
	echo '   with files in /usr/local (for package maintainers):'
	echo "        mkdir -p /tmp/rkhunter/usr/local"
	echo "        installer.sh --layout custom /tmp/rkhunter/usr/local \\"
	echo "                     --striproot /tmp/rkhunter --install"
	echo ""
	echo "5. Remove files, layout /usr/local:"
	echo "        installer.sh --layout /usr/local --remove"
	echo ""

	return
}

showVersion() { echo "${INSTALLER_NAME} ${INSTALLER_VERSION} ${INSTALLER_LICENSE}"; return; }

selectTemplate() { # Take input from the "--install parameter"
	case "$1" in
	/usr|/usr/local|default|custom_*|RPM|DEB|TGZ|TXZ)
		case "$1" in
		default)
			PREFIX="/usr/local"
			;;
		custom_*)
			PREFIX=`echo "${RKHINST_LAYOUT}" | sed 's|custom_||g'`

			case "${PREFIX}" in
			.)
				if [ "${RKHINST_ACTION}" = "install" ]; then
					echo "Standalone installation into ${PWD}/files"
				fi
				;;
			.*|/.*|*//*)
				echo "Invalid layout directory chosen: ${PREFIX}"
				exit 1
				;;
			*)
				test "${PREFIX}" = "/" && PREFIX=""

				if [ "${RKHINST_ACTION}" = "install" ]; then
					RKHTMPVAR=`echo "${PATH}" | grep "${PREFIX}/bin"`

					if [ -z "${RKHTMPVAR}" ]; then
						echo ""
						echo "Note: Directory ${PREFIX}/bin is not in your PATH"
						echo ""
					fi
				fi
				;;
			esac
			;;
		RPM)
			if [ -n "${RPM_BUILD_ROOT}" ]; then
				if [ "${RPM_BUILD_ROOT}" = "/" ]; then
					RPM_USING_ROOT=1
					PREFIX="/usr/local"
				else
					PREFIX="${RPM_BUILD_ROOT}/usr/local"
				fi
			else
				echo "RPM installation chosen but \$RPM_BUILD_ROOT variable not found. Exiting."
				exit 1
			fi
			;;
		DEB)
			if [ -n "${DEB_BUILD_ROOT}" ]; then
				if [ "${DEB_BUILD_ROOT}" = "/" ]; then
					DEB_USING_ROOT=1
					PREFIX="/usr"
				else
					PREFIX="${DEB_BUILD_ROOT}/usr"
				fi
			else
				echo "DEB installation chosen but \$DEB_BUILD_ROOT variable not found. Exiting."
				exit 1
			fi
			;;
		TGZ)
			if [ -n "${TGZ_BUILD_ROOT}" ]; then
				if [ "${TGZ_BUILD_ROOT}" = "/" ]; then
					TGZ_USING_ROOT=1
					PREFIX="/usr"
				else
					PREFIX="${TGZ_BUILD_ROOT}/usr"
				fi
			else
				echo "TGZ installation chosen but \$TGZ_BUILD_ROOT variable not found. Exiting."
				exit 1
			fi
			;;
		TXZ)
			if [ -n "${TXZ_BUILD_ROOT}" ]; then
				if [ "${TXZ_BUILD_ROOT}" = "/" ]; then
					TXZ_USING_ROOT=1
					PREFIX="/usr"
				else
					PREFIX="${TXZ_BUILD_ROOT}/usr"
				fi
			else
				echo "TXZ installation chosen but \$TXZ_BUILD_ROOT variable not found. Exiting."
				exit 1
			fi
			;;
		*)
			PREFIX="$1"
			;;
		esac

		case "$1" in
		RPM|DEB|TGZ|TXZ)
			;;
		*)
			if [ "${RKHINST_ACTION}" = "install" ]; then
				if [ -n "${PREFIX}" -a ! -d "${PREFIX}" ]; then
					echo "Non-existent installation directory chosen: ${PREFIX}"
					echo "Perhaps run \"mkdir -p ${PREFIX}\" first?"
					exit 1
				fi
			fi
			;;
		esac

		case "$1" in
		/usr/local|custom_*)
			SYSCONFIGDIR="${PREFIX}/etc"
			;;
		RPM)
			if [ $RPM_USING_ROOT -eq 1 ]; then
				SYSCONFIGDIR="/etc"
			else
				SYSCONFIGDIR="${RPM_BUILD_ROOT}/etc"
			fi
			;;
		DEB)
			if [ $DEB_USING_ROOT -eq 1 ]; then
				SYSCONFIGDIR="/etc"
			else
				SYSCONFIGDIR="${DEB_BUILD_ROOT}/etc"
			fi
			;;
		TGZ)
			if [ $TGZ_USING_ROOT -eq 1 ]; then
				SYSCONFIGDIR="/etc"
			else
				SYSCONFIGDIR="${TGZ_BUILD_ROOT}/etc"
			fi
			;;
		TXZ)
			if [ $TXZ_USING_ROOT -eq 1 ]; then
				SYSCONFIGDIR="/etc"
			else
				SYSCONFIGDIR="${TXZ_BUILD_ROOT}/etc"
			fi
			;;
		*)
			SYSCONFIGDIR="/etc"
			;;
		esac

		case "$1" in
		custom_*)
			LIBDIR=""

			if [ -z "${PREFIX}" -a "${OPERATING_SYSTEM}" = "Darwin" ]; then
				test -d "/Library" && LIBDIR="/Library"
			fi

			if [ -z "${LIBDIR}" ]; then
				if [ "${UNAMEM}" = "x86_64" -o "${UNAMEM}" = "ppc64" ]; then
					LIBDIR="${PREFIX}/lib64"
				else
					LIBDIR="${PREFIX}/lib"
				fi
			fi

			BINDIR="${PREFIX}/bin"
			VARDIR="${PREFIX}/var"

			if [ -z "${PREFIX}" ]; then
				if [ ! -d "/share" -a -d "/usr/share" ]; then
					SHAREDIR="/usr/share"
				else
					SHAREDIR="/share"
				fi
			else
				SHAREDIR="${PREFIX}/share"
			fi
			;;
		RPM)
			if [ "${UNAMEM}" = "x86_64" -o "${UNAMEM}" = "ppc64" ]; then
				LIBDIR="${PREFIX}/lib64"
			else
				LIBDIR="${PREFIX}/lib"
			fi

			BINDIR="${PREFIX}/bin"

			if [ $RPM_USING_ROOT -eq 1 ]; then
				VARDIR="/var"
			else
				VARDIR="${RPM_BUILD_ROOT}/var"
			fi

			SHAREDIR="${PREFIX}/share"
			;;
		DEB)
			BINDIR="${PREFIX}/bin"
			LIBDIR="${PREFIX}/lib"

			if [ $DEB_USING_ROOT -eq 1 ]; then
				VARDIR="/var"
			else
				VARDIR="${DEB_BUILD_ROOT}/var"
			fi

			SHAREDIR="${PREFIX}/share"
			;;
		TGZ)
			if [ "${UNAMEM}" = "x86_64" -o "${UNAMEM}" = "ppc64" ]; then
				LIBDIR="${PREFIX}/lib64"
			else
				LIBDIR="${PREFIX}/lib"
			fi

			BINDIR="${PREFIX}/bin"

			if [ $TGZ_USING_ROOT -eq 1 ]; then
				VARDIR="/var"
			else
				VARDIR="${TGZ_BUILD_ROOT}/var"
			fi

			SHAREDIR="${PREFIX}/share"
			;;
		TXZ)
			if [ "${UNAMEM}" = "x86_64" -o "${UNAMEM}" = "ppc64" ]; then
				LIBDIR="${PREFIX}/lib64"
			else
				LIBDIR="${PREFIX}/lib"
			fi

			BINDIR="${PREFIX}/bin"

			if [ $TXZ_USING_ROOT -eq 1 ]; then
				VARDIR="/var"
			else
				VARDIR="${TXZ_BUILD_ROOT}/var"
			fi

			SHAREDIR="${PREFIX}/share"
			;;
		*)
			if [ -d "${PREFIX}/lib64" ]; then
				LIBDIR="${PREFIX}/lib64"
			else
				LIBDIR="${PREFIX}/lib"
			fi

			BINDIR="${PREFIX}/bin"
			VARDIR="/var"
			SHAREDIR="${PREFIX}/share"
			;;
		esac
		;;
	oldschool) # The rigid way, like RKH used to be set up.
		PREFIX="/usr/local"
		SYSCONFIGDIR="${PREFIX}/etc"
		LIBDIR="${PREFIX}/${APPNAME}/lib"
		VARDIR="${LIBDIR}"
		SHAREDIR="${LIBDIR}"
		RKHINST_DOC_DIR="${PREFIX}/${APPNAME}/lib/docs"
		BINDIR="${PREFIX}/bin"
		;;
	*)	# None chosen.
		echo "No template chosen. Exiting."
		exit 1
		;;
	esac

	RKHINST_ETC_DIR="${SYSCONFIGDIR}"
	RKHINST_BIN_DIR="${BINDIR}"
	RKHINST_SCRIPT_DIR="${LIBDIR}/${APPNAME}/scripts"
	RKHINST_MAN_DIR="${SHAREDIR}/man/man8"

	if [ "${RKHINST_LAYOUT}" = "oldschool" ]; then
		RKHINST_DB_DIR="${VARDIR}/${APPNAME}/db"
		RKHINST_TMP_DIR="${VARDIR}/${APPNAME}/tmp"
		RKHINST_DOC_DIR="${SHAREDIR}/${APPNAME}/docs"
	elif [ "${RKHINST_LAYOUT}" = "DEB" ]; then
		RKHINST_DB_DIR="${VARDIR}/lib/${APPNAME}/db"
		RKHINST_TMP_DIR="${VARDIR}/lib/${APPNAME}/tmp"
		RKHINST_DOC_DIR="${SHAREDIR}/doc/${APPNAME}"
		RKHINST_SCRIPT_DIR="${SHAREDIR}/${APPNAME}/scripts"
	elif [ "${RKHINST_LAYOUT}" = "TXZ" ]; then
		RKHINST_DB_DIR="${VARDIR}/lib/${APPNAME}/db"
		RKHINST_TMP_DIR="${VARDIR}/lib/${APPNAME}/tmp"
		RKHINST_DOC_DIR="${PREFIX}/doc/${APPNAME}-${APPVERSION}"
		RKHINST_MAN_DIR="${PREFIX}/man/man8"
	else
		RKHINST_DB_DIR="${VARDIR}/lib/${APPNAME}/db"
		RKHINST_TMP_DIR="${VARDIR}/lib/${APPNAME}/tmp"
		RKHINST_DOC_DIR="${SHAREDIR}/doc/${APPNAME}-${APPVERSION}"
	fi

	RKHINST_LANG_DIR="${RKHINST_DB_DIR}/i18n"
	RKHINST_SIG_DIR="${RKHINST_DB_DIR}/signatures"

	RKHINST_ETC_FILE="${APPNAME}.conf"
	RKHINST_BIN_FILES="${APPNAME}"

	RKHINST_SCRIPT_FILES="check_modules.pl filehashsha.pl stat.pl readlink.sh"
	RKHINST_DB_FILES="backdoorports.dat mirrors.dat programs_bad.dat suspscan.dat"
	RKHINST_SIG_FILES="RKH_dso.ldb RKH_Glubteba.ldb RKH_jynx.ldb RKH_kbeast.ldb RKH_libkeyutils1.ldb RKH_libkeyutils.ldb RKH_libncom.ldb RKH_pamunixtrojan.ldb RKH_shv.ldb RKH_sniffer.ldb RKH_sshd.ldb RKH_turtle.ldb RKH_xsyslog.ldb"

	if [ "${RKHINST_LAYOUT}" = "DEB" ]; then
		RKHINST_DOC_FILES="ACKNOWLEDGMENTS FAQ README"
	else
		RKHINST_DOC_FILES="ACKNOWLEDGMENTS CHANGELOG FAQ LICENSE README"
	fi

	RKHINST_MAN_FILES="${APPNAME}.8"

	return
}

# Additions we need to be aware / take care of:
# any /contrib/ files which should include any RH*L/alike ones:
# Additions we need to be aware / take care of wrt RH*L/alike:
# /etc/cron.daily/rkhunter (different versions of cronjob)
# /etc/sysconfig/rkhunter (config for cronjob)
# /etc/logrotate.d/rkhunter

showTemplate() { # Take input from the "--install parameter"
	case "$1" in
	custom_.)
		# Dump *everything* in the current dir.
		echo "Standalone installation into ${PWD}/files"
		;;
	*)
		NOTPRESENT="   (Directory will be created)"

		selectTemplate "$1"

		test -z "${PREFIX}" && RKHTMPVAR="/" || RKHTMPVAR="${PREFIX}"

		test ! -d "${RKHTMPVAR}" && RKHTMPVAR="${RKHTMPVAR}                            (Directory does not exist)"
		echo "Install into:       ${RKHTMPVAR}"

		RKHTMPVAR="${RKHINST_BIN_DIR}"
		test ! -d "${RKHTMPVAR}" && RKHTMPVAR="${RKHTMPVAR}                     ${NOTPRESENT}"
		echo "Application:        ${RKHTMPVAR}"

		RKHTMPVAR="${RKHINST_ETC_DIR}"
		test ! -d "${RKHTMPVAR}" && RKHTMPVAR="${RKHTMPVAR}                     ${NOTPRESENT}"
		if [ $OVERWRITE -eq 0 ]; then
			echo "Configuration file: ${RKHTMPVAR}"
		else
			if [ ! -d "${RKHTMPVAR}" ]; then
				echo "Configuration file: ${RKHTMPVAR}"
			else
				if [ -z "${PREFIX}" ]; then
					echo "Configuration file: ${RKHINST_ETC_DIR}               (Configuration file will be overwritten)"
				else
					echo "Configuration file: ${RKHINST_ETC_DIR}           (Configuration file will be overwritten)"
				fi
			fi
		fi

		RKHTMPVAR="${RKHINST_DOC_DIR}"
		test ! -d "${RKHTMPVAR}" && RKHTMPVAR="${RKHTMPVAR}${NOTPRESENT}"
		echo "Documents:          ${RKHTMPVAR}"

		RKHTMPVAR="${RKHINST_MAN_DIR}"
		test ! -d "${RKHTMPVAR}" && RKHTMPVAR="${RKHTMPVAR}          ${NOTPRESENT}"
		echo "Man page:           ${RKHTMPVAR}"

		RKHTMPVAR="${RKHINST_SCRIPT_DIR}"
		if [ ! -d "${RKHTMPVAR}" ]; then
			if [ -z "${PREFIX}" ]; then
				RKHTMPVAR="${RKHTMPVAR}      ${NOTPRESENT}"
			else
				RKHTMPVAR="${RKHTMPVAR}  ${NOTPRESENT}"
			fi
		fi
		echo "Scripts:            ${RKHTMPVAR}"

		RKHTMPVAR="${RKHINST_DB_DIR}"
		test ! -d "${RKHTMPVAR}" && RKHTMPVAR="${RKHTMPVAR}     ${NOTPRESENT}"
		echo "Databases:          ${RKHTMPVAR}"

		RKHTMPVAR="${RKHINST_SIG_DIR}"
		test ! -d "${RKHTMPVAR}" && RKHTMPVAR="${RKHTMPVAR}     ${NOTPRESENT}"
		echo "Signatures:         ${RKHTMPVAR}"

		RKHTMPVAR="${RKHINST_TMP_DIR}"
		test ! -d "${RKHTMPVAR}" && RKHTMPVAR="${RKHTMPVAR}    ${NOTPRESENT}"
		echo "Temporary files:    ${RKHTMPVAR}"

		if [ -n "${STRIPROOT}" ]; then
			echo ""; echo "Got STRIPROOT=\"${STRIPROOT}\""
		fi
		;;
	esac

	return
}


#################################################################################
#
# Start installation
#
#################################################################################

doInstall()  {
	DOING_UPDT=0

	# Preflight checks
	echo "Checking system for:"

	if [ -f "./files/${APPNAME}" ]; then
		echo " ${INSTALLER_NAME} files: found"

		case "${RKHINST_LAYOUT}" in
		RPM|DEB|TGZ|TXZ) 
			;;
		*)
			for ITEM in `find ./files`; do
				chown "${RKHINST_OWNER}" "${ITEM}"
			done
			;;
		esac
	else
		echo "Checking system for: ${INSTALLER_NAME} files: FAILED"
		echo "Installation files not in \"${PWD}/files\". Exiting."
		exit 1
	fi


	# We only look for one download command.

	for RKHWEBCMD in wget links elinks lynx curl GET bget; do
		SEARCH=`which ${RKHWEBCMD} 2>/dev/null | grep -v ' '`

		if [ -n "${SEARCH}" ]; then
			echo " A web file download command: ${RKHWEBCMD} found"
			break
		fi
	done

	if [ -z "${SEARCH}" ]; then
		echo " A web file download command: None found"
		echo ""
		echo "    Please install one of wget, links, elinks, lynx, curl, GET or"
		echo '    bget (from www.cpan.org/authors/id/E/EL/ELIJAH/bget)'
		echo ""
	fi


	# Perl will be found in rkhunter itself.

	RKHINST_DIRS="$RKHINST_DOC_DIR $RKHINST_MAN_DIR $RKHINST_ETC_DIR $RKHINST_BIN_DIR"
	RKHINST_DIRS_EXCEP="$RKHINST_SCRIPT_DIR $RKHINST_DB_DIR $RKHINST_TMP_DIR $RKHINST_LANG_DIR $RKHINST_SIG_DIR"

	if [ -f "${RKHINST_ETC_DIR}/rkhunter.conf" ]; then
		echo "Starting update:"
		DOING_UPDT=1
	else
		echo "Starting installation:"
	fi

	case "${RKHINST_LAYOUT}" in
	RPM|DEB|TGZ|TXZ)
		;;
	*) 
		# Check PREFIX
		if [ -z "${PREFIX}" ]; then
			:
		elif [ -d "${PREFIX}" ]; then
			if [ -w "${PREFIX}" ]; then
				echo " Checking installation directory \"$PREFIX\": it exists and is writable."

				# That's enough for a standalone installation.
				if [ "${PREFIX}" = "." ]; then
					chown -R ${RKHINST_OWNER} ./files 

					for ITEM in `find ./files -type f`; do
						case "${ITEM}" in
						*.sh|*.pl|*/rkhunter)
							chmod "${RKHINST_MODE_EX}" "${ITEM}"
							;;
						*)
							chmod "${RKHINST_MODE_RW}" "${ITEM}"
							;;
						esac
					done

					cd ./files

					PREFIX="${PWD}"

					echo "LOGFILE=${PREFIX}/rkhunter.log" >>rkhunter.conf 
					echo "TMPDIR=$PREFIX" >>rkhunter.conf 
					echo "DBDIR=$PREFIX" >>rkhunter.conf 
					echo "SCRIPTDIR=$PREFIX" >>rkhunter.conf 
					echo "INSTALLDIR=$PREFIX" >>rkhunter.conf
					echo "USER_FILEPROP_FILES_DIRS=$PREFIX/rkhunter" >>rkhunter.conf
					echo "USER_FILEPROP_FILES_DIRS=$PREFIX/rkhunter.conf" >>rkhunter.conf
					test -f "$PREFIX/rkhunter.conf.local" && echo "USER_FILEPROP_FILES_DIRS=$PREFIX/rkhunter.conf.local" >>rkhunter.conf
					test -d "$PREFIX/rkhunter.d" && echo "USER_FILEPROP_FILES_DIRS=$PREFIX/rkhunter.d/*.conf" >>rkhunter.conf

					sed -e "s|-f /etc/rkhunter.conf|-f $PREFIX/rkhunter.conf|g" -e "s|CONFIGFILE=\"/etc|CONFIGFILE=\"$PREFIX|g" rkhunter >rkhunter.
					mv -f rkhunter. rkhunter

					chmod "${RKHINST_MODE_EX}" rkhunter

					echo "Installation complete"

					exit 0
				fi
			else
				echo " Checking installation directory \"$PREFIX\": it exists, but it is not writable. Exiting."
				exit 1
			fi
		elif [ -e "${PREFIX}" ]; then
			echo " Checking installation directory \"$PREFIX\": it is not a directory. Exiting."
			exit 1
		else
			echo " Checking installation directory \"$PREFIX\": it does not exist. Exiting."
			exit 1
		fi
		;;
	esac # end Check PREFIX


	echo " Checking installation directories:"

	if [ "${RKHINST_LAYOUT}" = "oldschool" ]; then
		RKHDIR_LIST="${RKHINST_DIRS}"
	else
		RKHDIR_LIST="${RKHINST_DIRS} ${LIBDIR} ${VARDIR}/lib"
	fi

	umask 022
	for DIR in ${RKHDIR_LIST}; do
		if [ -d "${DIR}" ]; then
			if [ -w "${DIR}" ]; then
				echo "  Directory ${DIR}: exists and is writable."
			else
				echo "  Directory ${DIR}: exists, but it is not writable. Exiting."
				exit 1
			fi
		else
			mkdir -p ${DIR} >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo "  Directory ${DIR}: creating: OK"
			else
				echo "  Directory ${DIR}: creating: FAILED: Code $ERRCODE"
				exit 1
			fi
		fi
	done

	umask 077
	for DIR in ${RKHINST_DIRS_EXCEP}; do
		if [ -d "${DIR}" ]; then
			if [ -w "${DIR}" ]; then
				echo "  Directory ${DIR}: exists and is writable."
			else
				echo "  Directory ${DIR}: exists, but it is not writable. Exiting."
				exit 1
			fi
		else
			mkdir -p ${DIR} >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo "  Directory ${DIR}: creating: OK"
			else
				echo "  Directory ${DIR}: creating: FAILED: Code $ERRCODE"
				exit 1
			fi
		fi

		case "${DIR}" in
		*/${APPNAME}|*/${APPNAME}/*|*/${APPNAME}-${APPVERSION}) 
			chmod "${RKHINST_MODE_EX}" "${DIR}"
			;;
		esac
	done
	umask 027


	#
	# Now do the actual installation.
	#

	# Helper scripts, database and man page
	for FILE in ${RKHINST_SCRIPT_FILES} ${RKHINST_DB_FILES} ${RKHINST_MAN_FILES}; do
		case "${FILE}" in
		*.pl|*.sh)
			cp -f ./files/"${FILE}" "${RKHINST_SCRIPT_DIR}" >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_EX}" "${RKHINST_SCRIPT_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE"
				exit 1
			fi
			;;
		*.dat)
			if [ "${FILE}" = "mirrors.dat" -a -f "${RKHINST_DB_DIR}/mirrors.dat" ]; then
				RKHTMPVAR=`egrep '^(local|remote)=' ${RKHINST_DB_DIR}/mirrors.dat 2>/dev/null`

				if [ -n "${RKHTMPVAR}" ]; then
					echo " Installing ${FILE}: Locally modified - not overwritten"
					continue
				fi
			fi

			cp -f ./files/"${FILE}" "${RKHINST_DB_DIR}" >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_RW}" "${RKHINST_DB_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE"
				exit 1
			fi
			;;
		*.8)
			cp -f ./files/"${FILE}" "${RKHINST_MAN_DIR}" >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_RWR}" "${RKHINST_MAN_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE"
				exit 1
			fi
			;;
		esac
	done


	# Application documents
	for FILE in ${RKHINST_DOC_FILES}; do
		cp -f ./files/"${FILE}" "${RKHINST_DOC_DIR}" >/dev/null 2>&1
		ERRCODE=$?

		if [ $ERRCODE -eq 0 ]; then
			echo " Installing ${FILE}: OK"
			chmod "${RKHINST_MODE_RWR}" "${RKHINST_DOC_DIR}/${FILE}"
		else
			echo " Installing ${FILE}: FAILED: Code $ERRCODE"
			exit 1
		fi
	done


	# Language support files
	ERRCODE=0

	for FILE in `find ./files/i18n -type f`; do
		cp "${FILE}" "${RKHINST_LANG_DIR}" >/dev/null 2>&1
		ERRCODE=$?

		FNAME=`echo ${FILE} | sed 's|^./files/i18n/||'`

		if [ $ERRCODE -eq 0 ]; then
			chmod "${RKHINST_MODE_RW}" "${RKHINST_LANG_DIR}/${FNAME}"
		else
			echo " Installing ${FILE}: FAILED: Code $ERRCODE"
			break
		fi
	done

	if [ $ERRCODE -eq 0 ];then
		echo " Installing language support files: OK"
	else
		echo " Installing language support files: FAILED: Code $ERRCODE"
		exit 1
	fi


	# ClamAV signatures
	ERRCODE=0

	for FILE in `find ./files/signatures -type f`; do
		cp "${FILE}" "${RKHINST_SIG_DIR}" >/dev/null 2>&1
		ERRCODE=$?

		FNAME=`echo ${FILE} | sed 's|^./files/signatures/||'`

		if [ $ERRCODE -eq 0 ]; then
			chmod "${RKHINST_MODE_RW}" "${RKHINST_SIG_DIR}/${FNAME}"
		else
			echo " Installing ${FILE}: FAILED: Code $ERRCODE"
			break
		fi
	done

	if [ $ERRCODE -eq 0 ];then
		echo " Installing ClamAV signatures: OK"
	else
		echo " Installing ClamAV signatures: FAILED: Code $ERRCODE"
		exit 1
	fi

	# Application
	for FILE in ${RKHINST_BIN_FILES}; do
		case "${RKHINST_LAYOUT}" in
		RPM|DEB|TGZ|TXZ)	
			cp -f ./files/"${FILE}" "${RKHINST_BIN_DIR}/${FILE}" >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_EX}" "${RKHINST_BIN_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE"
				exit 1
			fi
			;;
		*)	
			sed -e "s|-f /etc/rkhunter.conf|-f $RKHINST_ETC_DIR/rkhunter.conf|g" -e "s|CONFIGFILE=\"/etc|CONFIGFILE=\"$RKHINST_ETC_DIR|g" ./files/"${FILE}" >"${RKHINST_BIN_DIR}/${FILE}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_EX}" "${RKHINST_BIN_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE"
				exit 1
			fi
			;;
		esac
	done


	# Configuration file
	for FILE in ${RKHINST_ETC_FILE}; do
		test $OVERWRITE -eq 1 && rm -f "${RKHINST_ETC_DIR}/${FILE}"

		if [ -f "${RKHINST_ETC_DIR}/${FILE}" ]; then
			# We need people to make local changes themselves, so
			# give opportunity and alert. Don't use Perl to get value.

			if [ -n "$RANDOM" ]; then
				RANDVAL=$RANDOM
			else
				RANDVAL=`date +%Y%m%d%H%M%S 2>/dev/null`

				if [ -z "${RANDVAL}" ]; then
					RANDVAL=$$
				fi
			fi

			NEWFILE="${FILE}.${RANDVAL}"

			cp -f "./files/${FILE}" "${RKHINST_ETC_DIR}/${NEWFILE}" >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE} in no-clobber mode: OK"
				chmod "${RKHINST_MODE_RW}" "${RKHINST_ETC_DIR}/${NEWFILE}"
			else
				echo " Installing ${FILE} in no-clobber mode: FAILED: Code $ERRCODE"
				exit 1
			fi

			echo "" >>"${RKHINST_ETC_DIR}/${NEWFILE}"

			test -z "${PREFIX}" && RKHTMPVAR="/" || RKHTMPVAR="${PREFIX}"

			echo "INSTALLDIR=${RKHTMPVAR}" >>"${RKHINST_ETC_DIR}/${NEWFILE}"
			echo "DBDIR=${RKHINST_DB_DIR}" >>"${RKHINST_ETC_DIR}/${NEWFILE}"
			echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" >>"${RKHINST_ETC_DIR}/${NEWFILE}"
			echo "TMPDIR=${RKHINST_TMP_DIR}" >>"${RKHINST_ETC_DIR}/${NEWFILE}"

			if [ "$FILE" = "rkhunter.conf" ]; then
				echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" >>"${RKHINST_ETC_DIR}/${NEWFILE}"

				if [ -f "${RKHINST_ETC_DIR}/${FILE}.local" ]; then
					echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}.local" >>"${RKHINST_ETC_DIR}/${NEWFILE}"
					chmod "${RKHINST_MODE_RW}" "${RKHINST_ETC_DIR}/${FILE}.local"
				fi

				if [ -d "${RKHINST_ETC_DIR}/rkhunter.d" ]; then
					echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/rkhunter.d/*.conf" >>"${RKHINST_ETC_DIR}/${NEWFILE}"
				fi
			fi

			case "${RKHINST_LAYOUT}" in
			RPM|DEB|TGZ|TXZ)
				;;
			*)
				echo " >>>"
				echo " >>> PLEASE NOTE: inspect for update changes in \"${RKHINST_ETC_DIR}/${NEWFILE}\","
				echo " >>> and apply to either \"${RKHINST_ETC_DIR}/${FILE}\" or your local configuration"
				echo " >>> file before running Rootkit Hunter."
				echo " >>>"
				;;
			esac
		else
			cp -f "./files/${FILE}" "${RKHINST_ETC_DIR}" >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_RW}" "${RKHINST_ETC_DIR}/${FILE}"

				if [ -f "${RKHINST_ETC_DIR}/${FILE}.local" ]; then
					chmod "${RKHINST_MODE_RW}" "${RKHINST_ETC_DIR}/${FILE}.local"
				fi
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE"
				exit 1
			fi

			echo "" >>"${RKHINST_ETC_DIR}/${FILE}"

			if [ -n "${RPM_BUILD_ROOT}" -a $RPM_USING_ROOT -eq 0 ]; then
				echo "INSTALLDIR=${PREFIX}" | sed "s|${RPM_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "DBDIR=${RKHINST_DB_DIR}" | sed "s|${RPM_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" | sed "s|${RPM_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "TMPDIR=${RKHINST_TMP_DIR}" | sed "s|${RPM_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" | sed "s|${RPM_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
			elif [ -n "${TGZ_BUILD_ROOT}" -a $TGZ_USING_ROOT -eq 0 ]; then
				echo "INSTALLDIR=${PREFIX}" | sed "s|${TGZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "DBDIR=${RKHINST_DB_DIR}" | sed "s|${TGZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" | sed "s|${TGZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "TMPDIR=${RKHINST_TMP_DIR}" | sed "s|${TGZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" | sed "s|${TGZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
			elif [ -n "${TXZ_BUILD_ROOT}" -a $TXZ_USING_ROOT -eq 0 ]; then
				echo "INSTALLDIR=${PREFIX}" | sed "s|${TXZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "DBDIR=${RKHINST_DB_DIR}" | sed "s|${TXZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" | sed "s|${TXZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "TMPDIR=${RKHINST_TMP_DIR}" | sed "s|${TXZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" | sed "s|${TXZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
			elif [ -n "${DEB_BUILD_ROOT}" ]; then
				# Debian builds are handled with a patch during the build process.
				:
			else
				test -z "${PREFIX}" && RKHTMPVAR="/" || RKHTMPVAR="${PREFIX}"

				echo "INSTALLDIR=${RKHTMPVAR}" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "DBDIR=${RKHINST_DB_DIR}" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "TMPDIR=${RKHINST_TMP_DIR}" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" >>"${RKHINST_ETC_DIR}/${FILE}"
			fi
		fi
	done


	# Strip root from fake root install.
	if [ -n "${STRIPROOT}" ]; then
		for FILE in `find "${PREFIX}" -type f`; do 
			STR=`grep "${PREFIX}" "${FILE}"`

			if [ -n "${STR}" ]; then
				sed -i "s|${STRIPROOT}||g" "${FILE}" >/dev/null 2>&1
				ERRCODE=$?

				if [ $ERRCODE -eq 0 ]; then
					echo " Striproot ${FILE}: OK"
				else
					echo " Striproot ${FILE}: FAILED: Code $ERRCODE"
					exit 1
				fi
			fi
		done
	fi


	# Finally copy the passwd/group files to the TMP directory
	# to avoid warnings when rkhunter is first run.

	case "${RKHINST_LAYOUT}" in
	RPM|DEB|TGZ|TXZ)	# This is done by a %post section in the spec file / postinst file.
		;;
	*)
		cp -p /etc/passwd ${RKHINST_TMP_DIR} >/dev/null 2>&1
		cp -p /etc/group ${RKHINST_TMP_DIR} >/dev/null 2>&1
		;;
	esac

	if [ $DOING_UPDT -eq 1 ]; then
		echo "Update complete"
	else
		echo "Installation complete"
	fi

	return
} # End doInstall


doRemove()  {
	RKHINST_DIRS="$RKHINST_ETC_DIR $RKHINST_BIN_DIR $RKHINST_SCRIPT_DIR $RKHINST_DOC_DIR $RKHINST_DB_DIR $RKHINST_TMP_DIR $RKHINST_LANG_DIR $RKHINST_SIG_DIR"

	echo "Starting uninstallation"
	echo ""

	# Check the PREFIX
	if [ -z "${PREFIX}" ]; then
		:
	elif [ -d "${PREFIX}" ]; then
		if [ -w "${PREFIX}" ]; then
			echo "Checking installation directory \"$PREFIX\": it exists and is writable."
		else
			echo "Checking installation directory \"$PREFIX\": it exists, but it is not writable. Exiting."
			exit 1
		fi
	elif [ -e "${PREFIX}" ]; then
		echo "Checking installation directory \"$PREFIX\": it exists but it is not a directory. Exiting."
		exit 1
	else
		echo "Checking installation directory \"$PREFIX\": it does not exist. Exiting."
		exit 1
	fi


	# Standalone removal involves just deleting the 'files' subdirectory.
	if [ "$PREFIX" = "." ]; then
		rm -rf ./files >/dev/null 2>&1
		ERRCODE=$?

		if [ $ERRCODE -eq 0 ]; then
			echo "Uninstallation complete"
		else
			echo "Uninstallation FAILED: Code $ERRCODE"
		fi

		return
	fi


	echo "Removing installation files:"

	# Man page
	for FILE in ${RKHINST_MAN_FILES}; do
		if [ -f "${RKHINST_MAN_DIR}/${FILE}" ]; then
			rm -f "${RKHINST_MAN_DIR}/${FILE}" >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Removing ${FILE}: OK"
			else
				echo " Removing ${FILE}: FAILED: Code $ERRCODE"
			fi
		fi
	done


	# Application
	for FILE in ${RKHINST_BIN_FILES}; do
		if [ -f "${RKHINST_BIN_DIR}/${FILE}" ]; then
			rm -f "${RKHINST_BIN_DIR}/${FILE}" >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Removing ${RKHINST_BIN_DIR}/${FILE}: OK"
			else
				echo " Removing ${RKHINST_BIN_DIR}/${FILE}: FAILED: Code $ERRCODE"
			fi
		fi
	done


	# Configuration file
	for FILE in ${RKHINST_ETC_FILE}; do
		if [ -f "${RKHINST_ETC_DIR}/${FILE}" ]; then
			rm -f "${RKHINST_ETC_DIR}/${FILE}" >/dev/null 2>&1
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Removing ${RKHINST_ETC_DIR}/${FILE}: OK"
			else
				echo " Removing ${RKHINST_ETC_DIR}/${FILE}: FAILED: Code $ERRCODE"
			fi
		fi

		echo ""
		echo "Please remove any ${RKHINST_ETC_DIR}/${FILE}.* files manually."
		echo ""

		if [ -d "${RKHINST_ETC_DIR}/${FILE}.d" ]; then
			echo ""
			echo "Please remove any ${RKHINST_ETC_DIR}/${FILE}.d directory manually."
			echo ""
		fi
	done


	# Helper scripts: remove dir
	# Application documents: remove dir
	# Databases: remove dir
	# Language support: remove dir

	echo "Removing installation directories:"

	for DIR in ${RKHINST_DIRS}; do
		case "${DIR}" in 
		*/${APPNAME}) 
			if [ -d "${DIR}" ]; then
				rm -rf "${DIR}" >/dev/null 2>&1
				ERRCODE=$?

				if [ $ERRCODE -eq 0 ]; then
					echo " Removing ${DIR}: OK"
				else
					echo " Removing ${DIR}: FAILED: Code $ERRCODE"
				fi
			fi
			;;
		*/${APPNAME}-${APPVERSION}) 
			# Anything involving a specific version number
			# needs to remove all old versions as well.
			DIR=`dirname "${DIR}"`

			for RKHAPPDIR in ${DIR}/${APPNAME}-*; do
				if [ -d "${RKHAPPDIR}" ]; then
					rm -rf "${RKHAPPDIR}" >/dev/null 2>&1
					ERRCODE=$?

					if [ $ERRCODE -eq 0 ]; then
						echo " Removing ${RKHAPPDIR}: OK"
					else
						echo " Removing ${RKHAPPDIR}: FAILED: Code $ERRCODE"
					fi
				fi
			done
			;;
		*/${APPNAME}/*)
			DIR=`dirname "${DIR}"`

			if [ -d "${DIR}" ]; then
				rm -rf "${DIR}" >/dev/null 2>&1
				ERRCODE=$?

				if [ $ERRCODE -eq 0 ]; then
					echo " Removing ${DIR}: OK"
				else
					echo " Removing ${DIR}: FAILED: Code $ERRCODE"
				fi
			fi
			;;
		esac
	done


	# Could use patch for removing custom $VARDIR $SHAREDIR $PREFIX here.

	if [ "${RKHINST_LAYOUT}" = "oldschool" ]; then
		if [ -d "/usr/local/rkhunter" ]; then
			echo ""
			echo "Note: The directory '/usr/local/rkhunter' still exists."
		fi
	fi


	# Remove any old log files.
	rm -f /var/log/rkhunter.log /var/log/rkhunter.log.old >/dev/null 2>&1

	echo ""
	echo "Finished removing files. Please double-check."

	return
} # end doRemove


#
# Start of the installer
#

if [ $# -eq 0 ]; then
	showHelp
	exit 1
fi

while [ $# -ge 1 ]; do
	case "$1" in
	h | -h | --help | --usage)
		showHelp
		exit 1
		;;
	-e | --examples)
		showExamples
		exit 1
		;;
	-v | --version)
		showVersion
		exit 1
		;;
	-l | --layout)
		shift 1

		case "$1" in
		custom)
			shift 1
			if [ -n "$1" ]; then
				RKHINST_LAYOUT="custom_$1"
			else
				echo "No custom layout given. Exiting."
				exit 1
			fi
			;;
		default|oldschool|/usr|/usr/local|RPM|DEB|TGZ|TXZ)
			RKHINST_LAYOUT="$1"
			;;
		*)
			echo "Unknown layout given: $1"
			exit 1
			;;
		esac
		;;
	-s | --striproot)
		shift 1

		if [ -n "$1" ]; then
			STRIPROOT="$1"
		else
			echo "Striproot requested but no directory name given. Exiting."
			exit 1
		fi
		;;
	--show | --remove | --install | --uninstall)
		RKHINST_ACTION_SEEN=1
		RKHINST_ACTION=`echo "$1" | sed 's/-//g'`
		;;
	-o | --overwrite)
		OVERWRITE=1
		;;
	*)
		echo "Unknown option given: $1"
		echo ""

		showHelp
		exit 1
		;;
	esac

	shift
done

# We only get here when some installation action was to be taken.
if [ $RKHINST_ACTION_SEEN -eq 0 ]; then
	echo "No action given. Exiting."
else
	case "${RKHINST_ACTION}" in
	show)
		showTemplate $RKHINST_LAYOUT
		;;
	remove | uninstall)	# Clean active window
		selectTemplate $RKHINST_LAYOUT
		clear
		doRemove
		;;
	install) # Clean active window
		selectTemplate $RKHINST_LAYOUT
		clear
		doInstall
		;;
	esac
fi

exit 0
