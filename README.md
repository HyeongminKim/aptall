# aptall
## This shell script helps you update your apt package manager.
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/hmDonate)
### Installation
- [Download](https://github.com/HyeongminKim/aptall/archive/master.zip) the latest version of aptall package.
    - Place the aptall package where you want it.
- Or in terminal run below command.

    ```
    git clone https://github.com/HyeongminKim/aptall.git [destination]
    ```
- Now enjoy it
### Trouble shooting
- If you see the **permission denied** error message run command like below.

    ```
    chmod 755 foo.sh
    ```
### Usage: aptall.sh \[command\]
- version: Print this script version and environment version. 
- runtime: Print previous aptall launch time. 
- changelog: View update changes
- remove: aptall config remove.
- help: Print this help.
### Update channels
- First, run the ``git remote update`` command to access the remote branch.
- You can check the supported update channels with the `git branch -r` command.
- You can change the update channel with the ``git checkout -t origin/<branch>`` command.
### Description of the script used
|File Name|Note|
|:----:|:-----|
|aptall.sh|This script is a root script, please only start with this script. (If you run it with another script, it will not work properly.)|
|tools/install.sh|Initial setup and required packages are installed. If the requirements are not met during the check, this script will assist you with the installation.|
|tools/upgrade.sh|Update the locally installed aptall repository to the latest version. See [here](https://github.com/HyeongminKim/aptall\#update-channels) how to change channels.|
|tools/extension.sh|Allows the user to write additional shell scripts, which is optional.|

### License
This work is licensed under a [MIT License](https://github.com/HyeongminKim/aptall/blob/master/LICENSE).
