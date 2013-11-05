#!/bin/bash -e

## Put your sane-detected device name here.
#DEVICE="snapscan"
## For network scanners use
#DEVICE="net:sane.example.org:snapscan"
DEVICE='brother4:net1;dev0'

## See scanimage --device $(DEVICE) --help
SOURCES[0]="FlatBed"
SOURCES[1]="Automatic Document Feeder(left aligned)"
SOURCES[2]="Automatic Document Feeder(left aligned,Duplex)"
SOURCES[3]="Automatic Document Feeder(centrally aligned)"
SOURCES[4]="Automatic Document Feeder(centrally aligned,Duplex)"
SOURCE=${SOURCES[3]} # Default

RESOLUTIONS=(100 150 200 300 400 600 1200 2400 4800 9600)
RESOLUTION=150	# Default

MODES[0]="Black & White"
MODES[1]="Gray[Error Diffusion]"
MODES[2]="True Gray"
MODES[3]="24bit Color"
MODES[4]="24bit Color[Fast]"
MODE=${MODES[2]}	# Default

QUALITIES=(70 80 90 100)
QUALITY=80	# Default

function process_option()
{
	declare -a ARRAY=("${!1}"); shift
	VALUE=$1; shift
	DEFAULT=$1; shift
	MESSAGE=$1; shift
	if in_array ARRAY[@] "${VALUE}"; then
		echo ${VALUE}
		exit 0
	fi
	if [ ${VALUE} -lt 0 -o ${VALUE} -ge ${#ARRAY[@]} ]; then
		echo "$0: ${MESSAGE}"
		list_array ARRAY[@] "$DEFAULT" "  "
		exit 1
	fi >&2
	echo ${ARRAY[${VALUE}]}
}

function in_array()
{
	declare -a ARRAY=("${!1}"); shift
	VALUE=$1; shift
	for i in ${!ARRAY[@]}; do
		test "${ARRAY[$i]}" = "${VALUE}" && return 0
	done
	return 1
}

function list_array()
{
	declare -a ARRAY=("${!1}"); shift
	DEFAULT=$1; shift
        PREFIX=$1; shift
	for i in ${!ARRAY[@]}; do
		MARK_DEFAULT=" "
		test "${ARRAY[$i]}" = "${DEFAULT}" && MARK_DEFAULT="*"
		echo "${PREFIX}${MARK_DEFAULT} [$i]  ${ARRAY[$i]}"
	done
}

function print_current_options()
{
	echo -e "\e[1mCurrent scanning options:\e[0m"
	echo -e "\e[33mMODE:    \e[1m${MODE}\e[0m"
	echo -e "\e[33mDPI:     \e[1m${RESOLUTION}\e[0m"
	echo -e "\e[33mSOURCE:  \e[1m${SOURCE}\e[0m"
	echo -e "\e[33mQUALITY: \e[1m${QUALITY}\e[0m"
	echo -e "\e[33mOUTFILE: \e[1m${OUTFILE}\e[0m"
}

function usage()
{
        echo -e "Usage: \e[1;32m$(basename $0)\e[0m \e[1m[-m MODE] [-d DPI] [-s SOURCE] [-k] [-h]\e[33m -o OUTFILE\e[0m"
        echo
        echo -e "    \e[1m-m MODE\e[0m     Colour mode"
	list_array MODES[@] "${MODE}" "              "
        echo
        echo -e "    \e[1m-d DPI\e[0m      Resolution"
	list_array RESOLUTIONS[@] "${RESOLUTION}" "              "
        echo
        echo -e "    \e[1m-s SOURCE\e[0m   Source"
	list_array SOURCES[@] "${SOURCE}" "              "
        echo
        echo -e "    \e[1m-q QUALITY\e[0m  Quality"
	list_array QUALITIES[@] "${QUALITY}" "              "
        echo
	print_current_options
	exit 1
}

while getopts m:s:r:d:q:o:kh OPTION
do
	case ${OPTION} in
		m)
			MODE=$(process_option MODES[@] "${OPTARG}" "${MODE}" "invalid mode, valid values for -m are:")
			test $? -gt 0 && exit 1
			;;
		r|d)
			RESOLUTION=$(process_option RESOLUTIONS[@] "${OPTARG}" "${RESOLUTION}" "invalid resolution, valid values for -r are:")
			test $? -gt 0 && exit 1
			;;
		s)
			SOURCE=$(process_option SOURCES[@] "${OPTARG}" "${SOURCE}" "invalid source, valid values for -s are:")
			test $? -gt 0 && exit 1
			;;
		q)
			QUALITY=$(process_option QUALITIES[@] "${OPTARG}" "${QUALITY}" "invalid JPG quality, valid values for -q are:")
			test $? -gt 0 && exit 1
			;;
		o)
			OUTFILE=${OPTARG}
			;;
		k)
			KEEP_TMP=1
			;;
		h|?)
			usage
			exit 2
	esac
done

test -z "${OUTFILE}" && usage

print_current_options

#SCANIMAGE_OPTS=' --resolution 150 --brightness 20 --contrast 20 -l 0 -t 0 -x 210 -y 290'
SCANIMAGE_OPTS=' -l 0 -t 0 -x 210 -y 290'

TMPDIR=$(mktemp -d /tmp/scan2pdf.XXXXXXX)

echo "Temporary files kept in: ${TMPDIR}"

cd ${TMPDIR}

set +e
scanimage --device ${DEVICE} ${SCANIMAGE_OPTS} --resolution ${RESOLUTION} --source="${SOURCE}" --mode="${MODE}" --progress --verbose --format=tiff --batch=out%03d.tif  # --batch-prompt
set -e
ls -1 out*.tif > /dev/null

cd -

# Use TIFF tools
#tiffcp -c lzw ${TMPDIR}/out*.tif ${TMPDIR}/scan.tiff
#tiff2pdf -z ${TMPDIR}/scan.tiff > ${OUTFILE}

# Use ImageMagick
convert ${TMPDIR}/out*.tif -compress jpeg -quality ${QUALITY} ${OUTFILE}

ls -l ${OUTFILE}

if [ -z "${KEEP_TMP}" ]; then
        rm -rf ${TEMPDIR}
else
        echo "Temporary files are in ${TEMPDIR}"
fi
