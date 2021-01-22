#!/bin/bash

debugPath=/var/log/aptall
update=false
upgrade=false
cleanup=false
doctor=false
elapsedTime=
executePath=$(echo $0 | sed "s/\/aptall.sh//g")

if [ "$1" == "version" ]; then
    cd $executePath
    echo -e "aptall (git revision $(git rev-parse --short HEAD), last commit $(git log -1 --date=format:"%Y-%m-%d" --format="%ad"))\nCopyright (c) 2021 Hyeongmin Kim\n"
    bash --version
    echo ""
    apt --version
    echo ""
    git --version
    exit 0
elif [ "$1" == "runtime" ]; then
    if [ -r $debugPath/aptall_initiated.log ]; then
        cat $debugPath/aptall_initiated.log 2> /dev/null
    fi
    exit 0
elif [ "$1" == "changelog" ]; then
    if [ -r $debugPath/releasenote.txt ]; then
        less -R $debugPath/releasenote.txt
    fi
    exit 0
elif [ "$1" == "remove" ]; then
    if [ -x $executePath/tools/install.sh ]; then
        "$executePath/tools/install.sh" "uninstall"
    else
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\033[31m언인스톨러를 실행할 권한이 없습니다. \033[m"
        else
            echo -e "\033[31mCan't run uninstaller, Please change permission.\033[m"
        fi
    fi
    exit $?
elif [ x$1 == x ]; then
    echo "" > /dev/null 2>&1
elif [ "$1" == "help" ]; then
    xdg-open https://github.com/HyeongminKim/aptall\#usage-aptallsh-command-option
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo "사용법: $0 [명령]"
    else
        echo "USAGE: $0 [COMMAND]"
    fi
    exit 0
else
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo "$@ 은 알 수 없는 명령이며 무시됩니다. "
        echo "aptall의 도움말을 보시려면 help 명령을 사용하십시오. "
    else
        echo "Unknown command $@ Skipping."
        echo "If you wonder aptall help, Please use help command. "
    fi
fi

function calcTime() {
    willConvertStartSecond=$1
    willConvertEndSecond=$2
    calculatedElapsedSecond=$(($willConvertStartSecond-$willConvertEndSecond))
    elapsedTime=$calculatedElapsedSecond
    resultCalculatedHour=$(($calculatedElapsedSecond/3600))
    calculatedElapsedSecond=$(($calculatedElapsedSecond%3600))
    resultCalculatedMin=$(($calculatedElapsedSecond/60))
    calculatedElapsedSecond=$(($calculatedElapsedSecond%60))
    resultCalculatedSec=$calculatedElapsedSecond
    echo -n "$resultCalculatedHour:$resultCalculatedMin'$resultCalculatedSec\" "
}

function compareTime() {
    currenrtElapsedTime=$elapsedTime
    if [ -r $debugPath/ElapsedTime.txt ]; then
        previousElapsedTime=$(cat $debugPath/ElapsedTime.txt 2> /dev/null)
        if [ $previousElapsedTime -gt $currenrtElapsedTime ]; then
            result=$(($previousElapsedTime-$currenrtElapsedTime))
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "\033[34m▼ $result 초\033[m"
            else
                echo -e "\033[31m▼ $result sec\033[m"
            fi
        elif [ $previousElapsedTime -lt $currenrtElapsedTime ]; then
            result=$(($currenrtElapsedTime-$previousElapsedTime))
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "\033[31m▲ $result 초\033[m"
            else
                echo -e "\033[32m▲ $result sec\033[m"
            fi
        else
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo "- 0 초"
            else
                echo "- 0 sec"
            fi
        fi
    else
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo "- 0 초"
        else
            echo "- 0 sec"
        fi
    fi
    echo "$elapsedTime" > $debugPath/ElapsedTime.txt

}

startTime=$(date +%s)

ping -c 1 -W 1 -q "www.google.com" &> /dev/null
if [ "$?" != "0" ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -en "\033[31m인터넷 연결 확인... "
    else
        echo -en "\033[31mCheck your internet connection... "
    fi
    index=0
    spinner='/-\|'
    n=${#spinner}
    echo -n ' '
    while true; do
        ping -c 1 -W 1 -q "www.google.com" &> /dev/null
        if [ "$?" != "0" ]; then
            printf '\b%s' "${spinner:i++%n:1}"
            sleep 1
        else
            printf '\b\b\b\b%s' " "
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "\033[32m연결됨\033[m"
            else
                echo -e "\033[32mConnected\033[m"
            fi
            break
        fi
    done
fi

if [ -x $executePath/tools/install.sh ]; then
    "$executePath/tools/install.sh" "install"
    if [ $? != 0 ]; then
        exit $?
    fi
else
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\033[31m의존성 패키지가 제대로 설치되어 있는지 확인할 수 없어 종료합니다. \033[m"
    else
        echo -e "\033[31mExited because dependency package couldn't be verified.\033[m"
    fi
    exit 1
fi

if [ -r $debugPath/aptall_initiated.log ]; then
    cat $debugPath/aptall_initiated.log
fi
if [ $LANG == "ko_KR.UTF-8" ]; then
    echo -n "[33m이전 시간: $(date)[0m " > $debugPath/aptall_initiated.log
    echo -e "\033[32m시작 시간: $(date)\033[m"
else
    echo -n "[33m Previous time: $(date)[0m " > $debugPath/aptall_initiated.log
    echo -e "\033[32mInitiated time: $(date)\033[m"
fi

sudo apt update 2> $debugPath/apt_update_debug.log
if [ "$?" != "0" ]; then
    update=true
    cat $debugPath/apt_update_debug.log
else
    rm $debugPath/apt_update_debug.log
fi
sudo apt upgrade 2> $debugPath/apt_upgrade_debug.log
if [ "$?" != "0" ]; then
    upgrade=true
    cat $debugPath/apt_upgrade_debug.log
else
    rm $debugPath/apt_upgrade_debug.log
fi
sudo apt autoremove -s 2> $debugPath/apt_autoremove_debug.log
if [ "$?" != "0" ]; then
    cleanup=true
    cat $debugPath/apt_autoremove_debug.log
else
    rm $debugPath/apt_autoremove_debug.log
fi

if [ -x $executePath/tools/upgrade.sh ]; then
    "$executePath/tools/upgrade.sh" "$executePath"
else
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\033[31m자동 업데이트 도중 에러가 발생하였습니다. 수동으로 진행하여 주세요\033[m"
    else
        echo -e "\033[31mAn error occurred during automatic update. By going manually\033[m"
    fi
    xdg-open https://github.com/HyeongminKim/aptall
fi
if [ "$update" = true -o "$upgrade" = true -o "$cleanup" = true -o "$doctor" = true ]; then
    logFiles=$(ls $debugPath |grep apt_ |grep -c debug.log)
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\033[31maptall이 실패했거나 경고가 발생하였습니다.\033[m\naptall 로그 파일이 \033[0;1m$debugPath\033[m 에 위치해 있습니다. "
        echo "----- apt 로그 목록 -----"
    else
        if [ $logFiles == 1 ]; then
            echo -e "\033[31maptall has failed and/or occurred warning.\033[m\naptall log file located \033[0;1m$debugPath\033[m"
            echo "----- apt log list -----"
        else
            echo -e "\033[31maptall has failed and/or occurred warning.\033[m\naptall log files located \033[0;1m$debugPath\033[m"
            echo "----- apt logs list -----"
        fi
    fi
    ls -lh $debugPath | awk '{print $9 " ("$5")"}' |grep apt_ |grep debug.log
    if [ $logFiles == 1 ]; then
        echo "-------------------------"
    else
        echo "--------------------------"
    fi
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo "[31m[실패][0m " >> $debugPath/aptall_initiated.log
    else
        echo "[31m[FAILED][0m " >> $debugPath/aptall_initiated.log
    fi
    if [ -x $executePath/tools/extension.sh ]; then
        "$executePath/tools/extension.sh"
        if [ $? != 0 ]; then
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "\033[31m익스텐션을 로드하는 도중 에러가 발생하였습니다. \033[m"
                echo "[31m[실패][0m " >> $debugPath/aptall_initiated.log
            else
                echo -e "\033[31mAn error occurred while loading the extension.\033[m"
                echo "[31m[FAILED][0m " >> $debugPath/aptall_initiated.log
            fi
        fi
    fi
    endTime=$(date +%s)
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -n "소비 시간: "
    else
        echo -n "Elapsed Time: "
    fi
    calcTime $endTime $startTime
    compareTime
    exit 1
else
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\033[34maptall 이 성공하였습니다.\033[m"
    else
        echo -e "\033[34maptall has successful.\033[m"
    fi
    if [ -x $executePath/tools/extension.sh ]; then
        "$executePath/tools/extension.sh"
        if [ $? == 0 ]; then
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo "[34m[성공][0m " >> $debugPath/aptall_initiated.log
            else
                echo "[34m[SUCCEED][0m " >> $debugPath/aptall_initiated.log
            fi
            endTime=$(date +%s)
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -n "소비 시간: "
            else
                echo -n "Elapsed Time: "
            fi
            calcTime $endTime $startTime
            compareTime
            exit 0
        else
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "\033[31m익스텐션을 로드하는 도중 에러가 발생하였습니다. \033[m"
                echo "[31m[실패][0m " >> $debugPath/aptall_initiated.log
            else
                echo -e "\033[31mAn error occurred while loading the extension.\033[m"
                echo "[31m[FAILED][0m " >> $debugPath/aptall_initiated.log
            fi
            endTime=$(date +%s)
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -n "소비 시간: "
            else
                echo -n "Elapsed Time: "
            fi
            calcTime $endTime $startTime
            compareTime
            exit 1
        fi
    else
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo "[34m[성공][0m " >> $debugPath/aptall_initiated.log
        else
            echo "[34m[SUCCEED][0m " >> $debugPath/aptall_initiated.log
        fi
        endTime=$(date +%s)
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -n "소비 시간: "
        else
            echo -n "Elapsed Time: "
        fi
        calcTime $endTime $startTime
        compareTime
        exit 0
    fi
fi
