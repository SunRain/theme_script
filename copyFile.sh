#!/bin/bash

BASE_DIR=`pwd`
WORK_DIR=${BASE_DIR}/work
TRAGET_DIR=${BASE_DIR}/target

packageName=$1
searchFile=$2
targetDir=$3
rename=$4

if [ -z $packageName ] || [ -z $searchFile ] || [ -z $targetDir ]; then 
    echo "search [packageName] for [file], then copy to [targetDir], U can rename a [new file name] in target dir if U want"
fi

base=`echo $packageName | sed 's/.apk//g'`
TRAGET_DIR=${TRAGET_DIR}/$base
m_workApktooled=${WORK_DIR}/${base}_apktool



for i in `find ${m_workApktooled} -iname *$searchFile*`
do
    #~work/com.vicino.theme.FlatronBlue-1_unzip/res/drawable-xxhdpi/frameworks_res_btn_star_on_focused_holo_dark.9.png
    fromFileName=`echo $i | awk -F "/" '{a=NF}{print $a}'`  #=> frameworks_res_btn_star_on_focused_holo_dark.9.png
    dot=`echo $fromFileName | awk -F "." '{for(i=1;i<=NF;i++)a[i]=$i}{for(i=2;i<=NF;i++){printf ".";printf("%s", a[i])}}'`  #=> .9.png
    to=`echo $i | awk -F "/" '{i=NF;i-=1}{print $i}'`  #=> drawable-xxhdpi

    if [ ! -d $targetDir/$to ]; then
	mkdir -p $targetDir/$to
    fi
    
    if [ -z $rename ]; then
        echo "Will Copy [$i] => [$targetDir/$to/${searchFile}${dot}]"
	cp $i $targetDir/$to/${searchFile}${dot}
    else
        echo "Will Copy [$i] => [$targetDir/$to/${rename}${dot}]"
	cp $i ${TRAGET_DIR}/$targetDir/$to/${rename}${dot}
    fi
done

