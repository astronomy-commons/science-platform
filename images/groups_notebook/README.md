1. Build the image
```
$ docker build --platform linux/amd64 . -t astronomycommons/lincc-notebook:testing
```

2. Get a GitHub token from: https://github.com/settings/tokens
- Click "Generate new token" --> "Generate new token (classic)"
- Add "read:user" and "read:org" permissions
- Click "Generate token"
- Copy the token to "GH_TOKEN=..." in

3. Create `run.env`:
```
$ cp run.env.template run.env
```

4. Update `run.env`
```
# file: run.env
GH_TOKEN=<paste github token here>
NB_UID=12345 # or any number 1001+
NB_USER=stevenstetzler # or any string
```

5. Run the notebook server:
```
./run.sh
```
