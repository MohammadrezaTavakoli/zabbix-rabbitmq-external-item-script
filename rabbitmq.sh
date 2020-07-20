#!/bin/bash

file=./rabbit.json
user="admin"
pass="admin"

if [[ -f "$file" ]]; then
	rm $file
fi 
	
touch $file

echo "{" > $file 
echo "    \"msg_published_in\"" ":" "{">> $file

for j in $(curl -s -u admin:admin 'http://localhost:15672/api/exchanges' | jq .[].name)
do
        l=$(echo $j| sed 's/"//g')
        if [[ $l = "" ]]
        then
                echo "        \"main_exchange\"" ":" $(curl -s -u admin:admin "http://localhost:15672/api/exchanges/%2F?columns=message_stats" | jq .[0].message_stats.publish_in) "," >> $file
        else
                echo "        \"$l\"" ":" $(curl -s -u admin:admin "http://localhost:15672/api/exchanges/%2F/$l?columns=message_stats" | jq .[].publish_in) "," >> $file
        fi
done

echo "    }," >> $file


echo "    \"msg_published_out\"" ":" "{" >> $file

for j in $(curl -s -u admin:admin 'http://localhost:15672/api/exchanges' | jq .[].name)
do
        l=$(echo $j| sed 's/"//g')
    	if [[ $l = "" ]]
    	then
        	echo "        \"main_exchange\"" ":" $(curl -s -u admin:admin "http://localhost:15672/api/exchanges/%2F?columns=message_stats" | jq .[0].message_stats.publish_out) ',' >> $file 
    	else
            	echo "        \"$l\"" ":" $(curl -s -u admin:admin "http://localhost:15672/api/exchanges/%2F/$l?columns=message_stats" | jq .[].publish_out) ',' >> $file 
    	fi
done
echo "    }," >> $file

echo "    \"msg_unroutable\"" ":" "{" >> $file 
msg_unroutable=$(curl -s -u $user:$pass "http://127.0.0.1:15672/api/overview?columns=message_stats" | jq ".[].return_unroutable")
echo "        \"count\"" ":" $msg_unroutable >> $file
echo "    }," >> $file

