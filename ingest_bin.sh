#!/bin/bash

debug=0
spade_bin="./bin/spade"
spade_cfg="./cfg/spade.client.Control.config"

cmd_bin_logs_dir_path="/home/vagrant/trace_bins"
spade_log_msg_str_that_signals_the_cdm_log_has_been_processed="Finished reading"
dot_output_dir_path="/home/vagrant/trace_dots"


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
  echo "${cmd}" | "${spade_bin}" control
  if [ "${debug}" -eq 1 ]; then
  echo "list all" | "${spade_bin}" control
  fi
}


add_graphviz_storage(){
  local output_path="${1}"
  local cmd="add storage Graphviz ${output_path}"
  send_spade_command "${cmd}"
}


remove_graphviz_storage(){
  local cmd="remove storage Graphviz"
  send_spade_command "${cmd}"
}


add_cdm_reporter(){
  local input_log="${1}"
  local cmd="add reporter CDM ${input_log}"
  send_spade_command "${cmd}"
}


remove_cdm_reporter(){
  local cmd="remove reporter CDM"
  local current_log=`ls log -Art | tail -n 1`
  while : ; do
    sleep 10
    if grep -q "${spade_log_msg_str_that_signals_the_cdm_log_has_been_processed}" "./log/${current_log}" == ${1}; then
      break
    fi
  done
  send_spade_command "${cmd}"
}


process_cdm_log_to_dot(){
  local current_log=`current.log`
  local dot_path="${1}"
#   try_stop_kill_spade
#   clear_spade_cfg
  start_spade
  sleep 1
  ls -l "log/${current_log}"
  add_graphviz_storage "${dot_path}" # add storage Quickstep
  sleep 1
  add_cdm_reporter "${cdm_log_path}" # loop add reporter graphviz
  sleep 5
#   remove_cdm_reporter
#   sleep 5
#   remove_graphviz_storage
#   sleep 5
#   stop_spade
}


assert_check(){
  [ -z "${cmd_bin_logs_dir_path}" ] && echo "Must set the variable 'cmd_bin_logs_dir_path' to the path of the CDM binary logs for TCE3" && exit 1
  [ ! -d "${cmd_bin_logs_dir_path}" ] && echo "The path of the CDM binary logs directory for TCE3 is not a directory" && exit 1
  [ -z "${dot_output_dir_path}" ] && echo "Must set the variable 'dot_output_dir_path' to the path of the Graphviz output directory" && exit 1
  [ ! -d "${dot_output_dir_path}" ] && echo "The path of the Graphviz output directory is not a directory" && exit 1
  [ -z "${spade_log_msg_str_that_signals_the_cdm_log_has_been_processed}" ] && echo "Must set the variable 'spade_log_msg_str_that_signals_the_cdm_log_has_been_processed'" && exit 1
}


main_loop(){
  #assert_check

  local i= name= cdm_log_path= dot_path= idx=0
  local line_count=1
  try_stop_kill_spade
  clear_spade_cfg
  "${spade_bin}" start
   sleep 2
  send_spade_command "add storage Quickstep"
    for i in {114..119}; do
    # dot_path="${dot_output_dir_path}/${i}.dot"
    echo "ta1-trace-e3-official.bin.${i}"
    send_spade_command "add reporter CDM /home/vagrant/trace_bins/ta1-trace-e3-official.bin.${i}"
    while : ; do
    sleep 10
   # grep -q "${spade_log_msg_str_that_signals_the_cdm_log_has_been_processed}" "./log/${current_log}" == ${1}
    value=$( grep "File processing" "/home/vagrant/SPADE/log/current.log" | wc -l )
    echo $value
     if [ "$value" -eq "${line_count}" ]
      then
      line_count = $((line_count + 1))
      break
     fi
     done
  done
}


main_loop
