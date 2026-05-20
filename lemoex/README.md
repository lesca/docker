

## Usage

```bash
# transcribe all videos in specific folder
docker run -it --rm --name test -v $PWD/input/video_folder:/input lesca/lemoex:latest
# meanwhile, convert videos to mp4 format
docker run -it --rm --name test -v $PWD/input/video_folder:/input lesca/lemoex:latest --mp4
# use AI translate (.env with API keys)
docker run -it --rm --name test -v $PWD/.env:/app/.env -v $PWD/input/video_folder:/input lesca/lemoex:latest --translate
```


`.env` file example
```bash
OPENAI_BASE_URL="https://api.deepseek.com/v1"
OPENAI_API_KEY="sk-xxx"
OPENAI_MODEL="deepseek-v4-flash"
TRANSLATE_LINES_NUM=50
TRANSLATE_TASKS_NUM=5
TRANSLATE_RETRY_COUNT=5
```