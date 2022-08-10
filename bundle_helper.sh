#!/bin/bash
## Sricharan Mahavadi
## This is  helper script to fasten your bundle building excercise.
##  Update section 1 with environment specific entries

##Section 1 - update parameters according to your environment, onetime
project=spacex
robinuser=$1
robinpassword=$2
zoneid=1653366215    #  you can get it from robin zone list

##Section 2 -  App deployment variables
bundlefile=${project}bundle.tar.gz
appname=${project}app
bundleversion=${project}BV
rpoolname=default
workdir=$PWD

if [ $# -ne 2 ]; then
    echo "Your running $0 with argument: $@"

    echo "  please pass username and password for robin user "
    echo "     example : sh  $0 robin Robin123 "
    echo "        '
    echo "  "
    echo "  example:  $0 cluster or $0 host "
exit
fi

robin login $robinuser --password $robinpassword

if [[ $? -ne 0 ]]
then
  echo "Oops..!!! Please  verify check the robinusername and password and try again"
exit
fi

echo " tar the bundle file"
tar -cvzf $bundlefile manifest.yaml scripts icons

echo "deleting an app if its already created"

echo "robin app delete $appname --force --wait --yes "

robin app delete $appname --force --wait --yes

echo "Removing the old bundle bid:  `cat bid.last` "

echo "robin bundle remove $zoneid `cat bid.last` --yes --wait"
robin bundle remove $zoneid `cat bid.last` --yes --wait


echo "adding the bundle $project"
robin bundle add $project $bundleversion $bundlefile  --wait

echo "fetching the bundle id for newly uploaded"
bundid=$(robin bundle list|grep $bundleversion|awk '{print $1}')

echo $bundid > bid.last

echo "creating an app with new bundle"
echo "robin app create from-bundle $appname --rpool $rpoolname  $bundid   --ip-pool robin-default --wait"
robin app create from-bundle $appname --rpool $rpoolname  $bundid  --ip-pool robin-default --wait


echo "Here are the instances of the app"
echo "########################################"
robin instance list|grep $appname
