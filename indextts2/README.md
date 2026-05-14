
## 关于 index-tts

原项目地址：[index-tts](https://github.com/index-tts/index-tts)

## 使用方法

### 使用预构建镜像 `lesca/index-tts:latest`

```yaml
services:
  index-tts:
    image: lesca/index-tts:latest
    container_name: index-tts

    # GPU 配置
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

    ports:
      - "7860:7860"

```


### 自构建镜像 `index-tts:latest`

```bash
docker buildx build --platform linux/arm64 --build-arg BRANCH_NAME=main -t indextts2:latest -f Dockerfile .
```
