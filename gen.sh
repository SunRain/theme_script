#!/bin/bash

BASE_DIR=`pwd`
WORK_DIR=${BASE_DIR}/work
TRAGET_DIR=${BASE_DIR}/target
LOG_FILE=${BASE_DIR}/Log.txt

WORK_COLOR_MAP="" #${BASE_DIR}/work/color.map
WORK_DIM_MAP="" #${BASE_DIR}/work/dim.map
#WORK_SYSTEMUI_RES_MAP=${BASE_DIR}/work/systemui-res.map
#WORK_SYSTEMUI_DIM_MAP=${BASE_DIR}/work/systemui-dim.map

#BASE_FRAMEWORK_COLOR_MAP=${BASE_DIR}/framework-res_color.map
#BASE_FRAMEWORK_DIM_MAP=${BASE_DIR}/framework-res_dimens.map
#BASE_SYSTEMUI_COLOR_MAP=${BASE_DIR}/systemui_color.map
#BASE_SYSTEMUI_DIM_MAP=${BASE_DIR}/systemui_dimens.map

TYPE_DRAWABLE=drawable

m_workFile=$1
m_workApktooled=""
m_workUnziped=""
m_targetPath=""

function toLog() {
    echo "$*" # >> ${BASE_DIR}/Log.txt
}

##创建基本的文件目录
function initDirs() {
    if [ ! -d ${WORK_DIR} ]; then
	mkdir ${WORK_DIR}
    fi

    if [ ! -d ${TRAGET_DIR} ]; then
	mkdir ${TRAGET_DIR}
    fi

    if echo ${m_workFile} | grep .apk; then
	local base=`echo ${m_workFile} | sed 's/.apk//g'`
    else
	local base=${m_workFile}
    fi
    
    WORK_COLOR_MAP=${BASE_DIR}/work/${base}_color.map
    WORK_DIM_MAP=${BASE_DIR}/work/${base}_dim.map

    TRAGET_DIR=${TRAGET_DIR}/$base
    
    m_workApktooled=${base}_apktool
    m_workUnziped=${base}_unzip
    
    if [ ! -d ${WORK_DIR}/${m_workApktooled} ]; then
        apktool d ${m_workFile} ${WORK_DIR}/${m_workApktooled}
    fi
    
    if [ -d ${WORK_DIR}/${m_workApktooled} ]; then
        m_workApktooled=${WORK_DIR}/${m_workApktooled}
    fi
    
    if [ ! -d ${WORK_DIR}/${m_workUnziped} ]; then
        unzip ${m_workFile} -d ${WORK_DIR}/${m_workUnziped}
    fi
    
    if [ -d ${WORK_DIR}/${m_workUnziped} ]; then
         m_workUnziped=${WORK_DIR}/${m_workUnziped}
    fi
}

#gen the res map to a target file
function genApktooldResMap() {
    local file=$1
    local target=$2
    if [ ! -z $file ]; then
        toLog "not find file, exit"
    fi
    
    if [ ! -z $target ]; then
        toLog "not target file, exit"
    fi

    [ -f $target ] && rm $target

    cat $file | while read line
    do
        if ! echo $line | grep "name"; then
            continue
        fi
        
        #<color name="notification_list_shadow_top">#80000000</color>
        #<item type="color" name="bright_foreground_dark">@color/background_light</item>
        local tmp=`echo $line | awk '{print $2}'`
        if echo $tmp | grep "type=\""; then  #skip line like <item type="color" name="bright_foreground_dark">@color/background_light</item>
            continue
        fi
        
        #name="notification_list_shadow_top">#80000000</color>
        #name="notification_list_shadow_top
        #80000000</color>
        local itemName=`echo $tmp | awk -F "\">" '{print $1}' | awk -F "=\"" '{print $2}'`
        local itemVaule=`echo $tmp | awk -F "\">" '{print $2}' | awk -F "</" '{print $1}'`
        
        echo "localItem is $itemName, value is $itemVaule"
        
        echo $itemName:$itemVaule >> $target
    done
}

#输入指定的图片名称,然后在以zip模式解压的目录里面搜索图片,并复制到目标目录
#搜索zip目录是由于apktool解压后.9文件也会被反编译,而我们并不需要反编译.9文件
#######################################

#<item name="drawable/btn_star_on_focused_holo_dark">@drawable/frameworks_res_btn_star_on_focused_holo_dark</item>
#$1 => btn_star_on_focused_holo_dark
function copyDrawable() {
    local name=$1
    local to=$2
    
    if [ -z ${name} ]; then
        toLog "no from file found"
        return
    fi
    
    if [ -z ${to} ]; then
        toLog "no target path found"
        return
    fi
    
    toLog "search [${m_workUnziped}] for name [$name]"
    
    for i in `find ${m_workUnziped} -iname *${name}*`
    do
        #~work/com.vicino.theme.FlatronBlue-1_unzip/res/drawable-xxhdpi/frameworks_res_btn_star_on_focused_holo_dark.9.png
        local fromFileName=`echo $i | awk -F "/" '{a=NF}{print $a}'`  #=>frameworks_res_btn_star_on_focused_holo_dark.9.png
        local dot=`echo $fromFileName | awk -F "." '{for(i=1;i<=NF;i++)a[i]=$i}{for(i=2;i<=NF;i++){printf ".";printf("%s", a[i])}}'`  #=>.9.png
        local targetDir=`echo $i | awk -F "/" '{i=NF;i-=1}{print $i}'`  #=> drawable-xxhdpi

        if [ ! -d $to/$targetDir ]; then
            mkdir -p $to/$targetDir
        fi
        
        if [ $dot == ".xml" ]; then  #Do Not Copy .xml drawable atm
            #t=`echo $i | sed 's#'${m_workUnziped}'#'${m_workApktooled}'#g'`
  
            #cp $t $to/$targetDir/${name}${dot}
            continue
        else
            cp $i $to/$targetDir/${name}${dot}
        fi
    done
}

