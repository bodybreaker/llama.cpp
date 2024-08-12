#!/bin/bash

cleanup(){
	echo "프로세스 종료"
	kill $(jobs -p)
	wait
	exit
}


trap cleanup SIGINT SIGTERM


PORT=""
ORIGIN_ARGS=("$@")
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --port)
        PORT="$2"
        shift # shift past the argument
        shift # shift past the value
        ;;
        *)
        shift # shift past other arguments
        ;;
    esac
done

echo "======= LLAMA CPP SERVER PORT [$PORT] ========="


# paddler 먼저 실행
echo "======================= PADDLER AGENT 실행 ========================"
nohup /paddler agent \
    --external-llamacpp-host $(cat /etc/hostname)\
    --external-llamacpp-port $PORT \
    --local-llamacpp-host 127.0.0.1 \
    --local-llamacpp-port $PORT \
    --management-host loadbalancer \
    --management-port 8085  > paddler.log 2>&1 &

echo "======================= LLAMA SERVER 실행 ========================="

echo "argument :: ${ORIGIN_ARGS[@]}"

# llama-server 실행
nohup /llama-server "${ORIGIN_ARGS[@]}" > llama-server.log 2>&1 &

tail -f llama-server.log &

wait
