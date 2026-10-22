#!/bin/zsh
# 앱스토어 스크린샷 원본 캡처 — 화면 언어마다 5장 (Debug 전용 -ScreenshotScene 로 손대지 않고 연다).
#
# 사용법: scripts/capture_store_screenshots.sh <6.9" 시뮬레이터 UDID> [화면언어 ...]
#         기본 화면 언어: ko en es id ja zh-Hans
# 준비: Debug 빌드를 그 시뮬레이터에 설치한다.
# 결과: docs/screenshots/raw/<화면언어>/01-home.png … 05-pronunciation.png (1320×2868)
#       → scripts/make_marketing_screenshots.py 가 헤드라인을 얹어 marketing/<로케일>/ 로 만든다.
set -e
U=$1; shift
LANGS=(ko en es id ja zh-Hans)
(( $# )) && LANGS=("$@")
APP=com.devkoan.IndonesianSmallTalk
ROOT=${0:A:h:h}
OUT=$ROOT/docs/screenshots/raw
SCENES=(home practice drive script pronunciation)
# 맥이 몹시 바쁘면 simctl 이 한 시간씩 멈춘다 — 초 단위로 끊고 다시 한다.
lim() { local s=$1; shift; perl -e 'alarm shift; exec @ARGV' $s "$@"; }

# 화면 언어 → 보여 줄 배울 언어 (앱의 기본값과 같다: 한국어 사용자는 인도네시아어, 영어 사용자는 한국어, 그 밖은 영어)
typeset -A LEARN LOCALE_OF
LEARN=(ko id en ko es en id en ja en zh-Hans en)
# 그 밖의 화면 언어는 앱이 영어 화면으로 여겨 한국어를 배운다 (앱 기본값)
LEARN[zh-Hant]=en   # 중국어(번체) 화면은 중국어 화면으로 여겨 영어를 배운다
for l in en-GB ru de fr pt-BR it th vi cs da el fi nb nl pl sv tr; do LEARN[$l]=ko; done
LOCALE_OF=(ko ko_KR en en_US es es_MX id id_ID ja ja_JP zh-Hans zh_CN
  en-GB en_GB zh-Hant zh_TW ru ru_RU de de_DE fr fr_FR pt-BR pt_BR it it_IT th th_TH vi vi_VN
  cs cs_CZ da da_DK el el_GR fi fi_FI nb nb_NO nl nl_NL pl pl_PL sv sv_SE tr tr_TR)

xcrun simctl boot $U 2>/dev/null || true
xcrun simctl bootstatus $U >/dev/null
xcrun simctl ui $U appearance light
xcrun simctl status_bar $U override --time 9:41 --batteryState charged --batteryLevel 100 \
  --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4
for svc in microphone speech-recognition; do xcrun simctl privacy $U grant $svc $APP 2>/dev/null || true; done

for lang in $LANGS; do
  mkdir -p $OUT/$lang
  i=0
  for scene in $SCENES; do
    i=$((i+1))
    [[ " ${SKIP_SCENES:-} " == *" $scene "* ]] && continue   # 예: SKIP_SCENES=practice
    f=$OUT/$lang/0$i-$scene.png
    lim 60 xcrun simctl terminate $U $APP 2>/dev/null || true
    lim 180 xcrun simctl launch $U $APP -hasSeenOnboarding YES -AppleLanguages "($lang)" -AppleLocale ${LOCALE_OF[$lang]} \
      -ScreenshotScene $scene -ScreenshotLearning ${LEARN[$lang]} -drive.voice NO >/dev/null || true
    sleep ${SHOT_WAIT:-7}   # 맥이 바쁘면 SHOT_WAIT=15 처럼 늘린다
    for try in 1 2 3 4; do
      rm -f $f
      lim 180 xcrun simctl io $U screenshot --type=png $f >/dev/null 2>&1 || true
      python3 -c "
import sys; from PIL import Image
im=Image.open('$f').convert('L'); w,h=im.size
lo,hi=im.crop((w//8,h//4,w*7//8,h*3//4)).getextrema(); sys.exit(0 if hi-lo>40 else 1)" && break
      sleep 4
    done
    echo "$lang $scene → $f"
  done
done
xcrun simctl terminate $U $APP 2>/dev/null || true
xcrun simctl status_bar $U clear