function copyDrawableRes() {
    #com.android.mms
    local packageName=$1
    toLog "================== Copy drawable for package [$packageName] ==========================="

    if [ -z $packageName ]; then
        toLog "No packageName found, exit"
        return 1
    fi
    
    #local resPath
    #local file
    if [ $packageName == "framework-res" ]; then
        local resPath=${TRAGET_DIR}/framework-res/res
        local file=${m_workApktooled}/res/xml/android.xml
    else
        local resPath=${TRAGET_DIR}/$packageName/res
        local file=${m_workApktooled}/res/xml/$(echo $packageName | sed 's#\.#_#g').xml
    fi

    if [ ! -d $resPath ]; then
        mkdir -p $resPath
    fi

    cat $file | while read line
    do
        #echo "$line"
        #<item name="drawable/btn_star_on_focused_holo_light">@drawable/frameworks_res_btn_star_on_focused_holo_light</item>
        tmp=`echo $line | awk '{print $2}' | awk -F "\">@" '{print $1}' | awk -F "=\"" '{print $2}'`
        type=`echo $tmp | awk -F "/" '{print $1}'`
        name=`echo $tmp | awk -F "/" '{print $2}'`

        if [ "$type" == "${TYPE_DRAWABLE}" ]; then
            echo "** Copy file $name"

            copyDrawable $name $resPath #&
        fi
    done
}

##Really ugly, but works atm....
function genValuesRes() {
        #com.android.mms
    local packageName=$1
    
    if [ -z $packageName ]; then
        toLog "No packageName found, exit"
        return 1
    fi

    baseColorMap=${packageName}_color.map
    baseDimMap=${packageName}_dim.map
    #echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > ${TRAGET_DIR}/com.android.systemui/theme_values.xml
    #echo "<ChaOS_Theme_Values>" >> ${TRAGET_DIR}/com.android.systemui/theme_values.xml
    echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > ${TRAGET_DIR}/$packageName/theme_values.xml
    echo "<ChaOS_Theme_Values>" >> ${TRAGET_DIR}/$packageName/theme_values.xml

    
    local type=""
    local t=""
    local value=""
    
    #for colors
    cat $baseColorMap | while read line
    do
        #dim_foreground_dark_inverse:#ff323232
        type=`echo $line | awk -F ":" '{print $1}'`
        cat ${WORK_COLOR_MAP} | while read types
        do
	    #holo_blue_bright:#ff00ddff
	    t=`echo $types | awk -F ":" '{print $1}'`
	    if [ $type == $t ]; then
		value=`echo $types | awk -F ":" '{print $2}'`
		echo "<color name=\"$type\">$value</color>" >> ${TRAGET_DIR}/$packageName/theme_values.xml
		#echo "<color name=\"$type\">$value</color>" >> ${TRAGET_DIR}/com.android.systemui/theme_values.xml
		break
	    fi
        done
    done
    
    #for dim
    cat $baseDimMap | while read line
    do
        #dim_foreground_dark_inverse:#ff323232
        type=`echo $line | awk -F ":" '{print $1}'`
        cat ${WORK_DIM_MAP} | while read types
        do
	    #holo_blue_bright:#ff00ddff
	    t=`echo $types | awk -F ":" '{print $1}'`
	    if [ $type == $t ]; then
		value=`echo $types | awk -F ":" '{print $2}'`
		#<dimen name="system_bar_icon_size">32.0dip</dimen>
		echo "<dimen name=\"$type\">$value</dimen>" >> ${TRAGET_DIR}/$packageName/theme_values.xml
		#echo "<color name=\"$type\">$value</color>" >> ${TRAGET_DIR}/com.android.systemui/theme_values.xml
		break
	    fi
        done
    done

    echo "</ChaOS_Theme_Values>" >> ${TRAGET_DIR}/$packageName/theme_values.xml
}

function copyFrameworkDrawable() {
    copyDrawableRes "framework-res"
}

function genFrameworkValues() {
    genValuesRes "framework-res"
}

function genSystemUIValues() {
    genValuesRes "com.android.systemui"
}

function copySystemUIDrawable() {
    copyDrawableRes "com.android.systemui"
}

function genSettingsValues() {
    genValuesRes "com.android.settings"
}

function copySettingsDrawable() {
    copyDrawableRes "com.android.settings"
}

function genMmsValues() {
    genValuesRes "com.android.mms"
}

function copyMmsDrawable() {
    copyDrawableRes "com.android.mms"
}

function initBase() {
    initDirs
    
    local valueDir=${m_workApktooled}/res/values
    
    genApktooldResMap $valueDir/colors.xml $WORK_COLOR_MAP
    genApktooldResMap $valueDir/dimens.xml $WORK_DIM_MAP
}

if [ -z ${m_workFile} ]; then
    toLog "no file found, exit"
fi

rm ${LOG_FILE}

initBase

 copyFrameworkDrawable

 genFrameworkValues

  copySystemUIDrawable
  genSystemUIValues

  copySettingsDrawable
  genSettingsValues

  copyMmsDrawable
  genMmsValues

copyDrawableRes "com.android.contacts"
genValuesRes "com.android.contacts"

copyDrawableRes "com.android.dialer"
genValuesRes "com.android.dialer"




