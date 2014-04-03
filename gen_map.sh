#!/bin/bash

BASE=`pwd`

packageName=$1

if [ -z $packageName ]; then
    echo "no packageName found exit"
    exit 1
fi

cat colors.xml | while read line
do
    if ! echo $line | grep "name"; then
	continue
    fi
    
    #<color name="notification_list_shadow_top">#80000000</color>
    #<item type="color" name="bright_foreground_dark">@color/background_light</item>
    tmp=`echo $line | awk '{print $2}'`
    if echo $tmp | grep "type=\""; then
	continue
    fi
    
    #name="notification_list_shadow_top">#80000000</color>
    #name="notification_list_shadow_top
    #\#80000000</color>
     itemName=`echo $tmp | awk -F "\">" '{print $1}' | awk -F "=\"" '{print $2}'`
     itemVaule=`echo $tmp | awk -F "\">" '{print $2}' | awk -F "</" '{print $1}'`
    
    echo "localItem is $itemName, value is $itemVaule"
    
    echo $itemName:$itemVaule >> ${packageName}_color.map
done

cat dimens.xml | while read line
do
    if ! echo $line | grep "name"; then
	continue
    fi
    
    #<color name="notification_list_shadow_top">#80000000</color>
    #<item type="color" name="bright_foreground_dark">@color/background_light</item>
    tmp=`echo $line | awk '{print $2}'`
    if echo $tmp | grep "type=\""; then
	continue
    fi
    
    #name="notification_list_shadow_top">#80000000</color>
    #name="notification_list_shadow_top
    #\#80000000</color>
     itemName=`echo $tmp | awk -F "\">" '{print $1}' | awk -F "=\"" '{print $2}'`
     itemVaule=`echo $tmp | awk -F "\">" '{print $2}' | awk -F "</" '{print $1}'`
    
    echo "localItem is $itemName, value is $itemVaule"
    
    echo $itemName:$itemVaule >> ${packageName}_dim.map
done
