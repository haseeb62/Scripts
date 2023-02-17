#!/bin/bash

debug=0
spade_bin="./bin/spade"
spade_cfg="./cfg/spade.client.Control.config"

cmd_bin_logs_dir_path="/home/vagrant/trace_bins"
spade_log_msg_str_that_signals_the_cdm_log_has_been_processed="Finished reading"
dot_output_dir_path="/home/vagrant/trace_dots"
input_vertex_set="../vertex_set.json"


query_file="./cfg/spade.client.CommandLine.config"


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


erase(){
  local count="${1}"
  qeury_writer "erase %$count"
  qeury_writer "erase \$$count"
  qeury_writer "erase \$lineage_$count"
  qeury_writer "erase \$vertices_$count"
  qeury_writer "erase \$parents_$count"
  qeury_writer "erase \$skeleton_$count"
  # send_spade_command "erase \$subgraph_$count"

}

qeury_writer(){
  query="${1}"
  echo $query >> $query_file 
}



dfs_runner(){
  local uuid="${1}"
  local count="${2}"
  echo "UUID: $uuid"
  echo "count : $count" 
  qeury_writer "%$count = \"uuid\"=='$uuid'"  #uuid
  qeury_writer "\$$count = \$base.getVertex(%$count)"  #getVertex
  qeury_writer "\$lineage_$count = \$base.getLineage(\$$count, 5,'d')"  #$lineage 
  qeury_writer "\$vertices_$count = \$lineage_$count.getVertex()"  #vertexset
  qeury_writer "\$parents_$count = \$base.getNeighbor(\$vertices_$count, 'a')"  #parents
  qeury_writer "\$skeleton_$count = \$lineage_$count + \$parents_$count"   #union
  qeury_writer "\$subgraph_$count = \$base.getSubgraph(\$skeleton_$count)"  #getsubgraph
  # send_spade_command "\$dfs_$count = \$subgraph_$count.transform(TemporalTraversalPrime, \"order=timestamp\", \$$count, 'd')" #transformer
  erase $count
}



main_loop(){
local count=0
# Extract the uuids from the json file
uuids=$(jq '.[].annotations.uuid' ${input_vertex_set})

# remove the quotes
uuids="${uuids//\"}"

# replace the space with newline
uuids="${uuids// /\\n}"

#L(V1) then find V(L(V1)) then find P(V(L(V1) then Union P(V(L(V1) with L(V1) and on this union call getSubgraph
while IFS= read -r uuid; do # looping over each UUID
    # Print each uuid
    echo "UUID: $uuid"
    dfs_runner $uuid $count
    count=$((count+1))
done < <(echo "$uuids")

send_spade_command "list"
}


main_loop
