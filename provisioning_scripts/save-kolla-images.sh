#!/usr/bin/env bash

#!/usr/bin/env bash

hosts=(
  jump
  control1
  compute1
  compute2
)

for i in ${!hosts[@]}; do
  echo "${hosts[${i}]}==========================================================================================="
  ssh root@${hosts[${i}]} docker images -a | awk 'FNR>1 {output=$1"-"$2;image=$1":"$2; gsub("/","-", output); print "--output /containers/"output".tar "image;}' | xargs -l ssh root@${hosts[${i}]} docker save
done
