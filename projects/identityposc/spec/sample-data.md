# Sample videos — provenance, license, suitability

These clips are checked-out (not version-controlled) for POC testing. Each was selected because it exhibits the multi-speaker / name-mention / visible-face pattern the system is designed to learn from.

## 1. The Computer Chronicles — "Virtual Reality" (1992)

| Field        | Value                                                                                       |
|--------------|---------------------------------------------------------------------------------------------|
| Local path   | `D:\Exp\data\sample\computer_chronicles_virtual_reality_1992.mp4`                            |
| Source URL   | `https://archive.org/download/youtube-wfHMSqQKg6s/wfHMSqQKg6s.mp4`                           |
| Item page    | `https://archive.org/details/youtube-wfHMSqQKg6s`                                            |
| License      | Public domain — *The Computer Chronicles* was released to the public domain by host/producer Stewart Cheifet. See the show's Wikipedia article for the public-domain release notice and the Internet Archive collection. |
| Format       | H.264 MP4, ~28 min, ~154 MB                                                                  |
| Why it's good for this POC | TV interview format with **multiple named speakers** in conversation: host Stewart Cheifet, co-host Gary Kildall, and named studio guests. They introduce each other ("I'm Stewart Cheifet, with us today is …") which is *exactly* the name-mention pattern the binder is designed to learn from. Real human faces, professional lighting, well-recorded studio audio. |
| Known limits | 1992 broadcast video — interlaced source, 4:3 aspect, modest resolution. Audio is mono studio quality (good for ASR, may slightly hurt speaker diarization on far guests). |

## 2. Tears of Steel (Blender Open Movie, 2012)

| Field        | Value                                                                                       |
|--------------|---------------------------------------------------------------------------------------------|
| Local path   | `D:\Exp\data\sample\tears_of_steel_720p.mov`                                                 |
| Source URL   | `https://download.blender.org/demo/movies/ToS/tears_of_steel_720p.mov`                       |
| Project page | `https://mango.blender.org/`                                                                  |
| License      | Creative Commons Attribution 3.0 (CC BY 3.0) — © copyright Blender Foundation                |
| Format       | H.264 MOV, ~12 min, ~355 MB, 720p                                                             |
| Why it's good for this POC | Live-action drama with a small cast of **named characters** (Celia, Thom, Joris, Fred) who address each other by name multiple times. Cinematic lighting and clear English dialogue make it a strong stress-test for both face recognition and ASR. |
| Known limits | Heavily stylised post-production and VFX shots may produce false face detections (faces in props, projections, etc.). Some sci-fi sound design overlays speech in places. |

## 3. Sharmilee (1971) — Hindi-language Bollywood feature

| Field        | Value                                                                                       |
|--------------|---------------------------------------------------------------------------------------------|
| Local path   | `D:\Exp\data\sample\bollywood\Sharmilee_1971.mp4` (full film, 562 MB)                       |
| 5-min clip   | `D:\Exp\data\sample\bollywood\Sharmilee_1971_clip300s.mp4` (5:00–10:00, 13.8 MB) — what the POC actually processes |
| Source URL   | `https://archive.org/download/Sharmilee/Sharmilee.mp4`                                      |
| Item page    | `https://archive.org/details/Sharmilee`                                                     |
| License      | **CC0 1.0 Public Domain Dedication** — `licenseurl: creativecommons.org/publicdomain/zero/1.0/` declared on the Internet Archive item metadata. |
| Format       | H.264 MP4, 480x360, ~165 min, ~562 MB; AAC 44.1 kHz stereo                                  |
| Why it's good for this POC | A **non-English** stress test. The pipeline runs Whisper `large-v3` with `--asr-language hi --asr-task translate` so the Hindi dialogue is rendered as English, after which the existing English NER + vocative regex picks up the romanised character names spoken in the source audio (Kanchan, Kamini, Lily, Rupa, Naren/Narendra, Dwarka). This validates the cross-language path end-to-end without any code changes to the binder. |
| Known limits | 480p VHS-era source — face recognition has more false negatives than on Tears of Steel. ECAPA fallback over-clusters voices (7 stitched speakers for ~3–4 real characters). Translated-name spellings may drift between mentions ("Lily" vs "Leeli", "Naren" vs "Narendra") which fragments votes. |

To replicate the 5-minute slice:
```powershell
ffmpeg -y -ss 300 -i D:\Exp\data\sample\bollywood\Sharmilee_1971.mp4 `
       -t 300 -c copy D:\Exp\data\sample\bollywood\Sharmilee_1971_clip300s.mp4
```

To run the POC against it:
```powershell
python -m identityposc.main `
   --source data\sample\bollywood\Sharmilee_1971_clip300s.mp4 `
   --db-path data\db\identities_bollywood.sqlite `
   --asr-language hi --asr-task translate `
   --max-seconds 300
python -m identityposc.dashboard.app --db-path data\db\identities_bollywood.sqlite
```

---

Both files were verified on download:
- HTTP `Content-Length` matches the on-disk file size.
- Both files start with a valid ISO base media `ftyp` atom (MP4/MOV magic bytes).

Authoritative SHA256 hashes (verify your local copies match):

| File                                                  | SHA256                                                             |
|-------------------------------------------------------|--------------------------------------------------------------------|
| `computer_chronicles_virtual_reality_1992.mp4`        | `73703B0C6215681AF3F82AF7F593866BBDAC43388BA1135BD4B914E67D4040B0` |
| `tears_of_steel_720p.mov`                             | `EFA9062D9CDB7A338E40AD530DFDF234806743F29AE6A1A136B97ECE4E588E8F` |
| `bollywood\Sharmilee_1971.mp4`                        | `46822D650DF6C34F8F80AF31D5EF78289D9EF19B34A5C0B982C2C01A1A971244` |

To re-verify locally:
```powershell
Get-FileHash D:\Exp\data\sample\computer_chronicles_virtual_reality_1992.mp4 -Algorithm SHA256
Get-FileHash D:\Exp\data\sample\tears_of_steel_720p.mov -Algorithm SHA256
```

## Adding more clips

Looking for additional samples? Good criteria:
1. **Multi-speaker conversation** (≥ 2 speakers, ideally 3–5).
2. **Names spoken between speakers** (introductions, vocatives like "Thanks, X" or "X, what do you think?").
3. **Visible faces** at reasonable resolution; closeups during dialogue help.
4. **Free license** — public domain, CC0, CC-BY (with attribution), or similar.
5. **Manageable size** — under ~500 MB keeps download / iteration cycles fast.

Recommended sources to mine for more candidates:
- Internet Archive (`archive.org`) — many public-domain TV interviews; search via `https://archive.org/advancedsearch.php`.
- Blender Open Movies (`download.blender.org`) — Sintel, Tears of Steel, Cosmos Laundromat (all CC BY).
- Wikimedia Commons — public-domain US-government press briefings and similar.
- C-SPAN — much content is licensed for non-commercial reuse, but check each item.

After downloading, append a new section to this file with the same fields above.
