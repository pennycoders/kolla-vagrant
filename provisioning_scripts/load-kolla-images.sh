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
  ssh root@${hosts[${i}]} "for filename in /containers/*.tar;do docker load --input \${filename}; done"
done
