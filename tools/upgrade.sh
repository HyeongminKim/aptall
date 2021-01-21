#!/bin/bash

cd $1
last_commit=$(git rev-parse HEAD)
last_version=$(git rev-parse --short HEAD)
dirCreated=false
cntBranch=$(git branch | sed '/* /!d'| sed 's/* //g')

function showCommit() {
    releasePath=/var/log/aptall
    if [ -d $releasePath ]; then
        echo "" > /dev/null
    else
        sudo mkdir /var/log/aptall
        sudo chown -R $(whoami) /var/log/aptall
        dirCreated=true
    fi
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\033[0;1m업데이트 채널\033[m" > $releasePath/releasenote.txt
    else
        echo -e "\033[0;1mUpdate channel\033[m" > $releasePath/releasenote.txt
    fi
    echo -e "\033[0;4m$cntBranch\033[m\n" >> $releasePath/releasenote.txt

    if [ -z "$(git log -1 --grep="ADD" --no-merges --pretty=format:"%h" $updated_commit...$last_commit)" ]; then
        echo "" > /dev/null
    else
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\033[0;1m새로운 기능\033[m" >> $releasePath/releasenote.txt
        else
            echo -e "\033[0;1mNew features\033[m" >> $releasePath/releasenote.txt
        fi
        git log --stat --color --grep="ADD" --no-merges --pretty=format:"%C(magenta)%h%Creset - %C(cyan)%an%Creset [%C(red)%ar%Creset]: %C(green)%s%Creset" $updated_commit...$last_commit >> $releasePath/releasenote.txt
        echo "" >> $releasePath/releasenote.txt
    fi

    if [ -z "$(git log -1 --grep="UPDATE" --no-merges --pretty=format:"%h" $updated_commit...$last_commit)" ]; then
        echo "" > /dev/null
    else
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\033[0;1m업데이트된 기능\033[m" >> $releasePath/releasenote.txt
        else
            echo -e "\033[0;1mUpdated features\033[m" >> $releasePath/releasenote.txt
        fi
        git log --stat --color --grep="UPDATE" --no-merges --pretty=format:"%C(magenta)%h%Creset - %C(cyan)%an%Creset [%C(red)%ar%Creset]: %C(green)%s%Creset" $updated_commit...$last_commit >> $releasePath/releasenote.txt
        echo "" >> $releasePath/releasenote.txt
    fi

    if [ -z "$(git log -1 --grep="DELETE" --no-merges --pretty=format:"%h" $updated_commit...$last_commit)" ]; then
        echo "" > /dev/null
    else
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\033[0;1m삭제된 기능\033[m" >> $releasePath/releasenote.txt
        else
            echo -e "\033[0;1mRemoved features\033[m" >> $releasePath/releasenote.txt
        fi
        git log --stat --color --grep="DELETE" --no-merges --pretty=format:"%C(magenta)%h%Creset - %C(cyan)%an%Creset [%C(red)%ar%Creset]: %C(green)%s%Creset" $updated_commit...$last_commit >> $releasePath/releasenote.txt
        echo "" >> $releasePath/releasenote.txt
    fi

    if [ "$(git branch | sed '/* /!d'| sed 's/* //g')" == "nightly" ]; then
        if [ -z "$(git log -1 --grep="TEST" --no-merges --pretty=format:"%h" $updated_commit...$last_commit)" ]; then
            echo "" > /dev/null
        else
            if [ $LANG == "ko_KR.UTF-8" ]; then
                echo -e "\033[0;1m실험중인 기능\033[m" >> $releasePath/releasenote.txt
            else
                echo -e "\033[0;1mTesting features\033[m" >> $releasePath/releasenote.txt
            fi
            git log --stat --color --grep="TEST" --no-merges --pretty=format:"%C(magenta)%h%Creset - %C(cyan)%an%Creset [%C(red)%ar%Creset]: %C(green)%s%Creset" $updated_commit...$last_commit >> $releasePath/releasenote.txt
            echo "" >> $releasePath/releasenote.txt
        fi
    fi

    # less -R $releasePath/releasenote.txt
    cat $releasePath/releasenote.txt
}

function donation() {
    donateLink="https://www.paypal.com/paypalme/hmDonate"

    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "이 프로젝트에 기부하시고 싶나요? 페이팔에서 기부: \033[4;34m$donateLink\033[m"
    else
        echo -e "Would you like to donate to this project? Donate from PayPal: \033[4;34m$donateLink\033[m"
    fi
}

if [ $LANG == "ko_KR.UTF-8" ]; then
    echo -e "\033[32maptall 업데이트중"
else
    echo -e "\033[32mUpdating aptall"
fi
if git pull --rebase --stat origin $cntBranch; then
    updated_commit=$(git rev-parse HEAD)
    if [ "$updated_commit" = "$last_commit" ]; then
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\033[34maptall은 이미 최신 버전입니다.\033[m"
        else
            echo -e "\033[34maptall is already up to date.\033[m"
        fi
        donation
        exit 0
    else
        updated_version=$(git rev-parse --short HEAD)
        showCommit
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\033[34maptall이 성공적으로 업데이트 되었습니다.\033[m"
            if [ $dirCreated == false ]; then
                echo -e "release note를 다시 보시려면 \033[0;1m$1/aptall.sh changelog\033[m 명령을 사용하십시오."
            fi
        else
            echo -e "\033[34maptall has been updated. \033[m"
            if [ $dirCreated == false ]; then
                echo -e "You can see the release note again with \033[0;1m$1/aptall.sh changelog\033[m command."
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
        echo -e "\033[31m에러가 발생하였습니다. 잠시후 다시 시도하시겠습니까?\033[m"
    else
        echo -e "\033[31mThere was an error occured. Try again later?\033[m"
    fi
    exit 1
fi
