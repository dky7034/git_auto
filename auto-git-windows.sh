#!/bin/bash

# Windows에서 실행할 경우, 경로를 자동 변환
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    SCRIPT_PATH=$(cygpath -u "$0")  # Windows 스타일 → Bash 스타일 경로 변환
else
    SCRIPT_PATH="$0"
fi

SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
WATCH_DIR="$SCRIPT_DIR"

BRANCH=$(git branch --show-current)  # 현재 Git 브랜치 가져오기

echo "🔄 [Windows] 파일 변경 감지 중... (저장하면 자동으로 Git 반영됩니다)"
echo "📂 감시할 디렉토리: $WATCH_DIR"
echo "🌿 현재 브랜치: $BRANCH"

# 🛠 `watchman` 서버 강제 재시작 (오류 방지)
echo "🛠 Watchman 서버 재시작 중..."
watchman shutdown-server
watchman watch "$WATCH_DIR"

# 🛠 기존 트리거 삭제 (있을 경우)
echo "🗑 기존 Watchman 트리거 삭제..."
watchman trigger-del "$WATCH_DIR" auto-git 2>/dev/null

# 🔥 새로운 트리거 자동 등록
echo "🔥 Watchman 트리거 등록 중..."
watchman -- trigger "$WATCH_DIR" auto-git '*' -- bash -c "
    echo '✅ 변경 감지! Git 자동 커밋 & 푸시 실행 중...'
    cd \"$WATCH_DIR\"
    git add .
    git status
    if git diff --cached --quiet; then
        echo '⚠ 변경된 파일이 없어서 커밋을 건너뜁니다.'
    else
        BRANCH=\$(git branch --show-current)
        git commit -m 'Auto commit: \$(date +\"%Y-%m-%d %H:%M:%S\")'
        git push origin \"\$BRANCH\"
        echo '🚀 Git 자동 반영 완료!'
    fi
"

# ✅ 트리거 정상 등록 확인
echo "✅ Watchman 트리거 등록 완료!"
watchman trigger-list "$WATCH_DIR"
