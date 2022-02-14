#!/bin/bash
if [ $# -gt 0 ]; then
    echo "Your running $0 with argument: $1"
else
    echo "  expected args : "
    echo "        'cluster'  - to be run on master node(M* only), captures cluster wide info"
    echo "        'host'     - to be run on all nodes including masters, captures host specific data"
    echo "  "
    echo "  example:  $0 cluster or $0 host "
exit
fi


rlogin()

{
robin login robin --password Robin123;
}

progress_bar()
{
echo " Running the data collect script ...., please wait.."
echo -ne '     #####                     (33%)\r'
sleep 3
echo -ne '     #############             (50%)\r'
sleep 1
}


filenamehost=robin-host-data_$(hostname)_$(date +%Y%m%d-%H%M%S).log
filenamecluster=robin-cluster-data_$(hostname)_$(date +%Y%m%d-%H%M%S).log

#Function to collect to host data
collect_host_data()
{
commands=("uptime" "service kubelet status"  "service docker status" "service dockershim status"  "service ntpd status"  "df -h" "uname -a" "ip addr show" "free -g" "lscpu" "lsblk" "lspci" "hostname" "hostname -i" "dmidecode" "nslookup $(hostname)" "mount" "docker version" "kubectl version" "docker images" "cat /etc/hosts" "cat /etc/resolv.conf"  )
filename=$filenamehost

echo " ## collecting host information  from `hostname -f` on `date`##" > $filename
for x in  "${commands[@]}"
do
y=$(echo ~~~~~~~~~~~~~~~~${x}~~~~~~~~~~~~~|sed 's/./~/g')
echo "     $y     " >>$filename
echo "    command: ${x^^} on $(hostname)     " >> $filename
echo "     $y     " >>$filename
echo " " >> $filename
$x >> $filename 2>> /dev/null
done
}

cluster_info()
{
clust_commands=("robin version" "docker version" "kubectl version" "robin license info"  "robin host list" "robin app list" "robin instance list" "robin drive list" "robin volume list" "robin docker-registry list" "robin host list --services"  "robin ip-pool list --full" "robin ap report" "kubectl get nodes" "kubectl get all --all-namespaces -o wide" "kubectl get sc -o wide" "docker images" "kubectl get pvc --all-namespaces" "kubectl get pv --all-namespaces"  "robin config list" "robin job list" "robin user list" )

filename=$filenamecluster

echo " ## Collecting some basic cluster wide information from `hostname -f` on `date`..." > $filename
date >> $filename
echo >> $filename
for i in "${clust_commands[@]}"
do

j=$(echo ~~~~~~~~~${i}~~~~~~~~~~~~~~~~~|sed 's/./~/g')
  echo "     ${j}     " >> $filename
  echo "      command: ${i^^}                      " >> $filename
  echo "     ${j}     " >> $filename
  echo >> $filename
  $i >> $filename 2>> /dev/null
  echo >> $filename
done

}

cert_data()
{
echo "~~~~~~ capturing certificate expiry information ~~~~~" >>$filename
for c in $(ls /etc/kubernetes/pki/*.crt) ; do echo $c ;  openssl x509 -in $c -text -noout | grep 'Not After' ; done >> $filename
for c in $(ls /etc/kubernetes/pki/etcd/*.crt) ; do echo $c ;  openssl x509 -in $c -text -noout | grep 'Not After' ; done >> $filename
for c in $(ls /var/lib/kubelet/pki/*.crt) ; do echo $c ;  openssl x509 -in $c -text -noout | grep 'Not After' ; done >> $filename
}




   if [ $1 = "cluster" ];then
   rlogin 
     progress_bar
        cluster_info
        echo -ne '     ########################      (75%)\r'
        sleep 2
    collect_host_data
        if [ $? = 0 ];then
             echo -ne '     ############################################   (100%)\r'
                 echo -ne '\n'
                 sleep 1
            echo "Generated Reports $filenamecluster and $filenamehost on this Host. "
        echo " Script Completed successfully ..!!"
      fi
   elif [ $1 = "host" ];then
    echo "Running agent/host  data collection functions"
    collect_host_data
    echo "   Generated a report  $filenamehost on this Host. "
    echo " Script Completed successfully ..!!"

#cert_data
  else
      echo "wrong arguement passed"
      exit
   fi
