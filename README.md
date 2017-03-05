# utserver_api
Bash script for uTorrent Server WebAPI

Do not forget to modify first five lines of the script for your uTorrent Server

Usage:  

		utserver_api.sh --get [OPTION1] [INDEX]
		utserver_api.sh -g [OPTION1] [INDEX]
        			
		utserver_api.sh --set [OPTION2] [INDEX]
		utserver_api.sh -s [OPTION2] [INDEX]

INDEX:

        Index of the torrent file or [all]
        Example:
                utserver_api.sh --get name all
                utserver_api.sh --get name 5
        Remark:
                'all' can only be used with --get
                
OPTION1:

        hash            - torrent hash
        statusint       - status in integer value
        name            - torrent name
        size            - torrent size
        percent         - % completed multiplied by 10
        downloaded      - downloaded size in bytes
        uploaded        - uploaded size in bytes
        ratio           - ratio multiplied by 1000
        upspeed         - current upload speed in bytes
        downspeed       - current download speed in bytes
        eta             - torrent ETA
        label           - torrent LABEL
        peercon         - connected peers
        peerswarm       - peers in swarm
        seedcon         - connected seeders
        seedswarm       - seeders in swarm
        abailability    - integer in 1/65536ths
        queue           - torrent queue order
        remaining       - remaining size in bytes
        status          - current status of the torrent
        folder          - folder of downloaded torrent

OPTION2:

        start           - start torrent
        stop            - stop torrent
        pause           - pause torrent
        unpause         - unpause torrent
        forcestart      - force start of torrent
        recheck         - recheck torrent
        remove          - remove torrent
        removedata      - remove torrent and data
        queuebottom     - move torrent to the bottom of the queue
        queuedown       - move torrent one queue position down
        queuetop        - move torrent to the top of the queue
        queueup         - move torrent one queue position up
