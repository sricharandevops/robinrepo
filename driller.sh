#!/bin/bash
# 
#################################################################
### AUTHOR : SRICHARAN MAHAVADI..                            ####
# A Menu driven troubleshooting utility for Operational Use. #### 
#################################################################

## ----------------------------------
# Define variables
# ----------------------------------

. $HOME/.bash_profile
EDITOR=vim
PASSWD=/etc/passwd
RED='\033[0;41;30m'
STD='\033[0;0;39m'
export ROBIN_PASSWD=Robin123
export ROBIN_USER=robin
SCRIPT_HOME=$PWD


usage()
{
:
}


rlogin()
{
robin login $ROBIN_USER --password $ROBIN_PASSWD
if [ $? != 0 ]
then
echo " Incorrect login credentials supplied "

exit
fi
}

# HEADERS

write_header() {
  # print header

  local name=$1; shift;
  printf "%s""--------------------\\n$name%s\\n--------------------\\n"
  printf "%s" "$@"
}


checkargs()
{
if [ ! -z "$1" ]; 
then
	echo "$0 script parameter passed: $1"
else
	echo "SUBROUTINE requires run-time argument. EXITING..."
	exit 1
fi
}

 
# ----------------------------------
#   SUBROUTINES
# ----------------------------------
pause(){
  read -p "Press [Enter] key to continue..." 
}

 
#

k8s_cp_healthcheck()
{
 write_header " KUBECTL GET PODS -N KUBE-SYSTEM"
 kubectl get pods -n  kube-system -o wide

 write_header " KUBECTL GET NODES"
 kubectl get nodes -A

 pause
}

drill_app()
{
  echo "     "
         echo "  You choose to drilldown on a specific app , which app you want to investigate..? "
         echo "$(robin app list --headers=Name)"
         echo " Enter the name of the app you want to drilldown ..? "
         read  dappname
                   
         echo "       "
         echo "         1. show app status "
         echo "          "
         echo "         2. Show app volume and storage mapping info "
         echo "                         "
         echo "         3. Show app pods status "
         echo "                         "
         echo "         4 . exit    "
         echo "       "

         read -p "Enter one choice:" input_sm
        case $input_sm in
                1)  robin app info $dappname --storage && pause ;;
                2)  robin app info $dappname --network && pause ;;
                3)  kubectl get pods -A|grep $dappname && pause ;;
                4) echo " Going back to main menu" && pause;;
                *) echo -e "${RED}Error...${STD}" && sleep 2
        esac
        pause
}
 
# function to display menus
show_menus() {
	clear
	echo "#############################################################"	
	echo "                     ROBIN ADMIN UTIL "
	echo "##############################################################"
        echo "   Performing Initial Assesment:        "
        echo "                         "
	echo "1. Check K8s control plane health"
        echo "                         "
	echo "2. Check robin control plane pod health"
        echo "                         "
	echo "3. Is the issue specific to one app ..?"
        echo "                         "
	echo "4. Is the issue a cluster wide issue ..?"
        echo "                         "
	echo "5. Exit"
        echo "                         "
}
# read input from the keyboard and take a action
read_options(){
	local choice
	read -p "Enter choice [ 1 - 5] " choice
	case $choice in
		1) k8s_cp_healthcheck ;;
		2) kubectl get pods -A|grep robinio && pause ;;
		3) drill_app;;
		4) robin host list --services && pause;;
		5|exit|EXIT) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2 && echo -e " Press 5 to exit"
	esac
 pause
}
 
# ----------------------------------------------
#  Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
trap '' SIGINT SIGQUIT SIGTSTP
 
# -----------------------------------
#  Main logic - infinite loop
# ------------------------------------
rlogin
while true
do
	show_menus
	read_options
done

