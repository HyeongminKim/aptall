#!/bin/bash

beforeCommit="$1"
updatedCommit="$2"
executePath=$(echo $0 | sed "s/\/tools\/changelog.sh//g")
cntBranch=$(git branch --show-current)
releasePath=/var/log/aptall

cd $executePath

function releaseCommitFormatter() {
    git log --stat --color --grep="$1" --no-merges --pretty=format:"%C(magenta)%h%Creset - %C(cyan)%an%Creset [%C(red)%ar%Creset]: %C(green)%s%Creset" $updatedCommit...$beforeCommit | sed "s/\[$1\] //" >> $releasePath/releasenote.txt
}

if [ "$beforeCommit" == "$updatedCommit" ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[31m동일한 리비전을 비교하는 중입니다. \e[m"
    else
        echo -e "\e[31mComparing the same revision. \e[m"
    fi
    exit 1
fi

if [ $LANG == "ko_KR.UTF-8" ]; then
    echo -e "\e[0;1m업데이트 채널\e[m" > $releasePath/releasenote.txt
else
    echo -e "\e[0;1mUpdate channel\e[m" > $releasePath/releasenote.txt
fi
echo -e "\e[0;4m$cntBranch\e[m\n" >> $releasePath/releasenote.txt
if [ "$cntBranch" == "nightly" ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[33m경고: nightly 채널은 불안정합니다. 이 채널을 사용할 경우 예기치 않은 동작 또는 파일 유실, 더미 파일 생성 등이 나타날 수 있습니다.\e[m" > $releasePath/releasenote.txt
    else
        echo -e "\e[33mWarning: The nightly channel is unstable. Using this channel can lead to unexpected behavior or loss of files, dummy file creation, etc.\e[m" > $releasePath/releasenote.txt
    fi
fi

if ! [ -z "$(git log -1 --grep="ADD" --no-merges --pretty=format:"%h" $updatedCommit...$beforeCommit)" ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[0;1m새로운 기능\e[m" >> $releasePath/releasenote.txt
    else
        echo -e "\e[0;1mNew features\e[m" >> $releasePath/releasenote.txt
    fi
    releaseCommitFormatter "ADD"
    echo "" >> $releasePath/releasenote.txt
fi

if ! [ -z "$(git log -1 --grep="UPDATE" --no-merges --pretty=format:"%h" $updatedCommit...$beforeCommit)" ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[0;1m업데이트된 기능\e[m" >> $releasePath/releasenote.txt
    else
        echo -e "\e[0;1mUpdated features\e[m" >> $releasePath/releasenote.txt
    fi
    releaseCommitFormatter "UPDATE"
    echo "" >> $releasePath/releasenote.txt
fi

if ! [ -z "$(git log -1 --grep="DELETE" --no-merges --pretty=format:"%h" $updatedCommit...$beforeCommit)" ]; then
    if [ $LANG == "ko_KR.UTF-8" ]; then
        echo -e "\e[0;1m삭제된 기능\e[m" >> $releasePath/releasenote.txt
    else
        echo -e "\e[0;1mRemoved features\e[m" >> $releasePath/releasenote.txt
    fi
    releaseCommitFormatter "DELETE"
    echo "" >> $releasePath/releasenote.txt
fi

if [ "$cntBranch" == "nightly" ]; then
    if ! [ -z "$(git log -1 --grep="TEST" --no-merges --pretty=format:"%h" $updatedCommit...$beforeCommit)" ]; then
        if [ $LANG == "ko_KR.UTF-8" ]; then
            echo -e "\e[0;1m실험중인 기능\e[m" >> $releasePath/releasenote.txt
        else
            echo -e "\e[0;1mTesting features\e[m" >> $releasePath/releasenote.txt
        fi
        releaseCommitFormatter "TEST"
        echo "" >> $releasePath/releasenote.txt
    fi
fi

cat $releasePath/releasenote.txt
rm $releasePath/releasenote.txt
