#!/bin/bash
docker run --rm -p 7860:7860 -v /home/itrnd/testgpt/text-generation-webui/models:/models --gpus all llama_cpp_paddler:server-cuda -m models/gemma-2-2b-it-Q8_0.gguf -c 114744 -np 14 --host 0.0.0.0 --port 7860 --n-gpu-layers 27 -fa
