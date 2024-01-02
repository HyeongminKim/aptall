#!/bin/bash

debugPath=/var/log/aptall
update=false
upgrade=false
cleanup=false
doctor=false
elapsedTime=
executePath=$(echo $0 | sed "s/\/aptall.sh//g")

cd $executePath

if [ "$1" == "version" ]; then
    echo -e "aptall (git revision $(git rev-parse --short HEAD), last commit $(git log -1 --date=format:"%Y-%m-%d" --format="%ad"), $(git branch --show-current) build)"
    echo -e "Copyright (c) 2021-$(date +%Y) Hyeongmin Kim\n"
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
    if [ -r $debugPath/cntRevision.txt ] && [ -r $debugPath/updatedRevision.txt ]; then
        cntRevision="$(cat $debugPath/cntRevision.txt)"
        updatedRevision="$(cat $debugPath/updatedRevision.txt)"

        "$executePath/tools/changelog.sh" "$cntRevision" "$updatedRevision"
    else
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo "아직 한번도 업데이트를 받은 적이 없기 때문에 표시할 내용이 없는 것 같습니다."
        else
            echo "There is nothing to display because it has never received an update yet."
        fi
    fi
    exit 0
elif [ "$1" == "remove" ]; then
    if [ -x $executePath/tools/install.sh ]; then
        "$executePath/tools/install.sh" "uninstall"
    else
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\e[31m언인스톨러를 실행할 권한이 없습니다. \e[m"
        else
            echo -e "\e[31mCan't run uninstaller, Please change permission.\e[m"
        fi
    fi
    exit $?
elif [ x$1 == x ]; then
    echo "" > /dev/null 2>&1
elif [ "$1" == "help" ]; then
   xdg-open https://github.com/HyeongminKim/aptall\#usage-aptallsh-command 2> /dev/null
    if [ $? != 0 ]; then
        echo "URL: https://github.com/HyeongminKim/aptall#usage-aptallsh-command"
    fi
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
    echo -n "$resultCalculatedHour°$resultCalculatedMin'$resultCalculatedSec\" "
}

function compareTime() {
    currentElapsedTime=$elapsedTime
    if [ -r $debugPath/ElapsedTime.txt ]; then
        previousElapsedTime=$(cat $debugPath/ElapsedTime.txt 2> /dev/null)
        if [ $previousElapsedTime -gt $currentElapsedTime ]; then
            result=$(($previousElapsedTime-$currentElapsedTime))
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "\e[34m▼ $result 초\e[m"
            else
                echo -e "\e[31m▼ $result sec\e[m"
            fi
        elif [ $previousElapsedTime -lt $currentElapsedTime ]; then
            result=$(($currentElapsedTime-$previousElapsedTime))
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "\e[31m▲ $result 초\e[m"
            else
                echo -e "\e[32m▲ $result sec\e[m"
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

function executeExtension() {
    if [ $(id -u) -eq 0 ]; then
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo "root 권한으로는 추가 명령을 실행할 수 없습니다."
        else
            echo "Additional commands cannot be executed with root privileges."
        fi
        return 1
    fi
    if [ -r $debugPath/extension.csm ]; then
        shasum -a 256 $executePath/tools/extension.sh > $debugPath/extension_src.csm
        diff $debugPath/extension.csm $debugPath/extension_src.csm > /dev/null
        if [ $? != 0 ]; then
            extensionVerification
        else
            "$executePath/tools/extension.sh"
        fi
        rm $debugPath/extension_src.csm
    else
        extensionVerification
    fi
}

function extensionVerification {
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo "extension.sh 체크섬: $(shasum -a 256 $executePath/tools/extension.sh)"
    else
        echo "extension.sh checksum: $(shasum -a 256 $executePath/tools/extension.sh)"
    fi
    while true; do
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -n "실행할 작업(y: 실행, n: 중단, d: 훓어보기) > "
        else
            echo -n "Action to run(y: execute, n: abort, d: quicklook) > "
        fi
        read input
        if [ "$input" == "y" -o "$input" == "Y" ]; then
            shasum -a 256 $executePath/tools/extension.sh > $debugPath/extension.csm
            cp $executePath/tools/extension.sh $debugPath/extension.sh.bak
            "$executePath/tools/extension.sh"
            break
        elif [ "$input" == "n" -o "$input" == "N" ]; then
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo "사용자가 extension.sh 파일 실행을 중단했습니다. "
            else
                echo "User aborted extension.sh file execution."
            fi
            break
        elif [ "$input" == "d" -o "$input" == "D" ]; then
            if [ -r $debugPath/extension.sh.bak ]; then
                cat $executePath/tools/extension.sh > $debugPath/extension.txt
                cat $debugPath/extension.sh.bak > $debugPath/extension_bak.txt
                if [ -r $debugPath/extension.txt -a -r $debugPath/extension_bak.txt ]; then
                    git diff --no-index $debugPath/extension_bak.txt $debugPath/extension.txt 2> /dev/null
                    if [ $? != 0 ]; then
                        if [ $LANG == "ko_KR.UTF-8" ]; then
                            echo "향상된 diff를 사용할 수 없어 레거시 diff로 대체됩니다."
                        else
                            echo "Enhanced diff is not available and is replaced by legacy diff."
                        fi
                        diff $debugPath/extension_bak.txt $debugPath/extension.txt
                    fi
                    rm $debugPath/extension.txt $debugPath/extension_bak.txt
                else
                    if [ $LANG == "ko_KR.UTF-8" ]; then
                        echo "필수 비교 파일에 접근할 수 없습니다. 파일 권한 설정을 확인하세요. "
                    else
                        echo "The required comparison file could not be accessed. Check the file permission settings."
                    fi
                fi
            else
                less $executePath/tools/extension.sh
            fi
        else
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo "알 수 없는 명령 $input 무시됨"
            else
                echo "Unknown command $input Skipping"
            fi
        fi
    done
}

if [ -r $debugPath/aptall.lock ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[31m의존성 패키지를 검증할 수 없기 때문에 종료되었습니다.\e[m"
    else
        echo -e "\e[31mExited because dependency package couldn't be verified.\e[m"
    fi
    exit 1
else
    touch $debugPath/aptall.lock
fi

startTime=$(date +%s)

ping -c 1 -W 1 -q "www.google.com" &> /dev/null
if [ "$?" != "0" ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -en "\e[31m인터넷 연결 확인... "
    else
        echo -en "\e[31mCheck your internet connection... "
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
                echo -e "\e[32m연결됨\e[m"
            else
                echo -e "\e[32mConnected\e[m"
            fi
            break
        fi
    done
fi

if [ -x $executePath/tools/install.sh ]; then
    "$executePath/tools/install.sh" "install"
    if [ $? != 0 ]; then
        rm $debugPath/aptall.lock
        exit $?
    fi
else
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[31m설정 및 로그 폴더가 존재하는지 확인할 수 없으므로 종료합니다. \e[m"
    else
        echo -e "\e[31mExit because it is not possible to check whether the settings and log folder exist.\e[m"
    fi
    rm $debugPath/aptall.lock
    exit 1
fi

if [ -r $debugPath/aptall_initiated.log ]; then
    cat $debugPath/aptall_initiated.log
fi
if [ $LANG == "ko_KR.UTF-8" ]; then
    echo -n "[33m이전 시간: $(date)[0m " > $debugPath/aptall_initiated.log
    echo -e "\e[32m시작 시간: $(date)\e[m"
else
    echo -n "[33m Previous time: $(date)[0m " > $debugPath/aptall_initiated.log
    echo -e "\e[32mInitiated time: $(date)\e[m"
fi

if [ $(id -u) -ne 0 ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo "스크립트를 계속 진행하려면 관리자 암호가 필요합니다. "
    else
        echo "An admin password is required to proceed with the script. "
    fi
    sudo echo "" &> /dev/null
    if [ $? != 0 ]; then
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\e[31m로그인에 실패하였습니다. 잠시후 다시 시도하세요. \e[m"
            echo "[31m[실패][0m " >> $debugPath/aptall_initiated.log
        else
            echo -e "\e[31mlogin failed. Please try again later.\e[m"
            echo "[31m[FAILED][0m " >> $debugPath/aptall_initiated.log
        fi
        rm $debugPath/aptall.lock
        exit 1
    fi
fi

if [ $(id -u) -ne 0 ]; then
    sudo apt update 2> $debugPath/apt_update_debug.log
else
    apt update 2> $debugPath/apt_update_debug.log
fi
if [ "$?" != "0" ]; then
    update=true
    cat $debugPath/apt_update_debug.log
else
    rm $debugPath/apt_update_debug.log
fi
if [ "$USE_FULL_UPGRADE" == "true" -o "$USE_FULL_UPGRADE" == "TRUE" ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[33m이 옵션을 사용할 경우 디바이스 저장공간이 부족할 수 있습니다. \e[m"
    else
        echo -e "\e[33mIf you use this option, your device may run out of storage space.\e[m"
    fi
    if [ $(id -u) -ne 0 ]; then
        sudo apt full-upgrade 2> $debugPath/apt_upgrade_debug.log
    else
        apt full-upgrade 2> $debugPath/apt_upgrade_debug.log
    fi
    if [ "$?" != "0" ]; then
        upgrade=true
        cat $debugPath/apt_upgrade_debug.log
    else
        rm $debugPath/apt_upgrade_debug.log
    fi
else
    if [ $(id -u) -ne 0 ]; then
        sudo apt upgrade -y 2> $debugPath/apt_upgrade_debug.log
    else
        apt upgrade -y 2> $debugPath/apt_upgrade_debug.log
    fi
    if [ "$?" != "0" ]; then
        upgrade=true
        cat $debugPath/apt_upgrade_debug.log
    else
        rm $debugPath/apt_upgrade_debug.log
    fi
fi

if [ $(id -u) -ne 0 ]; then
    sudo apt autoremove -y 2> $debugPath/apt_autoremove_debug.log
else
    apt autoremove -y 2> $debugPath/apt_autoremove_debug.log
fi
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
        echo -e "\e[31m자동 업데이트 도중 에러가 발생하였습니다. 수동으로 진행하여 주세요\e[m"
    else
        echo -e "\e[31mAn error occurred during automatic update. By going manually\e[m"
    fi
    xdg-open https://github.com/HyeongminKim/aptall
fi
if [ "$update" = true -o "$upgrade" = true -o "$cleanup" = true -o "$doctor" = true ]; then
    logFiles=$(ls $debugPath |grep apt_ |grep -c debug.log)
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[31maptall이 실패했거나 경고가 발생하였습니다.\e[m\naptall 로그 파일이 \e[0;1m$debugPath\e[m 에 위치해 있습니다. "
        echo "----- apt 로그 목록 -----"
    else
        if [ $logFiles == 1 ]; then
            echo -e "\e[31maptall has failed and/or occurred warning.\e[m\naptall log file located \e[0;1m$debugPath\e[m"
            echo "----- apt log list -----"
        else
            echo -e "\e[31maptall has failed and/or occurred warning.\e[m\naptall log files located \e[0;1m$debugPath\e[m"
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
        executeExtension
        if [ $? != 0 ]; then
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "\e[31m익스텐션을 로드하는 도중 에러가 발생하였습니다. \e[m"
            else
                echo -e "\e[31mAn error occurred while loading the extension.\e[m"
            fi
        fi
    elif [ $(id -u) -ne 0 ]; then
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "추가 명령을 실행하고 싶으시면 extension.sh 파일을 \e[0;1m$executePath/tools\e[m 디렉토리 안에 두십시오. "
        else
            echo -e "If you want to run additional commands, place the extension.sh file in the \e[0;1m$executePath/tools\e[m directory."
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
    rm $debugPath/aptall.lock
    exit 1
else
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[34maptall 이 성공하였습니다.\e[m"
    else
        echo -e "\e[34maptall has successful.\e[m"
    fi
    if [ -x $executePath/tools/extension.sh ]; then
        executeExtension
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
            rm $debugPath/aptall.lock
            exit 0
        else
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "\e[31m익스텐션을 로드하는 도중 에러가 발생하였습니다. \e[m"
                echo "[31m[실패][0m " >> $debugPath/aptall_initiated.log
            else
                echo -e "\e[31mAn error occurred while loading the extension.\e[m"
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
            rm $debugPath/aptall.lock
            exit 1
        fi
    else
        if [ $(id -u) -ne 0 ]; then
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "추가 명령을 실행하고 싶으시면 extension.sh 파일을 \e[0;1m$executePath/tools\e[m 디렉토리 안에 두심시오. "
            else
                echo -e "If you want to run additional commands, place the extension.sh file in the \e[0;1m$executePath/tools\e[m directory."
            fi
        fi
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
        rm $debugPath/aptall.lock
        exit 0
    fi
fi
