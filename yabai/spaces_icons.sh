s2w=`yabai -m query --windows | jq -r 'map({"pid": .pid,"space": .space}) | group_by(.space)[] | [.[0].space] + map(.pid) | @tsv'`
while read s2w into arr
do
    echo $arr
done
