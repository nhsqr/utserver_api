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
        trackers        - list of trackers
        ulrate          - upload rate (integer in bytes per second)
        dlrate          - download rate (integer in bytes per second)
        superseed       - superseed (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)
        dht             - use DHT (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)
        pex             - use peer exchange (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)
        seed_override   - override seed queueing (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)
        seed_ratio      - seed ratio before stopping the torrent (integer in per mils; 0 = ignore)
        seed_time       - seed time in seconds before stopping the torrent; 0 = ignore
        ulslots         - upload slots (integer)

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
        label=LABEL             - set torrent label to value LABEL
        ulrate=INTEGER          - set upload rate to value INTEGER (integer in bytes per second)
        dlrate=INTEGER          - set download rate to value INTEGER (integer in bytes per second)
        superseed=INTEGER       - set superseed to value INTEGER (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)
        seed_override=INTEGER   - set override seed queueing to value INTEGER (integer: -1 = Not allowed; 0 = Disabled; 1 = Enabled)
        seed_ratio=INTEGER      - set seed ratio before stopping the torrent to value INTEGER (integer in per mils; 0 = ignore)
        seed_time=INTEGER       - set seed time in seconds before stopping the torrent to value INTEGER; 0 = ignore
        ulslots=INTEGER         - set upload slots to value INTEGER (integer)

	
The initial source for this script was from: https://myrveln.se/remove-finished-torrents-using-utorrents-api/
