#!/bin/bash -e

## Put your sane-detected device name here.
DEVICE="snapscan"

## For network scanners use
#DEVICE="net:sane.example.org:snapscan"

if [ "$1" = "" ]; then
        echo "Usage: $0 <output-file-name.pdf>"
        exit 1
fi

OUTFILE=$1

TMPDIR=$(mktemp -d)

echo "Temporary files kept in: ${TMPDIR}"

cd ${TMPDIR}

SCANIMAGE_OPTS="--device ${DEVICE} --mode Gray --resolution 150 --brightness 20 --contrast 20 -x 210 -y 290"
scanimage ${SCANIMAGE_OPTS} --progress --verbose --batch  --batch-prompt --format=tiff

tiffcp -c lzw out*.tif scan.tiff

cd -

tiff2pdf -z ${TMPDIR}/scan.tiff > ${OUTFILE}

ls -l ${OUTFILE}

if [ -z "${KEEP_TMP}" ]; then
        rm -rf ${TEMPDIR}
else
        echo "Temporary files are in ${TEMPDIR}"
fi