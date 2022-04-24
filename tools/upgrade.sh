#!/bin/bash

last_commit=$(git rev-parse HEAD)
last_version=$(git rev-parse --short HEAD)
executePath=$(echo $0 | sed "s/\/tools\/upgrade.sh//g")
cntBranch=$(git branch | sed '/* /!d'| sed 's/* //g')
dirCreated=false

cd $executePath

function showCommit() {
    releasePath=/var/log/aptall
    if [ -d $releasePath ]; then
        echo "" > /dev/null
    else
        sudo mkdir /var/log/aptall
        sudo chown -R $(whoami) /var/log/aptall
        dirCreated=true
    fi

    "$executePath/tools/changelog.sh" "$1" "$2"
    echo $1 > $releasePath/cntRevision.txt
    echo $2 > $releasePath/updatedRevision.txt
}

function donation() {
    donateLink="https://www.paypal.com/paypalme/hmDonate"

    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "이 프로젝트에 기부하시고 싶나요? 페이팔에서 기부: \e[4;34m$donateLink\e[m"
    else
        echo -e "Would you like to donate to this project? Donate from PayPal: \e[4;34m$donateLink\e[m"
    fi
}

if [ $LANG == "ko_KR.UTF-8" ]; then
    echo -e "\e[32maptall 업데이트중"
else
    echo -e "\e[32mUpdating aptall"
fi
if git pull --rebase --stat origin $cntBranch; then
    updated_commit=$(git rev-parse HEAD)
    if [ "$updated_commit" = "$last_commit" ]; then
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\e[34maptall은 이미 최신 버전입니다.\e[m"
        else
            echo -e "\e[34maptall is already up to date.\e[m"
        fi
        donation
        exit 0
    else
        updated_version=$(git rev-parse --short HEAD)
        showCommit "$last_commit" "$updated_commit"
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\e[34maptall이 성공적으로 업데이트 되었습니다.\e[m"
            if [ $dirCreated == false ]; then
                echo -e "release note를 다시 보시려면 \e[0;1m$1/aptall.sh changelog\e[m 명령을 사용하십시오."
            fi
        else
            echo -e "\e[34maptall has been updated. \e[m"
            if [ $dirCreated == false ]; then
                echo -e "You can see the release note again with \e[0;1m$1/aptall.sh changelog\e[m command."
            fi
        fi
        echo "$last_version → $updated_version"
        donation
        if [ $dirCreated == true ]; then
            rm -rf /var/log/aptall
        fi
        exit 2
    fi
else
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[31m에러가 발생하였습니다. 잠시후 다시 시도하시겠습니까?\e[m"
    else
        echo -e "\e[31mThere was an error occurred. Try again later?\e[m"
    fi
    exit 1
fi

