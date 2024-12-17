#!/bin/bash

version='1.3.14'

filename=$(basename "$0")  
if [[ "$filename" == *"_"* ]]; then
    alias="${filename%%_*}"   
else
    alias="$filename"  
fi

script_path=$(realpath "$0")

if [[ $1 == '-v' ]]; then
        echo $version
        exit
fi

FILES_PATH=~/script_files/
old_ip_file="$FILES_PATH/$alias.old_ip"
logs_file="$FILES_PATH/$alias.log"
conf_file="$FILES_PATH/$alias.conf"

source "$conf_file"
old_ip=$(cat $old_ip_file)
#clear

dt=$(date '+%d/%m/%Y %H:%M:%S');

if [[ ! -d $FILES_PATH ]]; then
	echo "Creating dir $FILES_PATH"
	mkdir $FILES_PATH
	sleep 2
fi

if [[ ! -f $logs_file ]]; then
	echo "Creating $logs_file"
	echo "$dt $logs_file file created." >> $logs_file
fi

if [[ ! -f $conf_file ]]; then
	echo "Creating $conf_file"
	echo "$dt $conf_file file created." >> $logs_file
	echo "local_ip=''
PORT='8097'
CRON_SET='15 * * * *'

mute='0' #for dabuging only

slack_notification='0'
discord_notification='0'
telegram_notification='0'

#_Slack_#######################
SLACK_WEBHOOK_URL=''
SLACK_CHANNEL=''

#_Discord_#####################
DISCORD_URL=''
	
#_Telegram_####################
TELEGRAM_TOKEN=''
TELEGRAM_CHAT_ID=''
" > $conf_file

fi

if [[ ! -f $old_ip_file ]]; then
	echo $ip > $old_ip_file
	echo "Creating $old_ip_file"
	echo "$dt $old_ip_file file created." >> $logs_file
fi

send_discord_notification() {
	local payload=$(cat <<EOF
{
  "content": "$1"
}
EOF
)
  curl -H "Content-Type: application/json" -X POST -d "$payload" $DISCORD_URL &> /dev/null
}

send_telegram_notification(){
	TELEGRAM_URL="https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"
	curl -s -X POST $TELEGRAM_URL -d chat_id=$TELEGRAM_CHAT_ID -d text="$1" &> /dev/null
}

send_slack_notification(){
  local color='good'
  if [ $1 == 'ERROR' ]; then
    color='danger'
  elif [ $1 == 'WARN' ]; then
    color='warning'
  fi
  local message="payload={\"channel\": \"#$SLACK_CHANNEL\",\"attachments\":[{\"pretext\":\"$2\",\"text\":\"$3\",\"color\":\"$color\"}]}"
  curl -X POST --data-urlencode "$message" ${SLACK_WEBHOOK_URL} &> /dev/null
}
 
send_notification(){
	if [[ "$old_ip" == "<test>" ]]; then
		MESSAGE="Testing!!! $1"
		if [[ $mute == '1' ]]; then
			echo "!!MUTE!!"
			echo $MESSAGE
			exit
		fi
	else
		MESSAGE="$1"
	fi
	
	if [[ $telegram_notification == '1' ]]; then
		if [[ -z "$TELEGRAM_TOKEN" ]]; then
			echo "Telegram token not set. Skipping notification."
		else
			send_telegram_notification "$MESSAGE" 
			echo "sending telegram notification"
		fi
	fi

	if [[ $discord_notification == '1' ]]; then
		if [[ -z "$DISCORD_URL" ]]; then
			echo "Discord URL not set. Skipping notification."
		else
			send_discord_notification "$MESSAGE" 
			echo "sending discord notification"
		fi
	fi
	if [[ $slack_notification == '1' ]]; then
		if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
			echo "Discord URL not set. Skipping notification."
		else
			send_slack_notification 'ERROR' "IP Changed!!!" "$MESSAGE"
			echo "sending slack notification"
		fi
	fi
}

