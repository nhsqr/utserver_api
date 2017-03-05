#!/bin/bash

# ----------------------------------- #
#Modify the next 5 lines for your situation
UTORRENTURL="http://YourIPaddress:port/gui/"
USERNAME="username"
PASSWORD="password"
CURL="/usr/bin/curl"
TEMPFILE="/tmp/utserver_api.tmp"
# ----------------------------------- #

# First authenticate and get session cookie
TOKEN=`${CURL} -u ${USERNAME}:${PASSWORD} -G -s -c cookie.txt -n ${UTORRENTURL}token.html | sed 's/<[^<>]*>//g'`
${CURL} -u ${USERNAME}:${PASSWORD} -G -s -n -b cookie.txt -d token=${TOKEN} -d list=1 ${UTORRENTURL} > ${TEMPFILE}

#Third parameter is always INDEX
index=$3

#gethash index (return hash)
function gethash {
	getoption 1 $1 ret
	eval "$2=$ret"
}

#getoption option index (return string | integer)
function getoption {
	eval "$3=`cat ${TEMPFILE} | awk -F',' 'NF > 20' | grep -Po '(?<=\[).*(?=\])' | cut -d',' -f$1 | awk "NR==$2"`"
}

function usage {
	echo -e "\nUsage:\t$(basename $0) --get [OPTION1] [INDEX]\n\t$(basename $0) -g [OPTION1] [INDEX]"
	echo -e "Usage:\t$(basename $0) --set [OPTION2] [INDEX]\n\t$(basename $0) -s [OPTION2] [INDEX]\n"
	echo -e "INDEX:"
	echo -e "\tIndex of the torrent file or [all]"
	echo -e "\tExample:"
	echo -e "\t\t$(basename $0) --get name all"
	echo -e "\t\t$(basename $0) --get name 5"
	echo -e "\tRemark:"
	echo -e "\t\t'all' can only be used with --get"
	echo -e "OPTION1:"
	echo -e "\thash 		- torrent hash"
	echo -e "\tstatusint	- status in integer value"
	echo -e "\tname 		- torrent name"
	echo -e "\tsize 		- torrent size"
	echo -e "\tpercent		- % completed multiplied by 10"
	echo -e "\tdownloaded	- downloaded size in bytes"
	echo -e "\tuploaded 	- uploaded size in bytes"
	echo -e "\tratio		- ratio multiplied by 1000"
	echo -e "\tupspeed		- current upload speed in bytes"
	echo -e "\tdownspeed	- current download speed in bytes"
	echo -e "\teta		- torrent ETA"
	echo -e "\tlabel		- torrent LABEL"
	echo -e "\tpeercon		- connected peers"
	echo -e "\tpeerswarm	- peers in swarm"
	echo -e "\tseedcon		- connected seeders"
	echo -e "\tseedswarm	- seeders in swarm"
	echo -e "\tabailability	- integer in 1/65536ths"
	echo -e "\tqueue		- torrent queue order"
	echo -e "\tremaining	- remaining size in bytes"
	echo -e "\tstatus		- current status of the torrent"
	echo -e "\tfolder		- folder of downloaded torrent"
	echo -e "\nOPTION2:"
	echo -e "\tstart 		- start torrent"
	echo -e "\tstop		- stop torrent"
	echo -e "\tpause 		- pause torrent"
	echo -e "\tunpause 	- unpause torrent"
	echo -e "\tforcestart	- force start of torrent"
	echo -e "\trecheck		- recheck torrent"
	echo -e "\tremove	 	- remove torrent"
	echo -e "\tremovedata	- remove torrent and data"
	echo -e "\tqueuebottom	- move torrent to the bottom of the queue"
	echo -e "\tqueuedown	- move torrent one queue position down"
	echo -e "\tqueuetop	- move torrent to the top of the queue"
	echo -e "\tqueueup		- move torrent one queue position up"
}
case "$1" in
--get | -g )
	case "$2" in
	"hash")
		option="1"
		;;
	"statusint")
	    option="2"
		;;
	"name")
		option="3"
		;;
	"size")
	    option="4"
		;;
	"percent")
		option="5"
		;;
	"downloaded")
	    option="6"
		;;
	"uploaded")
	    option="7"
		;;
	"ratio")
	    option="8"
		;;
	"upspeed")
	    option="9"
		;;
	"downspeed")
	    option="10"
		;;
	"eta")
	    option="11"
		;;
	"label")
	    option="12"
		;;
	"peercon")
	    option="13"
		;;
	"peerswarm")
	    option="14"
		;;
	"seedcon")
	    option="15"
	    ;;
	"seedswarm")
	    option="16"
	    ;;
	"availability")
	    option="17"
	    ;;
	"queue")
	    option="18"
	    ;;
	"remaining")
	    option="19"
	    ;;
	"status")
	    option="22"
	    ;;
	"folder")
	    option="27"
		;;
	*)
		usage
		exit 0
		;;
	esac
	if [ -z "$index" ]
	then
		echo "You need to supply index of the torrent"
	    echo "----------------------------------------------------------------------------------------"
		usage
		rm ${TEMPFILE} cookie.txt
		exit 0
	elif [ "$index" = "all" ]
	then
		#cat ${TEMPFILE} | head -n -6 | tail -n +3 | tr -cd '[:alnum:]''[=,=]''[=.=]''[=-=]''[:space:]' | cut -d',' -f3 | nl
		#cat ${TEMPFILE} | awk -F[\[] '{print $2}' | awk -F[\]] '{print $1$2}' | awk -F',' 'NF > 20' | cut -d',' -f3 | nl
		#cat ${TEMPFILE} | awk -F[\[] '{if  ($3 == "") print $2; else print $2"["$3;}' | awk -F[\]] '{if ($2 == "," || $2 == "") print $1; else print $1"]"$2}' | awk -F',' 'NF > 20' | cut -d',' -f3 | nl
		#cat ${TEMPFILE} | awk -F',' 'NF > 20' | grep -Po '(?<=\[).*(?=\])' | cut -d',' -f3 | nl
		cat ${TEMPFILE} | awk -F',' 'NF > 20' | grep -Po '(?<=\[).*(?=\])' | cut -d',' -f$option | nl
	else
		getoption $option $index ret
		echo "$ret"
		#cat ${TEMPFILE} | awk -F',' 'NF > 20' | grep -Po '(?<=\[).*(?=\])' | cut -d',' -f$option | awk "NR==$index"
		#cat ${TEMPFILE} | awk -F[\[] '{if  ($3 == "") print $2; else print $2"["$3;}' | awk -F[\]] '{if ($2 == "," || $2 == "") print $1; else print $1"]"$2}' | awk -F',' 'NF > 20' | cut -d',' -f$option | awk "NR==$index"
		#cat ${TEMPFILE} | awk -F[\[] '{print $2}' | awk -F[\]] '{print $1$2}' | awk -F',' 'NF > 20' | cut -d',' -f$option | awk "NR==$index"
		#cat ${TEMPFILE} | head -n -5 | tail -n +3 | awk "NR==$index" | cut -d'[' -f2 | cut -d']' -f1 | cut -d',' -f$option
		#cat ${TEMPFILE} | head -n -5 | tail -n +3 | tr -cd '[:alnum:]''[=,=]''[=.=]''[=-=]''[:space:]' | cut -d',' -f$option | awk "NR==$index"
	fi
	;;
--set | -s )
	gethash $index torrenthash
	${CURL} -u ${USERNAME}:${PASSWORD} -G -s -n -b cookie.txt -d token=${TOKEN} -d action=$2 -d hash=$torrenthash ${UTORRENTURL} > /dev/null
	if [ $? -gt 0 ]
	then
		echo "Error sending request to server. Check settings."
	else
		getoption 3 $index ret
		echo "Torrent $2 success: $ret"
	fi
	;;
--help | -h )
	usage
	;;
*)
	echo "Try: $(basename $0) --help"
	;;
esac
rm ${TEMPFILE} cookie.txt