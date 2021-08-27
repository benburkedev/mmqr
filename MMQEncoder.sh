#!/bin/bash
# Demonstrate the proposed MMQ protocol to ship arbitrary amounts of data through
# a set of linked QRCodes
TMPDIR=$(mktemp -d)     # used for output of 'split'... contents are input for qrencode
TMPFILE=$(mktemp)
TMPJSON=$(mktemp)
UUID=1b21960-d3ba-11eb-b8bc-0242ac13000
CYCLE_DELTA_SECONDS=60
CYCLE_MILLISECONDS=200
BLOCK_SIZE=512
QRENCODE_FLAGS="-l H -v 1"
IMAGE_CYCLE=3

while getopts "hb:m:d:q:i:" opt; do
	case $opt in
		m )	echo "milliseconds = $OPTARG" 
			CYCLE_MILLISECONDS="$OPTARG"
			;;
		d )	echo "delta = $OPTARG" 
			CYCLE_DELTA_SECONDS="$OPTARG"
			;;
        b )	echo "block size is = $OPTARG" 
			BLOCK_SIZE="$OPTARG"
			;;
        q )	echo "qrencode flags = $OPTARG" 
			QRENCODE_FLAGS="$OPTARG"
			;;
        i )	echo "image cycle = $OPTARG" 
			IMAGE_CYCLE="$OPTARG"
			;;

		h | *)	
            echo "usage - $basename($0) -m milliseconds -d delta -b blocksize"
			exit 1
            ;;
	esac
done


k=$(( 1000 / $CYCLE_MILLISECONDS))
k=$(( $k * $CYCLE_DELTA_SECONDS))

echo "Emulating for $CYCLE_DELTA_SECONDS seconds at $CYCLE_MILLISECONDS millisecond intervals producing $k samples" 
echo "Block Size is $BLOCK_SIZE"

# generate $k samples of pseudo-random integers 0-65536

for ((j=1;j<=k;j++)); do
        echo -n $(shuf -i 1-65335 -n 1)"," >> "$TMPFILE"
done

# keep the temp file for later comparison, rather than doing this all in one pipe

(cd $TMPDIR; cat $TMPFILE | base64 | split -C $BLOCK_SIZE)

#ls $TMPDIR

sequenceTotal=$(find $TMPDIR -maxdepth 1 -type f -name 'x*' | wc -l)

counter=1

function hereJson  {
STUFF=$(<$1)
cat <<EOF > "$TMPJSON"
{
  "mmq": "true",
  "UUID": "$UUID",
  "sequenceNumber": "$counter",
  "sequenceTotal": "$sequenceTotal",
  "cycleMilliseconds": "$CYCLE_MILLISECONDS",
  "cycleDeltaSeconds": "$CYCLE_DELTA_SECONDS",
  "payload": "$STUFF"
}
EOF

echo "Message content being encoded"

cat $TMPJSON

qrencode $QRENCODE_FLAGS -r $TMPJSON -o $TMPDIR/$( basename $1 ).png

}

counter=1


for f in $TMPDIR/* ;do 
    echo "encoding $f"
    hereJson "$f"
    ((counter++))

done 

ls $TMPDIR -al 
# replace feh with your preferred image viewing software to view the generated codes
if ( command -v feh &> /dev/null ) ; then
    feh -D 2 $TMPDIR/*.png -D $IMAGE_CYCLE -F
fi