pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
pip install torch==2.8.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cpu
pip install -r requirements.txt
pip install -e .

modelscope download --model OpenBMB/VoxCPM2 --local_dir ./checkpoints/OpenBMB/VoxCPM2
modelscope download --model iic/SenseVoiceSmall --local_dir ./checkpoints/iic/SenseVoiceSmall
modelscope download --model iic/speech_zipenhancer_ans_multiloss_16k_base --local_dir ./checkpoints/iic/speech_zipenhancer_ans_multiloss_16k_base

python app.py --ultra_clone_device_cpu