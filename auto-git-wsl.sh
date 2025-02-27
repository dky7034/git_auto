#!/bin/bash

WATCH_DIR="."

echo "🔄 [WSL] 파일 변경 감지 중... (저장하면 자동으로 Git 반영됩니다)"
echo "📂 감시할 디렉터리: $WATCH_DIR"

# inotifywait 설치 확인 (which 명령어 사용)
if ! which inotifywait > /dev/null; then
    echo "❌ 오류: inotifywait가 설치되지 않았습니다. 실행 전 'sudo apt install inotify-tools'를 실행하세요."
    exit 1
fi

while inotifywait -r -e modify,create,delete,move "$WATCH_DIR"; do
    echo "✅ 변경 감지! Git 자동 커밋 & 푸시 실행 중..."

    cd "$WATCH_DIR" || exit 1
    BRANCH=$(git branch --show-current)

    git add .
    git status

    if git diff --cached --quiet; then
        echo "⚠ 변경된 파일이 없어서 커밋을 건너뜁니다."
    else
        git commit -m "Auto commit: $(date +"%Y-%m-%d %H:%M:%S")"
        git push origin "$BRANCH"
        echo "🚀 Git 자동 반영 완료!"
    fi
done
