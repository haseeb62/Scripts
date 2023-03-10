#!/bin/bash
spade_bin="./SPADE/bin/spade"
spade_cfg="./SPADE/cfg/spade.client.Control.config"
Object_id_file_path="/home/vagrant/ObjectIDs"
merge_file="./merging_vertex1.txt"
cli="./SPADE/bin/manage-quickstep.sh start --path /home/vagrant/quickstepdb -c"
symbols="./spadesymbols.txt"
subgraph="subgraph"


# echo "copy select * from spade_query_symbols to '/home/vagrant/spadesymbols.txt' with (delimiter ',');" | ./manage-quickstep.sh start --path /home/vagrant/quickstepdb -c

is_spade_running(){
    "${spade_bin}" status | grep -q "Running"    
}

clear_cfg() {
    truncate -s 0 "${spade_cfg}"
}

stop_spade(){
  "${spade_bin}" stop
}

kill_spade(){
  "${spade_bin}" kill
}

start_spade(){
  "${spade_bin}" start
}


send_spade_command(){
  local cmd="${1}"
  echo "${cmd}" | "${spade_bin}" query
}

merge() {
  local x="${1}"
  local y="${2}"
  send_spade_command "\$intersect = \$${subgraph}_$x &  \$${subgraph}_$y"
  # local z=$(echo "copy select value from spade_query_symbols where name='\$intersect' to stdout;" | ${cli}| tail -n 1) # copy select value from spade_query_symbols where name='\$intersect0' to stdout;
  # echo "ez1=$z"
  local intersect_table_name=$(echo "copy select value from spade_query_symbols where name='\$intersect' to stdout;" | ${cli}| tail -n 1)
  local v_intersect_size=$(echo "copy select count(*) from ${intersect_table_name}_vertex to stdout;" | ${cli}| tail -n 1)


  echo "ez2=$intersect_table_name"
  echo "ez3=$v_intersect_size"
  
  # echo "$intersect_table_name $v_intersect_size"
  if [ $v_intersect_size -eq 0 ]; then
    echo "nomerge"  
    return
  fi

  local x_table_name=$(echo "copy select value from spade_query_symbols where name='\$${subgraph}_${x}' to stdout;" | ${cli}| tail -n 1)
  # $(echo "copy select value from spade_query_symbols where name='\$intersect_$x$y' to stdout;" | ${cli}| tail -n 1)

  local y_table_name=$(echo "copy select value from spade_query_symbols where name='\$${subgraph}_${y}' to stdout;" | ${cli} | tail -n 1)
  local v_x_size=$(echo "copy select count(*) from ${x_table_name}_vertex to stdout;" | ${cli} | tail -n 1)
  local v_y_size=$(echo "copy select count(*) from ${y_table_name}_vertex to stdout;" | ${cli} | tail -n 1)
  echo "outputing size1 = $v_x_size size2 = $v_y_size"

  
  if [ $v_x_size -eq $v_intersect_size ]; then
    send_spade_command "\$difference = \$${subgraph}_${x} - \$intersect"
    local diff1_table_name=$(echo "copy select value from spade_query_symbols where name='\$difference' to stdout;" | ${cli} | tail -n 1)
    local v_diff1_size=$(echo "copy select count(*) from ${diff1_table_name}_vertex to stdout;" | ${cli} | tail -n 1)
    local e_diff1_size=$(echo "copy select count(*) from ${diff1_table_name}_edge to stdout;" | ${cli} | tail -n 1)
    echo "$diff1_table_name $v_diff1_size $e_diff1_size"
    if [ $v_diff1_size -eq 0 ] && [ $e_diff1_size -eq 0 ]; then
        echo "mergex"
        return
    fi
  fi

  if [ $v_y_size -eq $v_intersect_size ]; then
    send_spade_command "\$difference = \$${subgraph}_${y} -  \$intersect"
    local diff2_table_name=$(echo "copy select value from spade_query_symbols where name='\$difference' to stdout;" | ${cli} | tail -n 1)
    local v_diff2_size=$(echo "copy select count(*) from ${diff2_table_name}_vertex to stdout;" | ${cli} | tail -n 1)
    local e_diff2_size=$(echo "copy select count(*) from ${diff2_table_name}_edge to stdout;" | ${cli} | tail -n 1)
     echo "$diff1_table_name $v_diff1_size $e_diff1_size"
    if [ $v_diff2_size -eq 0 ] && [ $e_diff2_size -eq 0 ]; then
        echo "mergey"
        return
    fi
  fi

  # if [ $check1 -eq 1 ]; then
  #   local diff1_table_name=`echo "copy select value from spade_query_symbols where name=\$difference1 to stdout;" | ${cli}`
  #   local v_diff1_size=`echo "copy select count(*) from ${diff1_table_name}_vertex to stdout;" | ${cli}`
  #   local e_diff1_size=`echo "copy select count(*) from ${diff1_table_name}_edge to stdout;" | ${cli}`
  #   if [ $v_diff1_size -eq 0 ] && [ $e_diff1_size -eq 0 ]; then
  #       echo "mergex"
  #       return
  #   fi
  # fi

  # if [ $check2 -eq 1 ]; then
  #   local diff2_table_name=`echo "copy select value from spade_query_symbols where name=\$difference1 to stdout;" | ${cli}`
  #   local v_diff2_size=`echo "copy select count(*) from ${diff2_table_name}_vertex to stdout;" | ${cli}`
  #   local e_diff2_size=`echo "copy select count(*) from ${diff2_table_name}_edge to stdout;" | ${cli}`
  #   if [ $v_diff2_size -eq 0 ] && [ $e_diff2_size -eq 0 ]; then
  #       echo "mergey"
  #       return
  #   fi
  # fi

  send_spade_command "erase \$intersect"
  send_spade_command "erase \$difference"
  # send_spade_command "erase \$difference2" 

  echo "nomerge"  
}

main() {
  while read line; do
  read -ra nums <<< "$line"
  x=${nums[0]}
  for i in "${nums[@]:1}"; do
    echo "$x $i"
    merge $x $i
  done
    done < ${merge_file}

   #merge graph_1 graph_2
  # $result is either "mergey" "mergex" or "nomerge"
  # merge x means x chota hay so remove it and keep y
  # merge y means remove subgraph y and vice versa right?
  # no merge means both remain

  
  # KHER
  # ab 2 options hain
  # ya to we keep a list, ke kon konse merge(REMOVE) karne or end pe akathay karden
  # ya hum loop ke andar he karte rahen agar koi graph remove karna ho
  # end wala tareeke me error handling nae karni parhe gi
  # during loop me error handling karni parhe gi but kuch computations bach jain gi cuz some groups u wont have to recheck again

  # mein soch raha
  #"\$intersect = \$${subgraph}_${x} &  \$${subgraph}_${y}"

  # u there?
}

main