echo "    \"disk_free\"" ":" "{" >> $file
disk_free=$(curl -s -u $user:$pass http://localhost:15672/api/nodes | jq .[].disk_free)
echo "        \"bytes_free\"" ":" $disk_free >> $file
echo "    }," >> $file

echo "    \"memory_used\"" ":" "{" >> $file
memory_used=$(curl -s -u $user:$pass http://localhost:15672/api/nodes | jq .[].mem_used)
echo "        \"bytes_in_ram\"" ":" $memory_used >> $file
echo "    }," >> $file

echo "    \"sockets_used\"" ":" "{" >> $file
sockets_used=$(curl -s -u $user:$pass http://localhost:15672/api/nodes | jq .[].sockets_used)
echo "        \"count\"" ":" $sockets_used >> $file
echo "    }," >> $file

echo "    \"file_descriptors_used\"" ":" "{" >> $file
file_descriptors_used=$(curl -s -u $user:$pass http://localhost:15672/api/nodes | jq .[].fd_used)
echo "        \"count\"" ":" $file_descriptors_used >> $file
echo "    }," >> $file

echo "    \"ready_and_unacknowledged_msg\"" ":" "{" >> $file
ready_and_unacknowledged_msg_name=($(rabbitmqctl -q list_queues -t 2 -p / name 2>/dev/null))
ready_and_unacknowledged_msg_value=($(rabbitmqctl -q list_queues -t 2 -p / messages 2>/dev/null))

for ((i=0;i<${#ready_and_unacknowledged_msg_name[@]};i++))
do
	echo "        \"${ready_and_unacknowledged_msg_name[$i]}\"" ":" ${ready_and_unacknowledged_msg_value[$i]} "," >> $file;
done
echo "    }," >> $file


echo "    \"unacknowledged_msg\"" ":" "{" >> $file
unacknowledged_msg_name=($(rabbitmqctl -q list_queues -t 2 -p / name 2>/dev/null))
unacknowledged_msg_value=($(rabbitmqctl -q list_queues -t 2 -p / messages_unacknowledged 2>/dev/null ))

for ((i=0;i<${#unacknowledged_msg_name[@]};i++))
do
         echo "        \"${unacknowledged_msg_name[$i]}\"" ":" ${unacknowledged_msg_value[$i]} "," >> $file;
done
echo "    }," >> $file


echo "    \"msg_available_to_consumer\"" ":" "{" >> $file
msg_available_to_consumer_name=($(rabbitmqctl -q list_queues -t 2 -p / name 2>/dev/null))
msg_available_to_consumer_value=($(rabbitmqctl -q list_queues -t 2 -p / messages_ready 2>/dev/null))

for ((i=0;i<${#msg_available_to_consumer_name[@]};i++))
do
	echo "        \"${msg_available_to_consumer_name[$i]}\"" ":" ${msg_available_to_consumer_value[$i]} "," >> $file;
done
echo "    }," >> $file


echo "    \"unacknowledged_msg_rate\"" ":" "{" >> $file
for i in $(curl -s -u $user:$pass http://localhost:15672/api/queues | jq .[].name)
do
    s=$(echo $i| sed 's/"//g')
    echo "        \"$s\"" ":" $(curl -s -u admin:admin "http://localhost:15672/api/queues/%2F/$s?columns=messages_unacknowledged_details" | jq .[].rate) "," >> $file 
done
echo "    }," >> $file


echo "    \"delivered_msg_rate\"" ":" "{" >> $file
delivered_msg_rate=$(curl -s -u admin:admin http://127.0.0.1:15672/api/overview?columns=message_stats | jq .[].deliver_details.delivered_msg_rate)
echo "        \"rate\"" ":" $delivered_msg_rate >> $file
echo "    }," >> $file


echo "    \"redelivered_msg_rate\"" ":" "{" >> $file
redelivered_msg_rate=$(curl -s -u admin:admin http://127.0.0.1:15672/api/overview?columns=message_stats | jq .[].redeliver_details.rate)
echo "        \"rate\"" ":" $redelivered_msg_rate >> $file
echo "    }," >> $file


echo "    \"msg_written_to_disk\"" ":" "{" >> $file 
msg_written_to_disk_name=($(rabbitmqctl -q list_queues -t 2 -p / name 2>/dev/null))
msg_written_to_disk_value=($(rabbitmqctl -q list_queues -t 2 -p / messages_persistent 2>/dev/null))

for ((i=0;i<${#msg_written_to_disk_name[@]};i++))
do
        echo "        \"${msg_written_to_disk_name[$i]}\"" ":" ${msg_written_to_disk_value[$i]} "," >> $file;
done
echo "    }," >> $file


echo "    \"msg_written_to_disk_bytes_sum\"" ":" "{" >> $file
msg_written_to_disk_bytes_sum_name=($(rabbitmqctl -q list_queues -t 2 -p / name 2>/dev/null))
msg_written_to_disk_bytes_sum_value=($(rabbitmqctl -q list_queues -t 2 -p / message_bytes_persistent 2>/dev/null))

for ((i=0;i<${#msg_written_to_disk_bytes_sum_name[@]};i++))
do
        echo "        \"${msg_written_to_disk_bytes_sum_name[$i]}\"" ":" ${msg_written_to_disk_bytes_sum_value[$i]} "," >> $file;
done
echo "    }," >> $file


echo "    \"msg_stored_in_memory_sum\"" ":" "{"  >> $file
msg_stored_in_memory_sum_name=($(rabbitmqctl -q list_queues -t 2 -p / name 2>/dev/null))
msg_stored_in_memory_sum_value=($(rabbitmqctl -q list_queues -t 2 -p / message_bytes_ram 2>/dev/null))

for ((i=0;i<${#msg_stored_in_memory_sum_name[@]};i++))
do
        echo "        \"${msg_stored_in_memory_sum_name[$i]}\"" ":" ${msg_stored_in_memory_sum_value[$i]} "," >> $file;
done
echo "    }," >> $file


echo "    \"consumer_count\"" ":" "{" >> $file
consumer_count_name=($(rabbitmqctl -q list_queues -t 2 -p / name 2>/dev/null))
consumer_count_value=($(rabbitmqctl -q list_queues -t 2 -p / consumers 2>/dev/null))

for ((i=0;i<${#consumer_count_name[@]};i++))
do
        echo "        \"${consumer_count_name[$i]}\"" ":" ${consumer_count_value[$i]} "," >> $file;
done
echo "    }," >> $file


echo "    \"consumer_utilisation\"" ":" "{" >> $file
consumer_utilisation_name=($(rabbitmqctl -q list_queues -t 2 -p / name 2>/dev/null))
consumer_utilisation_value=($(rabbitmqctl -q list_queues -t 2 -p / consumer_utilisation 2>/dev/null))

for ((i=0;i<${#consumer_utilisation_name[@]};i++))
do
        echo "        \"${consumer_utilisation_name[$i]}\"" ":" ${consumer_utilisation_value[$i]} "," >> $file;
done
echo "    }," >> $file


echo "    \"queue_alocated_memory\"" ":" "{" >> $file
queue_alocated_memory_name=($(rabbitmqctl -q list_queues -t 2 -p / name 2>/dev/null))
queue_alocated_memory_value=($(rabbitmqctl -q list_queues -t 2 -p / memory 2>/dev/null))

for ((i=0;i<${#queue_alocated_memory_name[@]};i++))
do
        echo "        \"${queue_alocated_memory_name[$i]}\"" ":" ${queue_alocated_memory_value[$i]} "," >> $file;
done
echo "    }," >> $file


echo "    \"octets_recieved_rate\"" ":" "{" >> $file
octets_recieved_rate=$(curl -s -u $user:$pass http://localhost:15672/api/vhosts?columns=recv_oct_details | jq .[].recv_oct_details.rate)
echo "        \"rate\"" ":" $octets_recieved_rate >> $file
echo "    }," >> $file

echo "    \"octets_sent_rate\"" ":" "{" >> $file
octets_sent_rate=$(curl -s -u $user:$pass http://localhost:15672/api/vhosts?columns=send_oct_details | jq .[].send_oct_details.rate)
echo "        \"rate\"" ":" $octets_sent_rate >> $file
echo "    }," >> $file

echo "    \"octets_recieved\"" ":" "{" >> $file
octets_recieved=$(curl -s -u $user:$pass http://localhost:15672/api/vhosts?columns=recv_oct | jq .[].recv_oct)
echo "        \"count\"" ":" $octets_recieved >> $file
echo "    }," >> $file

echo "    \"octets_sent\"" ":" "{" >> $file
octets_sent=$(curl -s -u $user:$pass http://localhost:15672/api/vhosts?columns=send_oct | jq .[].send_oct)
echo "        \"count\"" ":" $octets_sent >> $file
echo "    }" >> $file

echo "}" >> $file
echo "$(cat $file | sed -E -n 'H; x; s:,(\s*\n\s*}):\1:; P; ${x; p}' | sed '1 d')" > $file

