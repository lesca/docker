### Install ComfyUI ###
conda create -y -n comfyui python=3.12
conda activate comfyui

# install comfyui
git clone -b v0.34.1 --depth 1 https://github.com/comfy-org/comfyui
pip install -r comfyui/requirements.txt

# install comfyui manager
pip install -U --pre comfyui-manager matrix-nio

# setup comfyui data
rm -r comfyui/{output,input,models,custom_nodes}
ln -s /share/public/comfyui/{user,input,output,models,custom_nodes} comfyui/

# install nvidia gpu support cu129 for flash-attention-v100
# https://github.com/ai-bond/flash-attention-v100
# pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
pip install torch==2.10.0+cu129 torchvision==0.25.0+cu129 torchaudio==2.10.0+cu129 --index-url https://download.pytorch.org/whl/cu129

# Check is package supports Volta (sm_70)
python -c "import torch; p=torch.cuda.get_device_properties(0); print(f'{p.name} SM {p.major}.{p.minor} supported')"

# test gpu (sm_70)
python -c "import torch; print('CUDA Available:', torch.cuda.is_available()); print('Device Name:', torch.cuda.get_device_name(0)); print('Arch List:', torch.cuda.get_arch_list())"

# start comfyui (v.0.38+)
python3 main.py --listen 0.0.0.0 --enable-manager --disable-comfy-compiler

### install flash-attention-v100 ###
# install gcc-14 (for cuda 12.9)
sudo pacman -U \
https://archive.archlinux.org/packages/g/gcc14/gcc14-14.3.1%2Br416%2Bg44d5743651c4-2-x86_64.pkg.tar.zst \
https://archive.archlinux.org/packages/g/gcc14-libs/gcc14-libs-14.3.1%2Br416%2Bg44d5743651c4-2-x86_64.pkg.tar.zst

# install cuda 12.9 lib
yay -S cuda-12.9
cat >> ~/.zshrc << 'EOF'
export CUDA_HOME=/opt/cuda
EOF
source ~/.zshrc

# Clone code and install packages:
git clone https://github.com/ai-bond/flash-attention-v100
cd flash-attention-v100
pip install -r requirements.txt

# 强制 pip 直接使用你当前 Conda 环境中已安装的依赖项进行编译，不再创建临时环境。
pip install . --no-build-isolation -v

### clean up comfyui ###
conda deactivate
conda env remove -n comfyui -y


### Minimax H3 优化 ###
# minimax-h3-fp16-fix: 
# https://github.com/Amduraznak/minimax-h3-fp16-fix
# https://github.com/aaalll12322/ComfyUI-MiniMaxH3-FP16Safe
# https://github.com/aaalll12322/ComfyUI-MiniMaxH3-SolAttn-V100
# flash-attention-v100: https://github.com/ai-bond/flash-attention-v100
# flash-attention-v100 node: https://github.com/FearL0rd/ComfyUI-Flash-Attention_v100
# Minimax-H3-Easy node: https://github.com/nkxx188/ComfyUI-MiniMaxH3-Easy
# Turbo node: https://github.com/Larryvrh/ComfyUI-MiniMax-H3-Turbo