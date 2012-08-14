#!/bin/bash -e

## Put your sane-detected device name here.
#DEVICE="snapscan"
DEVICE='brother4:net1;dev0'

## For network scanners use
#DEVICE="net:sane.example.org:snapscan"

## See scanimage --device $(DEVICE) --help
#SOURCE="FlatBed"
SOURCE="Automatic Document Feeder(centrally aligned)"
#SOURCE="Automatic Document Feeder(centrally aligned,Duplex)"

#SCANIMAGE_OPTS=' --resolution 150 --brightness 20 --contrast 20 -l 0 -t 0 -x 210 -y 290'
SCANIMAGE_OPTS=' --resolution 150 -l 0 -t 0 -x 210 -y 290'

if [ "$1" = "" ]; then
        echo "Usage: $0 <output-file-name.pdf>"
        exit 1
fi

OUTFILE=$1

TMPDIR=$(mktemp -d)

echo "Temporary files kept in: ${TMPDIR}"

cd ${TMPDIR}

set +e
scanimage --device ${DEVICE} ${SCANIMAGE_OPTS} --source="${SOURCE}" --mode="True Gray" --progress --verbose --format=tiff --batch  # --batch-prompt
set -e
ls -1 out*.tif > /dev/null

tiffcp -c lzw out*.tif scan.tiff

cd -

tiff2pdf -z ${TMPDIR}/scan.tiff > ${OUTFILE}

ls -l ${OUTFILE}

if [ -z "${KEEP_TMP}" ]; then
        rm -rf ${TEMPDIR}
else
        echo "Temporary files are in ${TEMPDIR}"
fi
