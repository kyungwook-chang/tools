#!/bin/csh -f

set cmd = (curl -u kyungwook222 https://api.github.com/user/repos -d \''{'\"name\":\"$1\"'}'\')
eval "$cmd"
#echo \'\{\"name\":\"$1\"\}\'
