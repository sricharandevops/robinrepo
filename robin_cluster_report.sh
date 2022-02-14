#!/bin/bash

# Robin Cluster info_page - A script to produce a system information HTML file


ruser=$1
rpassword=$2

##### Constants

TITLE="ROBIN CNP CLUSTER INFORMATION for $HOSTNAME"
RIGHT_NOW=$(date +"%x %r %Z")
TIME_STAMP="Updated on $RIGHT_NOW by $USER"
MASTER_HOST=$(if [[ $(ps aux | grep robin-server | grep -vc grep)  > 0 ]] ; then echo "$(hostname) is ACTIVE MASTER "; else echo "$(hostname) is NOTACTIVE MASTERNODE, Please run on Active Master node" ; fi)
PGROLE=$(docker exec -ti $(docker ps|grep rcm|awk '{print $1}') bash  pgsql-role)

##### Functions

robin_login()
{
robin login $ruser --password $rpassword
if [  $? -ne 0 ] 
then
exit
fi
}
system_info()
{
    echo "<h2 >Host Info</h2>"
    echo "<p><b> Kernel info</b></p>"
        uname -a;
    echo "<p><b> OS Info</b></p>"
    cat /etc/redhat-release
     echo '\n'
     echo uptime: $(uptime);
     hostname -i
    echo "<p><b>Mem info</b></p>"
    cat /proc/meminfo|grep Mem
    echo "<p><b>CPU info</b></p>"
    nproc --all
     
}  

filesystem_space()
{
    echo "<h2>Filesystem space</h2>"
    echo "<pre>"
    df -h|grep -vE 'kubelet|plugins|containers' > /tmp/fscheck.rtmp &
    cat /tmp/fscheck.rtmp
    echo "</pre>"

}   

kubelet_status()
{
    echo "<h2>kubelet service status</h2>"
    echo "<pre>"
        service kubelet status 
        echo "</pre>"
}  

kube_get_nodes()
{
    echo "<h2>kubectl get nodes</h2>"
    echo "<pre>"
    kubectl get nodes 
    echo "</pre>"

}

kube_get_pods()
{
    echo "<h2>kubectl get pods</h2>"
    echo "<pre>"
    kubectl get pods -A -o wide
    echo "</pre>"
}

kube_get_pvc()
{
    echo "<h2>kubectl get pvc</h2>"
    echo "<pre>"
    kubectl get pvc -A
    echo "</pre>"
}

docker_version()
{

    if [ "$(id -u)" = "0" ]; then
        echo "<h2>docker version</h2>"
        echo "<pre>"
        docker version|grep Version|head -1
        echo "</pre>"
    fi

}

docker_status()
{

    if [ "$(id -u)" = "0" ]; then
        echo "<h2>docker status</h2>"
        echo "<pre>"
        echo "Bytes Directory"
        systemctl status docker
        echo "</pre>"
    fi

}

watchdog_info()
{
    echo "<h2 >robin watchdog info</h2>"
    echo "<pre>"
    docker exec -ti $(docker ps|grep rcm|awk '{print $1}') bash robin-watchdog info > /tmp/wd.info
    cat  /tmp/wd.info   
    echo "</pre>"
}

sherlock_info()
{
    echo "<h2>sherlock insight</h2>"
    echo "<pre style='background-color:#FFF380;'>"
    source ~/.bashrc;sherlock > /tmp/sherlock.rtmp
    cat /tmp/sherlock.rtmp
    echo "</pre>"
}

robin_server_log()
{
 echo "<h2 >tail -100f robinserver.log</h2>"
cat /var/log/robin/server/server.log |tail -100 > /tmp/robin_server.rtmp
cat /tmp/robin_server.rtmp
}

iomgr_log()
{
echo " <h2> tail -100f iomgr.log </h2>"
cat /var/log/robin/iomgr.log|tail -100> /tmp/iomgrlog.rtmp
cat /tmp/iomgrlog.rtmp
}


docker_images()
{
 echo "<h2>docker images</h2>"
    echo "<pre>"
    docker images
    echo "</pre>"
}

robin_service_info()
{
    echo "<h2>robin host list --services</h2>"
    echo "<pre>"
    robin host list --services
    echo "</pre>"
}

robin_host_status()
{
    echo "<h1>robin-host-status</h1>"
    echo "<pre>"
 source ~/.bashrc;robin-host-status 
    echo "</pre>"
}

robin_host_list()
{
    echo  "<h2>robin-host-list</h2>"
    echo "<pre>"
    robin host list
    echo "</pre>"

}

postgres_info()
{
    echo "<h2>Active Postgres DB processes</h2>"
    echo "<pre>"
    ps -ef|grep postgres
    echo "</pre>"
}

robin_app_list()
{
echo "<h2>robin app list</h2>"
    echo "<pre>"
    robin app list
    echo "</pre>"
}

robin_collection_list()
{
  echo "<h2>robin collection list</h2>"  
  echo "</pre>"
  robin collection list
  echo "</pre>"
}

robin_job_list()
{
  echo "<h2>robin job list</h2>"
  robin job list > /tmp/rjl.rtmp
  cat /tmp/rjl.rtmp
}

varlogmessages()
{
   echo "<h2>/var/log/messages</h2>"
    echo "<pre  >"
    cat /var/log/messages|tail -50
    echo "</pre>"
}

robin_drive_list()
{
    echo "<h2>robin drive list</h2>"
    echo "<pre  >"
    robin drive list
    echo "</pre>"
}

write_page()
{
    cat <<- _EOF_
    <html>
        <head>
        <title>$TITLE</title>
        </head>
        <body style="background-color:#7BCCB5;">
        <h1 style="background-color:DodgerBlue;">$TITLE</h1>
        <p>$TIME_STAMP</p>
        <h2><b style="color:Tomato;">$MASTER_HOST </b></h2>
        $(system_info)
        $(kube_get_nodes)
        $(robin_login)
        $(sherlock_info)
        $(robin_host_status)
        $(robin_host_list)
        $(watchdog_info)
        $(robin_service_info)
        $(postgres_info)
        $(robin_app_list)
        $(robin_collection_list)
        $(filesystem_space)
        $(robin_drive_list)
        $(docker_version)
        $(docker_images)
        $(docker_status)
        $(kube_get_nodes)
        $(kube_get_pods)
        $(kubelet_status)
        $(kube_get_pvc)
        $(varlogmessages)
        $(robin_server_log)
        $(iomgr_log)
        </body>
    </html>
_EOF_

}
##### Main

filename=./RobinClusterReport.html

if [ $# != 2 ]; then
    echo "  expected args : "
    echo "        'username' - robin admin username"
    echo "        'password' - robin admin password  "
    echo "  "
    echo "  example:  $0 robin robinpaswd"
    echo " "
    echo " Run this script from Active Master Node"
exit
fi

write_page > $filename
