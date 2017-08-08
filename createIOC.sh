#!/bin/bash
. env.sh

#=====Name of IOC, "ioc" will be appended automatically by makeBaseApp!=====
export EPICS_IOCNAME="test"

#====Change if necessary====
export EPICS_HOME=/home/epics
file1="$EPICS_HOME/base/startup/EpicsHostArch"
if [ -f "$file1" ]
then
     export EPICS_HOST_ARCH=$($file1)
fi

#====Leave unchanged====
export EPICS_BASE=$EPICS_HOME/base
export EPICS_EXTENSIONS=$EPICS_HOME/extensions
export PATH=$PATH:$EPICS_BASE/bin/$EPICS_HOST_ARCH:$EPICS_EXTENSIONS/bin/$EPICS_HOST_ARCH



##==================
mkdir -p  $EPICS_IOCNAME"ioc"
cd $EPICS_HOME/$EPICS_IOCNAME"ioc"
$EPICS_BASE/bin/$EPICS_HOST_ARCH/makeBaseApp.pl -i -p $EPICS_IOCNAME -t ioc $EPICS_IOCNAME
$EPICS_BASE/bin/$EPICS_HOST_ARCH/makeBaseApp.pl -t ioc $EPICS_IOCNAME
make -C $EPICS_HOME/$EPICS_IOCNAME"ioc" 

##=====Implement modules at compile time =====
sed -i "/# Include dbd files from all support applications:/a "$EPICS_IOCNAME"_DBD += asyn.dbd stream.dbd drvAsynIPPort.dbd drvAsynSerialPort.dbd" $EPICS_IOCNAME"App"/src/Makefile
sed -i "/# Add all the support libraries needed by this IOC/a "$EPICS_IOCNAME"_LIBS += stream \n"$EPICS_IOCNAME"_LIBS += asyn" $EPICS_IOCNAME"App"/src/Makefile
sed -i "/EPICS_BASE*=.*/a ASYN=$EPICS_HOME/asyn\nSTREAM=$EPICS_EXTENSIONS/StreamDevice\nEPICS_EXTENSION=$EPICS_EXTENSIONS\n#Benötigt,damit stream.dbd gefunden wird" configure/RELEASE
make -C $EPICS_HOME/$EPICS_IOCNAME"ioc"
cd $EPICS_HOME

##====Write envPaths in <ioc>/iocBoot/ioc<name>/envPaths =====
printf "epicsEnvSet(\"ARCH\",\""$EPICS_HOST_ARCH"\")\n" > $EPICS_HOME/$EPICS_IOCNAME"ioc"/iocBoot/ioc$EPICS_IOCNAME/envPaths
printf "epicsEnvSet(\"IOC\",\"ioc"$EPICS_IOCNAME"\")\n" >> $EPICS_HOME/$EPICS_IOCNAME"ioc"/iocBoot/ioc$EPICS_IOCNAME/envPaths
printf "epicsEnvSet(\"TOP\",\""$EPICS_HOME"/"$EPICS_IOCNAME"ioc\")\n" >> $EPICS_HOME/$EPICS_IOCNAME"ioc"/iocBoot/ioc$EPICS_IOCNAME/envPaths
printf "epicsEnvSet(\"EPICS_BASE\",\""$EPICS_BASE"\")\n" >> $EPICS_HOME/$EPICS_IOCNAME"ioc"/iocBoot/ioc$EPICS_IOCNAME/envPaths
printf "epicsEnvSet(\"ASYN\",\""$EPICS_HOME"/asyn""\")\n" >> $EPICS_HOME/$EPICS_IOCNAME"ioc"/iocBoot/ioc$EPICS_IOCNAME/envPaths
printf "epicsEnvSet(\"STREAM\",\""$EPICS_EXTENSIONS"/StreamDevice\")\n" >> $EPICS_HOME/$EPICS_IOCNAME"ioc"/iocBoot/ioc$EPICS_IOCNAME/envPaths
printf "epicsEnvSet(\"EPICS_EXTENSION\",\""$EPICS_EXTENSIONS"\")" >> $EPICS_HOME/$EPICS_IOCNAME"ioc"/iocBoot/ioc$EPICS_IOCNAME/envPaths

##===Write STREAM_PROTOCOL_PATH variable in st.cmd  ===
MYTEXT='epicsEnvSet ("STREAM_PROTOCOL_PATH", ".:../../db")'
sed -i "/cd \"\${TOP}\"/a $MYTEXT" $EPICS_HOME/$EPICS_IOCNAME"ioc"/iocBoot/ioc$EPICS_IOCNAME/st.cmd
echo 'dbl > /home/epics/dbl_latest.lst' >> $EPICS_HOME/$EPICS_IOCNAME"ioc"/iocBoot/ioc$EPICS_IOCNAME/st.cmd

##=== add absolute Path to envPaths in st.cmd ===
sed -ie "s@< envPaths@< $EPICS_HOME\/${EPICS_IOCNAME}ioc\/iocBoot\/ioc$EPICS_IOCNAME\/envPaths@g" $EPICS_HOME/$EPICS_IOCNAME"ioc"/iocBoot/ioc$EPICS_IOCNAME/st.cmd

##=== Create executeable startioc.sh in $EPICS_HOME ===
printf '#!/bin/bash\n'$EPICS_HOME'/'$EPICS_IOCNAME'ioc/bin/'$EPICS_HOST_ARCH'/'$EPICS_IOCNAME' '$EPICS_HOME'/'$EPICS_IOCNAME'ioc/iocBoot/ioc'$EPICS_IOCNAME'/st.cmd\n' > $EPICS_HOME/starteioc.sh
chmod 755 $EPICS_HOME/starteioc.sh

##=== Make protocols and db directory ===
mkdir $EPICS_HOME/$EPICS_IOCNAME"ioc"/db

