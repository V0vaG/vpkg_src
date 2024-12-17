#!/bin/bash
################################
# Author: Vladimir Glayzer     #
# eMail: its_a_vio@hotmail.com #
################################
# made with v-pkg version: 3.3.6

install_path='/usr/bin'
TMP_SCRIPT_PATH='/tmp'
TMP_DIR='/tmp/tmp_app'
file_list=( char_1.0.12.sh cip_1.3.14.sh agit_1.0.14.sh )

help(){
echo "################################
# Author: Vladimir Glayzer     #
# eMail: its_a_vio@hotmail.com #
################################
made with v-pkg vova-packege

1. [-h] Print help.
	$ $0 -h
	
2. [-p] Generate .deb packege.
	$ $0 -p

3. [-h] Print number of packeges.
	$ $0 -n
	
"
}

if [[ $1 = -p ]]; then
        pack=true
elif [[ $1 = -n ]]; then
	echo ${#file_list[@]}
	exit
elif [[ $1 = -h ]]; then
	help
	exit
fi

make_char_1.0.12(){
print_to_file $LINENO $1
: << "COMMENT"
#!/bin/bash

version='1.0.12'
#alias="${0%%_*}" 
alias="char"

if [[ $1 == '-v' ]]; then
	echo $version
	exit
elif [[ $1 == '-h' ]]; then
	help
	exit
fi

    # Get the directory from the first command-line argument, default to current directory if none provided
    DIR="${1:-.}"

    # Check if the provided argument is a directory
    if [ ! -d "$DIR" ]; then
        echo "Error: $DIR is not a directory."
        exit 1
    fi

    # Read user input for characters to replace
    read -p "Enter old char (default ' '): " old_char
    if [[ ! $old_char ]]; then
        old_char=' '
    fi

    read -p "Enter new char (default '_'): " new_char
    if [[ ! $new_char ]]; then
        new_char='_'
    fi

    # Function to rename directories (deepest first)
    rename_dirs() {
        local base_dir="$1"
        
        # Find and list directories with spaces
        find "$base_dir" -depth -type d -name "*$old_char*" | sort -r > directories.txt
        
        # Process the directories
        while IFS= read -r dir; do
            local new_dir=$(echo "$dir" | sed "s/$old_char/$new_char/g")
            if [ "$dir" != "$new_dir" ]; then
                echo "Renaming directory '$dir' to '$new_dir'"
                mv "$dir" "$new_dir"
            fi
        done < directories.txt
    }

    # Function to rename files
    rename_files() {
        local base_dir="$1"
        
        # Find and list files with spaces
        find "$base_dir" -type f -name "*$old_char*" > files.txt
        
        # Process the files
        while IFS= read -r file; do
            local new_file=$(echo "$file" | sed "s/$old_char/$new_char/g")
            if [ "$file" != "$new_file" ]; then
                echo "Renaming file '$file' to '$new_file'"
                mv "$file" "$new_file"
            fi
        done < files.txt
    }

    # Loop until no more files or directories need renaming
    while true; do
        # Rename directories
        rename_dirs "$DIR"

        # Rename files
        rename_files "$DIR"

        # Check if there are any remaining directories or files with spaces
        remaining_dirs=$(find "$DIR" -depth -type d -name "*$old_char*" | wc -l)
        remaining_files=$(find "$DIR" -type f -name "*$old_char*" | wc -l)

        if [ "$remaining_dirs" -eq 0 ] && [ "$remaining_files" -eq 0 ]; then
            break
        fi
        
        # Small delay to prevent rapid looping
        sleep 1
    done

    echo "Renaming complete."




COMMENT
}
make_cip_1.3.14(){
print_to_file $LINENO $1
: << "COMMENT"
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


COMMENT
}
make_agit_1.0.14(){
print_to_file $LINENO $1
: << "COMMENT"
#!/bin/bash

version='1.0.14'
#alias="${0%%_*}" 
alias="agit"

help(){
echo "a-git (auto git)
################################
# Author: Vladimir Glayzer     #
# eMail: its_a_vio@hotmail.com #
################################

Version: $version

This Script manages multi ripository push/pull commands.

0. Command:
	$ $alias
	> The script create an alias: *a_git*

1. [-e] Edit conf file
	$ $alias -e
	> The conf file will be created at first start of the script.
	> Edit the conf file before the first use to add your ripos path

2. [-push] push command
	$ $alias -push
	> git add, commit & push to all repos from "git_list"

3. [-pull] pull comand
	$ $alias -pull
	> git fetch & pull from all repos from "git_list"

4. [-c] add cronjob
	$ $alias -c [arg]

	4.1- add pull cronjob
		$ $alias -c -pull

	4.2- add push cronjob
		$ $alias -c -push

5. [-l] Print logs
	$ $alias -l
"
}

dt=$(date '+%d/%m/%Y %H:%M:%S');
FILES_PATH=~/script_files
logs_file="$FILES_PATH/auto_git.log"
conf_file="$FILES_PATH/auto_git.conf"

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
	echo "Creating conf file..."
	sleep 2
	echo "file_test='OK'
git_list=(
	'/home/vova/GIT/vova_sphere'
)
" > $conf_file

fi

source $conf_file
echo "Import config file... $file_test"
sleep 0.1
 
if [ ! $1 ]; then
	echo "Enter a flag or 'a_git -h' for help"
elif [ $1 == "-h" ]; then
	help
	exit
elif [ $1 == "-v" ]; then
	echo $version
	exit
elif [ $1 == "-e" ]; then
	nano $conf_file
	exit
elif [ $1 == "-l" ]; then
        cat $logs_file
elif [ $1 == "-push" ]; then
	echo "$dt pushing to ${git_list[@]}." >> $logs_file
	for git_ripo in "${git_list[@]}"; do
		echo "************************************"
		echo "pushing to $git_ripo"
		cd $git_ripo && git add . && git commit -m 'auto_cron_push' && git push
	done
elif [ $1 == "-pull" ]; then
	echo "$dt pulling from ${git_list[@]}." >> $logs_file
	for git_ripo in "${git_list[@]}"; do
		echo "************************************"
		echo "pulling from $git_ripo"
		cd $git_ripo && git fetch && git pull
	done
elif [ $1 == "-c" -a $2 ]; then
	if [ $2 == "-push" ];then
		echo "$dt adding crontab push job" >> $logs_file
		echo "adding crontab push job..."
		(crontab -l ; echo '14 23 * * * /bin/bash /usr/bin/a-git -push') | crontab
		echo "OK!"
	elif [ $2 == "-pull" ]; then
		echo "$dt adding crontab pull job" >> $logs_file
		echo "adding crontab push job..."
		(crontab -l ; echo '14 23 * * * /bin/bash /usr/bin/a-git -pull') | crontab
		echo "OK!"
	fi
fi



COMMENT
}

print_to_file() {
	EOF="COMMENT"
	i=$(($1+2))
	while :; do
		line=$(sed -n $i"p" $0)
		if [[ "$line" == "$EOF" ]]; then
			break
		fi
		sed -n $i"p" $0 >> /tmp/tmp_app.$2
		((i++))
	done
}

check_install_dialog() {
  if ! command -v dialog &> /dev/null; then
    echo "Dialog is not installed. Installing..."
    sudo apt-get update && sudo apt-get install -y dialog
    if [ $? -ne 0 ]; then
      echo "Failed to install dialog. Exiting."
      exit 1
    fi
  fi
}

check_install_dialog

make_pack(){
	echo "Creating pack for: $alias v: $version arch: $architecture"
	#if [[ $extension = sh ]]; then
        	#source "/tmp/tmp_app$1"
	#fi
  mkdir -p "/tmp/tmp_app/$install_path"
  if	[[ $extension = py* ]]; then
     cp -p "/tmp/py/tmp_app" "$TMP_SCRIPT_PATH/tmp_app/$install_path/$alias"
     rm -r /tmp/py
  else
    cp -p "/tmp/tmp_app$1" "$TMP_SCRIPT_PATH/tmp_app/$install_path/$alias"
  fi
  mkdir -p "/tmp/tmp_app/DEBIAN"

  echo "Package: $alias
Version: $version
Command: $alias
Architecture: $architecture
Maintainer: Vladimir Glayzer
Homepage: http://example.com
eMail: its_a_vio@hotmail.com
Description: $desc" > "$TMP_SCRIPT_PATH/tmp_app/DEBIAN/control"

  echo "chmod 777 $install_path/$alias
  mkdir -p ~/script_files" > "$TMP_SCRIPT_PATH/tmp_app/DEBIAN/postinst"

  chmod 775 "/tmp/tmp_app/DEBIAN/postinst"
  dpkg --build $TMP_SCRIPT_PATH/tmp_app
  rm $TMP_SCRIPT_PATH/tmp_app$1
  rm -r $TMP_SCRIPT_PATH/tmp_app
	if [[ $pack == true ]]; then
		echo "Creating file: $(pwd)/$alias-$version-$architecture.deb"
		cp $TMP_SCRIPT_PATH/tmp_app.deb $(pwd)/$alias-$version-$architecture.deb
	fi
	sudo apt-get install -f /tmp/tmp_app.deb
  rm $TMP_SCRIPT_PATH/tmp_app.deb
}

decript(){
  if [[ $extension = *x ]]; then
    read -s -p "Enter password: " pass
    echo "decripting ${1}x"
    openssl enc -d -aes-256-cbc -pbkdf2 -a -in "${1}x" -k "$pass" > "$1"
    rm "${1}x"
  fi
}

scripts(){
if [[ $ans ]]; then
  desc=N/A
    file=${file_list["(( $ans - 1 ))"]}
    filename=$(basename -- "$file")
    extension="${filename##*.}"
    filename="${filename%.*}"
    name_list=($(echo $filename | tr "_" " "))
    alias=${name_list[0]}
    version=${name_list[1]}
    architecture=$(dpkg --print-architecture)
    func_name="${file%.*}"
    if [[ $extension = c* ]]; then
      if [[ $extension = cx ]]; then
        make_$func_name cx
      else
        make_$func_name c
      fi
      decript "/tmp/tmp_app.c"
      gcc /tmp/tmp_app.c -o /tmp/tmp_app.o
      rm /tmp/tmp_app.c
      make_pack .o
    elif [[ $extension = py* ]]; then
      if [[ $extension = pyx ]]; then
        make_$func_name pyx
      else
        make_$func_name py
      fi
      decript "/tmp/tmp_app.py"
      pyinstaller --onefile --distpath /tmp/py --workpath /tmp/py/work /tmp/tmp_app.py
      rm /tmp/tmp_app.py
      make_pack
    elif [[ $extension = sh* ]]; then
      if [[ $extension = shx ]]; then
        make_$func_name shx
      else
        make_$func_name sh
      fi
      decript "/tmp/tmp_app.sh"
      make_pack .sh
    elif [[ $extension = bin* ]]; then
      if [[ $extension = binx ]]; then
        make_$func_name binx
      else
        result=$(make_$func_name bin 2>/dev/null)
      fi
      decript "/tmp/tmp_app.bin"

      make_pack .bin
    fi
  else
    exit
  fi
}

echo "SRC mode 
+------------------------------------------------+
| Nun Command  version type Description          |
+------------------------------------------------+
| 1.  char     v1.0.12 sh                        |
| 2.  cip      v1.3.14 sh                        |
| 3.  agit     v1.0.14 sh                        |
+------------------------------------------------+
0. EXIT"
read -p "Enter apt package num to install: " ans
echo

if [[ $ans ]]; then
	if [ ! $ans ] || [ $ans = 0 ]; then
		exit
	fi
  scripts
else
  clear
	exit
fi

