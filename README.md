# OpenedAI Speech

An OpenAI API compatible text to speech server.

* Compatible with the OpenAI audio/speech API
* Serves the [/v1/audio/speech endpoint](https://platform.openai.com/docs/api-reference/audio/createSpeech)
* Not affiliated with OpenAI in any way, does not require an OpenAI API Key
* A free, private, text-to-speech server with custom voice cloning

Full Compatibility:
* `tts-1`: `alloy`, `echo`, `fable`, `onyx`, `nova`, and `shimmer` (configurable)
* `tts-1-hd`:  `alloy`, `echo`, `fable`, `onyx`, `nova`, and `shimmer` (configurable, uses OpenAI samples by default)
* response_format: `mp3`, `opus`, `aac`, or `flac`
* speed 0.25-4.0 (and more)

Details:
* Model `tts-1` via [piper tts](https://github.com/rhasspy/piper) (very fast, runs on cpu)
  * You can map your own [piper voices](https://rhasspy.github.io/piper-samples/) via the `voice_to_speaker.yaml` configuration file
* Model `tts-1-hd` via [coqui-ai/TTS](https://github.com/coqui-ai/TTS) xtts_v2 voice cloning (fast, but requires around 4GB GPU VRAM)
  * Custom cloned voices can be used for tts-1-hd, See: [Custom Voices Howto](#custom-voices-howto)
  * 🌐 [Multilingual](#multilingual) support with XTTS voices
* Occasionally, certain words or symbols may sound incorrect, you can fix them with regex via `pre_process_map.yaml`


If you find a better voice match for `tts-1` or `tts-1-hd`, please let me know so I can update the defaults.

## Recent Changes

Version 0.12.3, 2024-06-17

* Additional logging details for BadRequests (400)

Version 0.12.2, 2024-06-16

* Fix :min image requirements (numpy<2?)

Version 0.12.0, 2024-06-16

* Improved error handling and logging
* Restore the original alloy tts-1-hd voice by default, use alloy-alt for the old voice.

Version 0.11.0, 2024-05-29

* 🌐 [Multilingual](#multilingual) support (16 languages) with XTTS
* Remove high Unicode filtering from the default `config/pre_process_map.yaml`
* Update Docker build & app startup. thanks @justinh-rahb
* Fix: "Plan failed with a cudnnException"
* Remove piper cuda support

Version: 0.10.1, 2024-05-05

* Remove `runtime: nvidia` from docker-compose.yml, this assumes nvidia/cuda compatible runtime is available by default. thanks @jmtatsch

Version: 0.10.0, 2024-04-27

* Pre-built & tested docker images, smaller docker images (8GB or 860MB)
* Better upgrades: reorganize config files under `config/`, voice models under `voices/`
* **Compatibility!** If you customized your `voice_to_speaker.yaml` or `pre_process_map.yaml` you need to move them to the `config/` folder.
* default listen host to 0.0.0.0

Version: 0.9.0, 2024-04-23

* Fix bug with yaml and loading UTF-8
* New sample text-to-speech application `say.py`
* Smaller docker base image
* Add beta [parler-tts](https://huggingface.co/parler-tts/parler_tts_mini_v0.1) support (you can describe very basic features of the speaker voice), See: (https://www.text-description-to-speech.com/) for some examples of how to describe voices. Voices can be defined in the `voice_to_speaker.default.yaml`. Two example [parler-tts](https://huggingface.co/parler-tts/parler_tts_mini_v0.1) voices are included in the `voice_to_speaker.default.yaml` file. `parler-tts` is experimental software and is kind of slow. The exact voice will be slightly different each generation but should be similar to the basic description.

...

Version: 0.7.3, 2024-03-20

* Allow different xtts versions per voice in `voice_to_speaker.yaml`, ex. xtts_v2.0.2
* Quality: Fix xtts sample rate (24000 vs. 22050 for piper) and pops


## Installation instructions

1) Copy the `sample.env` to `speech.env` (customize if needed)
```bash
cp sample.env speech.env
```

2. Option: Docker (**recommended**) (prebuilt images are available)

Run the server:
```shell
docker compose up
```
For a minimal docker image with only piper support (<1GB vs. 8GB), use `docker compose -f docker-compose.min.yml up`

To install the docker image as a service, edit the `docker-compose.yml` and uncomment `restart: unless-stopped`, then start the service with: `docker compose up -d`


2. Option: Manual installation:
```shell
# install curl and ffmpeg
sudo apt install curl ffmpeg
# Create & activate a new virtual environment (optional but recommended)
python -m venv .venv
source .venv/bin/activate
# Install the Python requirements
pip install -r requirements.txt
# run the server
bash startup.sh
```


## Usage

```
usage: speech.py [-h] [--xtts_device XTTS_DEVICE] [--preload PRELOAD] [-P PORT] [-H HOST] [-L {DEBUG,INFO,WARNING,ERROR,CRITICAL}]

OpenedAI Speech API Server

options:
  -h, --help            show this help message and exit
  --xtts_device XTTS_DEVICE
                        Set the device for the xtts model. The special value of 'none' will use piper for all models. (default: cuda)
  --preload PRELOAD     Preload a model (Ex. 'xtts' or 'xtts_v2.0.2'). By default it's loaded on first use. (default: None)
  -P PORT, --port PORT  Server tcp port (default: 8000)
  -H HOST, --host HOST  Host to listen on, Ex. 0.0.0.0 (default: 0.0.0.0)
  -L {DEBUG,INFO,WARNING,ERROR,CRITICAL}, --log-level {DEBUG,INFO,WARNING,ERROR,CRITICAL}
                        Set the log level (default: INFO)

```

## API Documentation

* [OpenAI Text to speech guide](https://platform.openai.com/docs/guides/text-to-speech)
* [OpenAI API Reference](https://platform.openai.com/docs/api-reference/audio/createSpeech)


### Sample API Usage

You can use it like this:

```shell
curl http://localhost:8000/v1/audio/speech -H "Content-Type: application/json" -d '{
    "model": "tts-1",
    "input": "The quick brown fox jumped over the lazy dog.",
    "voice": "alloy",
    "response_format": "mp3",
    "speed": 1.0
  }' > speech.mp3
```

Or just like this:

```shell
curl http://localhost:8000/v1/audio/speech -H "Content-Type: application/json" -d '{
    "input": "The quick brown fox jumped over the lazy dog."}' > speech.mp3
```

Or like this example from the [OpenAI Text to speech guide](https://platform.openai.com/docs/guides/text-to-speech):

```python
import openai

client = openai.OpenAI(
  # This part is not needed if you set these environment variables before import openai
  # export OPENAI_API_KEY=sk-11111111111
  # export OPENAI_BASE_URL=http://localhost:8000/v1
  api_key = "sk-111111111",
  base_url = "http://localhost:8000/v1",
)

with client.audio.speech.with_streaming_response.create(
  model="tts-1",
  voice="alloy",
  input="Today is a wonderful day to build something people love!"
) as response:
  response.stream_to_file("speech.mp3")
```

Also see the `say.py` sample application for an example of how to use the openai-python API.

```shell
python say.py -t "The quick brown fox jumped over the lazy dog." -p # play the audio, requires 'pip install playsound'
python say.py -t "The quick brown fox jumped over the lazy dog." -m tts-1-hd -v onyx -f flac -o fox.flac # save to a file.
```

```
usage: say.py [-h] [-m MODEL] [-v VOICE] [-f {mp3,aac,opus,flac}] [-s SPEED] [-t TEXT] [-i INPUT] [-o OUTPUT] [-p]

Text to speech using the OpenAI API

options:
  -h, --help            show this help message and exit
  -m MODEL, --model MODEL
                        The model to use (default: tts-1)
  -v VOICE, --voice VOICE
                        The voice of the speaker (default: alloy)
  -f {mp3,aac,opus,flac}, --format {mp3,aac,opus,flac}
                        The output audio format (default: mp3)
  -s SPEED, --speed SPEED
                        playback speed, 0.25-4.0 (default: 1.0)
  -t TEXT, --text TEXT  Provide text to read on the command line (default: None)
  -i INPUT, --input INPUT
                        Read text from a file (default is to read from stdin) (default: None)
  -o OUTPUT, --output OUTPUT
                        The filename to save the output to (default: None)
  -p, --playsound       Play the audio (default: False)

```

## Custom Voices Howto

### Piper

  1. Select the piper voice and model from the [piper samples](https://rhasspy.github.io/piper-samples/)
  2. Update the `config/voice_to_speaker.yaml` with a new section for the voice, for example:
```yaml
...
tts-1:
  ryan:
    model: voices/en_US-ryan-high.onnx
    speaker: # default speaker
```
  3. New models will be downloaded as needed, of you can download them in advance with `download_voices_tts-1.sh`. For example:
```shell
bash download_voices_tts-1.sh en_US-ryan-high
```

### Coqui XTTS v2

Coqui XTTS v2 voice cloning can work with as little as 6 seconds of clear audio. To create a custom voice clone, you must prepare a WAV file sample of the voice.

#### Guidelines for preparing good sample files for Coqui XTTS v2
* Mono (single channel) 22050 Hz WAV file
* 6-30 seconds long - longer isn't always better (I've had some good results with as little as 4 seconds)
* low noise (no hiss or hum)
* No partial words, breathing, laughing, music or backgrounds sounds
* An even speaking pace with a variety of words is best, like in interviews or audiobooks.

You can use FFmpeg to prepare your audio files, here are some examples:

```shell
# convert a multi-channel audio file to mono, set sample rate to 22050 hz, trim to 6 seconds, and output as WAV file.
ffmpeg -i input.mp3 -ac 1 -ar 22050 -t 6 -y me.wav
# use a simple noise filter to clean up audio, and select a start time start for sampling.
ffmpeg -i input.wav -af "highpass=f=200, lowpass=f=3000" -ac 1 -ar 22050 -ss 00:13:26.2 -t 6 -y me.wav
# A more complex noise reduction setup, including volume adjustment
ffmpeg -i input.mkv -af "highpass=f=200, lowpass=f=3000, volume=5, afftdn=nf=25" -ac 1 -ar 22050 -ss 00:13:26.2 -t 6 -y me.wav
```

Once your WAV file is prepared, save it in the `/voices/` directory and update the `config/voice_to_speaker.yaml` file with the new file name.

For example:

```yaml
...
tts-1-hd:
  me:
    model: xtts_v2.0.2 # you can specify different xtts versions
    speaker: voices/me.wav # this could be you
```

## Multilingual

Multilingual support was added in version 0.11.0 and is available only with the XTTS v2 model.

Coqui XTTSv2 has support for 16 languages: English (`en`), Spanish (`es`), French (`fr`), German (`de`), Italian (`it`), Portuguese (`pt`), Polish (`pl`), Turkish (`tr`), Russian (`ru`), Dutch (`nl`), Czech (`cs`), Arabic (`ar`), Chinese (`zh-cn`), Japanese (`ja`), Hungarian (`hu`) and Korean (`ko`).

Unfortunately the OpenAI API does not support language, but you can create your own custom speaker voice and set the language for that.

1) Create the WAV file for your speaker, as in [Custom Voices Howto](#custom-voices-howto)
2) Add the voice to `config/voice_to_speaker.yaml` and include the correct Coqui `language` code for the speaker. For example:

```yaml
  xunjiang:
    model: xtts
    speaker: voices/xunjiang.wav
    language: zh-cn
```

3) Don't remove high unicode characters in your `config/pre_process_map.yaml`! If you have these lines, you will need to remove them. For example:

Remove:
```yaml
- - '[\U0001F600-\U0001F64F\U0001F300-\U0001F5FF\U0001F680-\U0001F6FF\U0001F700-\U0001F77F\U0001F780-\U0001F7FF\U0001F800-\U0001F8FF\U0001F900-\U0001F9FF\U0001FA00-\U0001FA6F\U0001FA70-\U0001FAFF\U00002702-\U000027B0\U000024C2-\U0001F251]+'
  - ''
```

These lines were added to the `config/pre_process_map.yaml` config file by default before version 0.11.0:

4) Your new multi-lingual speaker voice is ready to use!
