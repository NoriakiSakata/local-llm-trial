#!/bin/bash
# スクリーンショット生成: 画面ごとにビルドし、ライト/ダークで1枚ずつ撮る。
# 使い方: bash tool/shoot.sh            （全6画面）
#         bash tool/shoot.sh beans      （指定画面だけ）
set -u
cd "$(dirname "$0")/.." || exit 1
export PATH="/private/tmp/qw-toolbin:$PATH"

BUNDLE=dev.brewlog.brewLog
OUT=screenshots
mkdir -p "$OUT"
TABS=("$@")
if [ ${#TABS[@]} -eq 0 ]; then
  TABS=(brew running log beans stats settings)
fi

for tab in "${TABS[@]}"; do
  echo "== build $tab"
  fvm flutter build ios --simulator --debug -t lib/demo/demo_main.dart \
      --dart-define=DEMO_TAB="$tab" >/tmp/build_$tab.log 2>&1 || {
    echo "BUILD FAILED: $tab (see /tmp/build_$tab.log)"; tail -5 /tmp/build_$tab.log; continue;
  }
  xcrun simctl install booted build/ios/iphonesimulator/Runner.app >/dev/null 2>&1

  for mode in light dark; do
    xcrun simctl ui booted appearance "$mode" >/dev/null 2>&1
    xcrun simctl launch --terminate-running-process booted "$BUNDLE" >/dev/null 2>&1
    sleep 6
    xcrun simctl io booted screenshot "$OUT/${tab}_$mode.png" >/dev/null 2>&1 \
      || echo "SHOT FAILED: ${tab}_$mode"
    echo "shot ${tab}_$mode"
  done
done
xcrun simctl ui booted appearance light >/dev/null 2>&1
md5 "$OUT"/*.png | sort
