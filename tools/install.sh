#!/bin/bash

debugPath=/var/log/aptall
executePath=$(echo $0 | sed "s/\/tools\/install.sh//g")
versionChecked=false

if [ "$(uname -s)" != "Linux" ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[31m$(uname -s) 는 아직 지원하지 않습니다. \e[m"
    else
        echo -e "\e[31m$(uname -s) does not support yet.\e[m"
    fi
    exit 1
fi

function checkVersion() {
    if [ $versionChecked == true ]; then
        return
    fi
    versionChecked=true
    "$executePath/tools/upgrade.sh" "$executePath"
    if [ $? == 0 ]; then
        return
    elif [ $? == 1 ]; then
        exit 1
    else
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\e[33m변경 사항을 적용하기 위해 다시 실행하여 주세요. \e[m"
        else
            echo -e "\e[33mPlease run again to apply the changes.\e[m"
        fi
        exit 2
    fi
}

if [ "$1" == "install" ]; then
    if [ ! -r /etc/aptall/initializationed ]; then
        checkVersion
        curl -fsSkL https://raw.githubusercontent.com/HyeongminKim/aptall/master/LICENSE
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -en "\naptall 프로젝트 및 스크립트는 위의 MIT 라이선스에 귀속됩니다. \n 위 라이선스에 동의하십니까? (Y/n) > "
        else
            echo -en "\nThe aptall projects and scripts belong to the MIT license above. \nDo you accept the above license? (Y/n) > "
        fi
        read n
        if [ "$n" == "N" -o "$n" == "n" ]; then
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo "라이선스에 동의해야 aptall 프로젝트 및 스크립트를 사용할 수 있습니다. "
            else
                echo "You should agree to the license before you can use aptall project and scripts."
            fi
            exit 1
        fi

        if [ $(id -u) -eq 0 ]; then
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -en "root 권한으로 설치할 경우 예기치 않은 문제가 발생할 수 있습니다. \n 계속하시겠습니까? (y/N) > "
            else
                echo -en "Unexpected problems may occur if you install with root privileges. \n Are you sure you want to continue? (y/N) > "
            fi
        fi
        read n
        if [ ! "$n" == "y" -o "$n" == "Y" ]; then
            exit 1
        fi

        if [ $(id -u) -ne 0 ]; then
            sudo mkdir /etc/aptall
            sudo chown -R $(whoami) /etc/aptall
        else
            mkdir /etc/aptall
        fi
        touch /etc/aptall/initializationed
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "aptall 설정 폴더를 생성하였습니다. 설정 폴더는 \e[0;1m/etc/aptall/initializationed\e[m에 위치할 것입니다. "
        else
            echo -e "aptall config folder created. This config folder path is \e[0;1m/etc/aptall/initializationed\e[m"
        fi
    fi

    if [ ! -d $debugPath ]; then
        if [ $(id -u) -ne 0 ]; then
            sudo mkdir /var/log/aptall
            sudo chown -R $(whoami) /var/log/aptall
        else
            mkdir /var/log/aptall
        fi
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "aptall 로그 폴더를 생성하였습니다. 모든 로그 파일들은 \e[0;1m$debugPath\e[m에 위치할 것입니다. "
        else
            echo -e "aptall log folder created. All logs file are located in \e[0;1m$debugPath\e[m"
        fi
    fi
elif [ "$1" == "uninstall" ]; then
    if [ -w $debugPath ]; then
        rm -rf $debugPath
    fi
fi
