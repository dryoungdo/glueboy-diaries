#!/bin/bash
# Assemble Ep.3 video from scene slides + narration audio
# Usage: bash assemble-video.sh

SCENES_DIR="scenes"
AUDIO="../audio/episode3.mp3"
OUTPUT="../audio/episode3-fb.mp4"

# Get audio duration
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$AUDIO" 2>/dev/null)
echo "Audio duration: ${DURATION}s"

# Scene timing (seconds per slide, roughly matching narration)
# Total: ~179 seconds = 2:59
# 12 slides, paced to narration beats
declare -a SLIDES=(
  "scene-00-flash.png:3"     # "ดีมาก" flash-forward
  "scene-01-hook.png:12"     # Hook — typing and deleting
  "scene-02-team.png:20"     # Team intro — suffer
  "scene-03-captain.png:15"  # Captain's message — turning point
  "scene-04-chaos.png:18"    # Chaos — errors everywhere
  "scene-05-fear.png:15"     # Fear — "ความทรงจำ ไม่ใช่ผู้นำ"
  "scene-06-remember.png:10" # Remember — "เป็นกาว"
  "scene-07-resolve.png:22"  # Resolve — sending clear instructions
  "scene-08-done.png:15"     # Done — git log + dawn
  "scene-09-deemak.png:12"   # "ดีมาก" — the two words
  "scene-10-lesson.png:20"   # Lesson — leadership quote
  "scene-11-end.png:17"      # End card — CTA
)

# Create concat file for ffmpeg
CONCAT_FILE="concat.txt"
> "$CONCAT_FILE"

for entry in "${SLIDES[@]}"; do
  IFS=':' read -r file dur <<< "$entry"
  filepath="${SCENES_DIR}/${file}"
  if [ -f "$filepath" ]; then
    echo "file '${filepath}'" >> "$CONCAT_FILE"
    echo "duration ${dur}" >> "$CONCAT_FILE"
    echo "  ✓ ${file} (${dur}s)"
  else
    echo "  ✗ MISSING: ${file}"
  fi
done

# Add last file again (ffmpeg concat demuxer quirk)
LAST_FILE=$(echo "${SLIDES[-1]}" | cut -d: -f1)
echo "file '${SCENES_DIR}/${LAST_FILE}'" >> "$CONCAT_FILE"

echo ""
echo "Assembling video..."

# Assemble: slides + audio → mp4
ffmpeg -y \
  -f concat -safe 0 -i "$CONCAT_FILE" \
  -i "$AUDIO" \
  -c:v libx264 -pix_fmt yuv420p -r 25 \
  -c:a aac -b:a 128k \
  -vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:color=#0a1628" \
  -shortest \
  "$OUTPUT" 2>&1

echo ""
if [ -f "$OUTPUT" ]; then
  SIZE=$(du -h "$OUTPUT" | cut -f1)
  DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUTPUT" 2>/dev/null)
  echo "✅ Video created: $OUTPUT"
  echo "   Size: $SIZE"
  echo "   Duration: ${DUR}s"
else
  echo "❌ Video creation failed"
fi

rm -f "$CONCAT_FILE"
