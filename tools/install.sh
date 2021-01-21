#!/bin/bash

debugPath=/var/log/aptall
executePath=$(echo $0 | sed "s/\/tools\/install.sh//g")
versionChecked=false

if [ "$(uname -s)" != "Linux" ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\033[31m$(uname -s) 는 아직 지원하지 않습니다. \033[m"
    else
        echo -e "\033[31m$(uname -s) does not support yet.\033[m"
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
            echo -e "\033[33m변경 사항을 적용하기 위해 다시 실행하여 주세요. \033[m"
        else
            echo -e "\033[33mPlease run again to apply the changes.\033[m"
        fi
        exit 2
    fi
}

if [ "$1" == "install" ]; then
    if [ -r /etc/aptall/initializationed ]; then
        echo "" > /dev/null
    else
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

        mkdir /etc/aptall 
        touch /etc/aptall/initializationed
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "aptall 설정 폴더를 생성하였습니다. 설정 폴더는 \033[0;1m/etc/aptall/initializationed\033[m에 위치할 것입니다. "
        else
            echo -e "aptall config folder created. This config folder path is \033[0;1m/etc/aptall/initializationed\033[m"
        fi
    fi

    if [ -d $debugPath ]; then
        echo "" > /dev/null
    else
        mkdir /var/log/aptall 
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "aptall 로그 폴더를 생성하였습니다. 모든 로그 파일들은 \033[0;1m$debugPath\033[m에 위치할 것입니다. "
        else
            echo -e "aptall log folder created. All logs file are located in \033[0;1m$debugPath\033[m"
        fi
    fi
elif [ "$1" == "uninstall" ]; then
    if [ -w $debugPath ]; then
        rm -rf $debugPath
    fi
fi
