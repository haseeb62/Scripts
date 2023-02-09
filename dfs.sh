#!/bin/bash

debug=0
spade_bin="./bin/spade"
spade_cfg="./cfg/spade.client.Control.config"

cmd_bin_logs_dir_path="/home/vagrant/trace_bins"
spade_log_msg_str_that_signals_the_cdm_log_has_been_processed="Finished reading"
dot_output_dir_path="/home/vagrant/trace_dots"
input_vertex_set="../vertex_set.json"



clear_spade_cfg(){
  truncate -s 0 "${spade_cfg}"
}


is_spade_running(){
  "${spade_bin}" status | grep -q "Running"
}


stop_spade(){
  "${spade_bin}" stop
}


kill_spade(){
  "${spade_bin}" kill
}


try_stop_kill_spade(){
  #if is_spade_running; then
   # stop_spade
  ##fi
  #sleep 5
  if is_spade_running; then
    kill_spade
  fi
}


start_spade(){
  "${spade_bin}" start
}


send_spade_command(){
  local cmd="${1}"
  echo "${cmd}" | "${spade_bin}" query
  if [ "${debug}" -eq 1 ]; then
  echo "list all" | "${spade_bin}" query
  fi
}



dfs_runner(){
    local uuid = "${1}"
    echo "UUID: $uuid"
    send_spade_command "%$count = \"UUID\"=='$uuid'" #uuid
    send_spade_command "\$$count = \$base.getVertex(%$count)" #getVertex
    send_spade_command "\$lineage_$count = \$base.getLineage(\$$count, 5,'d')" #$lineage 
    send_spade_command "\$vertices_$count = \$lineage_$count.getVertex()" #vertexset
    send_spade_command "\$parents_$count = \$base.getLineage(\$vertices_$count, 1,'a')" #parents
    send_spade_command "\$skeleton_$count = \$lineage_$count + \$parents+_$count"  #union
    send_spade_command "\$subgraph_$count = \$base.getSubgraph(\$skeleton_$count)" #getsubgraph
    send_spade_command "\$dfs_$count = \$subgraph.transform(temporaltraversalprime)" #transformer
}




main_loop(){
local count=0
# Extract the uuids from the json file
uuids=$(jq '.[].annotations.uuid' ${input_vertex_set})

# remove the quotes
uuids="${uuids//\"}"

# replace the space with newline
uuids="${uuids// /\\n}"

while IFS= read -r uuid; do # looping over each UUID
    # Print each uuid
    echo "UUID: $uuid"
    send_spade_command "%$count = \"uuid\"=='$uuid'" #uuid
    send_spade_command "\$$count = \$base.getVertex(%$count)" #getVertex
    send_spade_command "\$lineage_$count = \$base.getLineage(\$$count, 5,'d')" #$lineage 
    send_spade_command "\$vertices_$count = \$lineage_$count.getVertex()" #vertexset
    send_spade_command "\$parents_$count = \$base.getLineage(\$vertices_$count, 1,'a')" #parents
    send_spade_command "\$skeleton_$count = \$lineage_$count + \$parents_$count"  #union
    send_spade_command "\$subgraph_$count = \$base.getSubgraph(\$skeleton_$count)" #getsubgraph
    send_spade_command "\$dfs_$count = \$subgraph_$count.transform(TemporalTraversalPrime, \"order=timestamp\", \$$count, 'd')" #transformer
    count=$((count+1))
    #L(V1) then find V(L(V1)) then find P(V(L(V1) then Union P(V(L(V1) with L(V1) and on this union call getSubgraph
done < <(echo "$uuids")

#   local i= name= cdm_log_path= dot_path= idx=0
#   local line_count=1
#   try_stop_kill_spade
#   clear_spade_cfg
#   "${spade_bin}" start
#    sleep 2
#   send_spade_command "add storage Quickstep"
#     for i in {114..119}; do
#     echo "ta1-trace-e3-official.bin.${i}"
#     send_spade_command "add reporter CDM /home/vagrant/trace_bins/ta1-trace-e3-official.bin.${i}"
#     while : ; do
#     sleep 10
#     value=$( grep "File processing" "/home/vagrant/SPADE/log/current.log" | wc -l )
#     echo $value
#      if [ "$value" -eq "${line_count}" ]
#       then
#       line_count = $((line_count + 1))
#       break
#      fi
#      done
#   done
}


main_loop