help(){
	echo "Welcome to check ip
################################
# Author: Vladimir Glayzer     #
# eMail: its_a_vio@hotmail.com #
################################

check-ip is a tool designed to monitor changes in the public IP address of a machine, send notifications when changes are detected and manage cron jobs for periodic checks. It supports notifications through Discord, Telegram and Slack. The script can also perform server reachability checks via ping tests and manage configuration and log files for each session.

0. Command:
	$ $alias [-flag] [option] 

1. [-v] Print version
	$ $alias -v

2. [-l] Print logs
        $ $alias -l

3. [-t] Test
	$ $alias -t

4. [-e] Edit .conf file
	$ $alias -e

5. [-p] Ping check
	$ $alias -p
	> The script makes reachability test (install on enother pc)

6. [-i] IP check
	$ $alias -i
	> The script compere the curent IP with last time check IP
	if it's diffrent, it will alert

7. [-c] Add cronjob
	6.1 [-i] Add cronjob IP check
	$ $alias -c -i

	6.2 [-p] Add cronjob Ping check
	$ $alias -c -p
"
}

update_ip(){
	echo $ip > $old_ip_file
}

main(){
	ip=$(curl ipinfo.io/ip) &> /dev/null
	echo "Old IP: $old_ip:$PORT"
	echo "New IP: $ip:$PORT"
	if [[ $old_ip == $ip ]]; then
		echo "The IP is the same: $ip:$PORT"
		echo "$dt Same IP. Old IP: $old_ip:$PORT. " >> $logs_file
		# send_notification  "The IP is the same: $ip:$PORT"
	else
		echo "The IP Changed! Old IP: $old_ip:$PORT, New IP: $ip:$PORT."
		echo "$dt IP Changed! Old IP: $old_ip:$PORT, New IP: $ip:$PORT, Sending notification." >> $logs_file
		send_notification "The NEW IP is: http://$ip:$PORT"
		update_ip
	fi
}
 
ping_test(){
	if ping -c 1 $local_ip &> /dev/null; then
	  if [[ -f file ]]; then
		  echo "Server on-line"
		  send_notification "Server on-line"
		  echo "$dt Server on-line. " >> $logs_file
	  else
		  echo "Server back on-line"
		  echo "$dt Server back on-line. " >> $logs_file
		  send_notification "The Server is back on-line, IP: $ip:$PORT"
		  touch file
	  fi
	else
	  if [[ -f file ]]; then
	    echo "error"
	    echo "$dt Server off_line. " >> $logs_file
	    send_notification "The Server went off-line"
	    rm file
	  else
	    echo "Server still off-line"
            echo "$dt Server still off-line. " >> $logs_file
	  fi
	fi
}

ip=$(curl ipinfo.io/ip)

if [[ $1 == '-h' ]]; then
	help
	exit
elif [[ $1 == "-t" ]]; then
	old_ip='<test>'
	main
elif [[ $1 == "-e" ]]; then
	nano $conf_file
	exit
elif [[ $1 == "-l" ]]; then
	cat $logs_file
	exit
elif [[ $1 == "-p" ]]; then
	ping_test
	exit
elif [[ $1 == "-i" ]]; then
	main
	exit
elif [[ $1 == "-c" ]]; then
	if [[ $2 == "-i" ]]; then
		if ! crontab -l | grep -q "$script_path -i"; then
			(crontab -l ; echo "$CRON_SET /bin/bash $script_path -i") | crontab -
			echo "IP cronjob set to: $CRON_SET."
			echo "$dt IP cronjob set to: $CRON_SET." >> $logs_file
		else
			echo "crontab allready exists"
		fi
	elif [[ $2 == "-p" ]]; then
		if ! crontab -l | grep -q "$script_path -p"; then
			(crontab -l ; echo "$CRON_SET /bin/bash $script_path -p") | crontab -
			echo "Ping conjob set to: $CRON_SET." 
			echo "$dt Ping conjob set to: $CRON_SET." >> $logs_file
		else
			echo "crontab allready exists"
		fi
	fi
	exit
fi

