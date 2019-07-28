#!/bin/sh

NGSPICEDIR=../ngspice
XSPICEDIR="${NGSPICEDIR}/src/xspice/icm/xtradev/"

#
#
#
if [ ! -d ${XSPICEDIR} ]; then
  echo "Directory ${XSPICEDIR} does not exist. There is a problem with your installation! Cannot continue!"
  exit 1
fi

FILE1="cmextrn.h"
HAVEINFO=`cat ${XSPICEDIR}${FILE1} | grep ucm_cmdiode_info`
if [ -z "${HAVEINFO}" ]; then
  echo -n "${FILE1}: Adding code model diode to list of external code models "
  echo "extern SPICEdev ucm_cmdiode_info;" >> ${XSPICEDIR}/${FILE1}
  echo "Done!"
else
  echo "${XSPICEDIR}${FILE1} already processed!"
fi

FILE2="cminfo.h"
HAVEINFO=`cat ${XSPICEDIR}${FILE2} | grep ucm_cmdiode_info`
if [ -z "${HAVEINFO}" ]; then
  echo -n "${FILE2}: Adding code model info "
  echo "&ucm_cmdiode_info," >> ${XSPICEDIR}/${FILE2}
  echo "Done!"
else
  echo "${XSPICEDIR}${FILE2} already processed!"
fi

FILE4="modpath.lst"
HAVEINFO=`cat ${XSPICEDIR}${FILE4} | grep -v sidiode | grep diode`
if [ -z "${HAVEINFO}" ]; then
  echo -n "${FILE4}: Adding code model to the list of modules "
  echo "diode" >> ${XSPICEDIR}/${FILE4}
  echo "Done!"
else
  echo "${XSPICEDIR}${FILE4} already processed!"
fi

FILE5="objects.inc"
HAVEINFO=`cat ${XSPICEDIR}${FILE5} | grep -v sidiode | grep diode`
if [ -z "${HAVEINFO}" ]; then
  echo -n "${FILE5}: Adding code model diode source code directory "
  echo "diode/*.o \\" > tmp.inc
  cat ${XSPICEDIR}${FILE5} >> tmp.inc
  mv ${XSPICEDIR}${FILE5} "${XSPICEDIR}${FILE5}.old"
  mv tmp.inc ${XSPICEDIR}${FILE5}
  echo "Done!"
else
  echo "${XSPICEDIR}${FILE5} already processed!"
fi

DIR1="diode"
HAVEINFO=`ls ${XSPICEDIR} | grep -v sidiode | grep ${DIR1}`
if [ -z "${HAVEINFO}" ]; then
  echo -n "${DIR1}: Copying directory containing the model  "
  cp -a ./diode ${XSPICEDIR}
  echo "Done!"
else
  echo "${XSPICEDIR}${DIR1} already processed!"
fi

#
# now recompile ngspice with new files added:
#   this step should complete without errors, otherwise we are in trouble
cd $NGSPICEDIR
make

