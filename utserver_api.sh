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

#Check if all parameters are supplied
if [ $1 != "--help" ]
then
	if [ -z $2 ] || [ -z $3 ]
	then
		echo "Not all parameters are supplied. Try: $(basename $0) --help"
		rm ${TEMPFILE} cookie.txt
		exit 0
	fi
fi

#Third parameter is always INDEX
index=$3

#gethash index (return hash)
function gethash {
	echo `getoption 1 $1`
}

#getoption option index (return string | integer)
function getoption {
	echo `cat ${TEMPFILE} | awk -F',' 'NF > 20' | grep -Po '(?<=\[).*(?=\])' | cut -d',' -f$1 | awk "NR==$2"`
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
	echo -e "\ttrackers	- list of trackers"
	echo -e "\tulrate		- upload rate (integer in bytes per second)"
	echo -e "\tdlrate		- download rate (integer in bytes per second)"
	echo -e "\tsuperseed	- superseed (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)"
	echo -e "\tdht		- use DHT (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)"
	echo -e "\tpex		- use peer exchange (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)"
	echo -e "\tseed_override	- override seed queueing (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)"
	echo -e "\tseed_ratio	- seed ratio before stopping the torrent (integer in per mils; 0 = ignore)"
	echo -e "\tseed_time	- seed time in seconds before stopping the torrent; 0 = ignore"
	echo -e "\tulslots		- upload slots (integer)"
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
	echo -e "\tlabel=LABEL		- set torrent label to value LABEL"
	echo -e "\tulrate=INTEGER		- set upload rate to value INTEGER (integer in bytes per second)"
	echo -e "\tdlrate=INTEGER		- set download rate to value INTEGER (integer in bytes per second)"
	echo -e "\tsuperseed=INTEGER	- set superseed to value INTEGER (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)"
	echo -e "\tseed_override=INTEGER	- set override seed queueing to value INTEGER (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)"
	echo -e "\tseed_ratio=INTEGER	- set seed ratio before stopping the torrent to value INTEGER (integer in per mils; 0 = ignore)"
	echo -e "\tseed_time=INTEGER	- set seed time in seconds before stopping the torrent to value INTEGER; 0 = ignore"
	echo -e "\tulslots=INTEGER		- set upload slots to value INTEGER (integer)"
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
	"trackers" | "ulrate" | "dlrate" | "superseed" | "dht" | "pex" | "seed_override" | "seed_ratio" | "seed_time" | "ulslots" | "seed_num")
		torrenthash=`gethash $index | cut -d'"' -f2`
		props=`${CURL} -u ${USERNAME}:${PASSWORD} -G -s -n -b cookie.txt -d token=${TOKEN} -d action=getprops -d hash=$torrenthash ${UTORRENTURL}`
		echo -e `echo "$porps" | grep "$2" | awk -F': ' '{print $2}' | cut -d'"' -f2`
		rm ${TEMPFILE} cookie.txt
		exit 0
		;;
	*)
		usage
		rm ${TEMPFILE} cookie.txt
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
		cat ${TEMPFILE} | awk -F',' 'NF > 20' | grep -Po '(?<=\[).*(?=\])' | cut -d',' -f$option | nl
	else
		echo `getoption $option $index`
	fi
	;;
--set | -s )
	property=`echo $2 | cut -d'=' -f1`
	value=`echo $2 | cut -d'=' -f2`
	torrenthash=`gethash $index | cut -d'"' -f2`
	case "$property" in
	"start" | "stop" | "pause" | "unpause" | "forcestart" | "recheck" | "remove" | "removedata" | "queuebottom" | "queuedown" | "queuetop" | "queueup" )
		${CURL} -u ${USERNAME}:${PASSWORD} -G -s -n -b cookie.txt -d token=${TOKEN} -d action=$2 -d hash=$torrenthash ${UTORRENTURL} > /dev/null
		if [ $? -gt 0 ]
		then
			echo "Error sending request to server. Check settings."
		else
			echo "Torrent $2 success: `getoption 3 $index`"
		fi
		;;
	"label" | "ulrate" | "dlrate" | "superseed" | "seed_override" | "seed_ratio" | "seed_time" | "ulslots" )
		${CURL} -u ${USERNAME}:${PASSWORD} -G -s -n -b cookie.txt -d token=${TOKEN} -d action=setprops -d hash=$torrenthash -d s=$property -d v=$value ${UTORRENTURL} > /dev/null
		if [ $? -gt 0 ]
		then
			echo "Error ($?) sending request to server. Check settings."
		else
			echo "Torrent setting $property=$value success: `getoption 3 $index`"
		fi
		;;
	* )
		echo -e "Invalid request: $property\nTry: $(basename $0) --help"
		;;
	esac
	;;
--help | -h )
	usage
	;;
*)
	echo "Try: $(basename $0) --help"
	;;
esac
rm ${TEMPFILE} cookie.txt
