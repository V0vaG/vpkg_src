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


