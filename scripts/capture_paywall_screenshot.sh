#!/bin/zsh
# 인앱 구매 심사용 스크린샷 — 말문 Pro 결제 화면 (상품마다 한 장: 그 상품이 선택된 모습).
#
# 사용법: scripts/capture_paywall_screenshot.sh <시뮬레이터 UDID> [연간가격] [평생가격] [로케일 ...]
#         기본: \$19.99 \$39.99, 로케일 en-US ko
#
# 준비: Debug 빌드를 그 시뮬레이터에 설치한다. 상품이 아직 App Store Connect 에 없어 시뮬레이터가
#       가격을 못 불러오므로, Debug 전용 -ScreenshotPaywall 인자로 가격을 준다 (ScreenshotPaywallView).
#       가격을 App Store Connect 에서 다르게 정했으면 그 값으로 다시 찍는다.
# 결과: docs/screenshots/iap-review/<로케일>/1-pro-yearly.png · 2-pro-lifetime.png (1242×2688)
#       → App Store Connect ▸ 앱 ▸ 구독/인앱 구매 ▸ 그 상품 ▸ 심사 정보 ▸ 스크린샷
set -e
U=$1; shift
YEARLY=${1:-\$19.99}; LIFETIME=${2:-\$39.99}
(( $# >= 2 )) && shift 2 || shift $#
LOCALES=(en-US ko)
(( $# )) && LOCALES=("$@")
APP=com.devkoan.IndonesianSmallTalk
ROOT=${0:A:h:h}
OUT=$ROOT/docs/screenshots/iap-review

typeset -A LANG_OF LOCALE_OF
LANG_OF=(ko ko en-US en ja ja zh-Hans zh-Hans es-MX es id id)
LOCALE_OF=(ko ko_KR en-US en_US ja ja_JP zh-Hans zh_CN es-MX es_MX id id_ID)

xcrun simctl boot $U 2>/dev/null || true
xcrun simctl bootstatus $U >/dev/null
xcrun simctl ui $U appearance light
xcrun simctl status_bar $U override --time 9:41 --batteryState charged --batteryLevel 100 \
  --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4

for loc in $LOCALES; do
  mkdir -p $OUT/$loc
  for sel in yearly lifetime; do
    xcrun simctl terminate $U $APP 2>/dev/null || true
    xcrun simctl launch $U $APP -hasSeenOnboarding YES -AppleLanguages "(${LANG_OF[$loc]})" \
      -AppleLocale ${LOCALE_OF[$loc]} -ScreenshotPaywall "$YEARLY,$LIFETIME" -ScreenshotSelect $sel >/dev/null
    sleep 9   # 시트가 다 올라올 때까지
    n=$([[ $sel == yearly ]] && echo 1 || echo 2)
    raw=$OUT/$loc/.raw-$sel.png
    rm -f $raw $OUT/$loc/$n-pro-$sel.png
    # 첫 실행이 늦으면 빈 화면이 찍힌다 — 화면 가운데가 한 색이면 조금 더 기다렸다 다시 찍는다
    for try in 1 2 3 4; do
      rm -f $raw
      xcrun simctl io $U screenshot --type=png $raw >/dev/null 2>&1
      python3 -c "
import sys; from PIL import Image
im=Image.open('$raw').convert('L'); w,h=im.size
lo,hi=im.crop((w//8,h//4,w*7//8,h*3//4)).getextrema(); sys.exit(0 if hi-lo>40 else 1)" && break
      sleep 4
    done
    # 6.9" 캡처(1320×2868) → 제출 규격 1242×2688
    ffmpeg -loglevel error -y -i $raw -vf "scale=1242:2699,crop=1242:2688" $OUT/$loc/$n-pro-$sel.png
    rm -f $raw
    echo "$loc $sel → $OUT/$loc/$n-pro-$sel.png"
  done
done
xcrun simctl terminate $U $APP 2>/dev/null || true
xcrun simctl status_bar $U clear
