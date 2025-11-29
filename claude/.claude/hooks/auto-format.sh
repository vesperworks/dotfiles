#!/bin/bash

# auto-format.sh - 自動フォーマット・Lint・テスト実行スクリプト
# ファイルの種類に応じて適切なツールを実行する

# Claudeから渡される引数を取得
TOOL_NAME="$1"
shift # 最初の引数（ツール名）を除去

# デバッグモード（環境変数で制御）
DEBUG="${CLAUDE_HOOKS_DEBUG:-false}"
DEBUG_LOG="$HOME/.claude/hooks/debug.log"

# デバッグログ関数
debug_log() {
    [[ "$DEBUG" == "true" ]] && echo "[auto-format.sh] $1" >> "$DEBUG_LOG"
}

# 引数をログ
debug_log "Tool: $TOOL_NAME, Args: $@"

# ファイルパスを高速抽出（jqを使用）
extract_file_path() {
    local args="$@"
    
    # JSON形式の引数からfile_pathを抽出
    echo "$args" | jq -r '.file_path // empty' 2>/dev/null || {
        # jqが失敗した場合は正規表現でフォールバック
        if [[ "$args" =~ \"file_path\":[[:space:]]*\"([^\"]+)\" ]]; then
            echo "${BASH_REMATCH[1]}"
        fi
    }
}

# プロジェクトルートを高速検索（fdを使用）
find_project_root() {
    local dir="$1"
    
    # fdで.git、package.json、pyproject.tomlを高速検索
    local root=$(fd -H -t f -E node_modules -E .venv '(^\.git$|^package\.json$|^pyproject\.toml$)' "$dir" -x dirname {} \; 2>/dev/null | head -1)
    
    if [ -n "$root" ]; then
        echo "$root"
    else
        # フォールバック：親ディレクトリを遡って検索
        while [ "$dir" != "/" ]; do
            if [ -f "$dir/package.json" ] || [ -f "$dir/pyproject.toml" ] || [ -d "$dir/.git" ]; then
                echo "$dir"
                return 0
            fi
            dir=$(dirname "$dir")
        done
        echo "$1"
    fi
}

# メイン処理
main() {
    # 開始時刻を記録（パフォーマンス測定用）
    local start_time=$(date +%s.%N)
    
    # ファイルパスを抽出
    FILE_PATH=$(extract_file_path "$@")
    
    if [ -z "$FILE_PATH" ]; then
        debug_log "ファイルパスが見つかりません"
        exit 0
    fi
    
    debug_log "Processing: $FILE_PATH"
    
    # ファイルが存在しない場合はスキップ
    if [ ! -f "$FILE_PATH" ]; then
        debug_log "ファイルが存在しません: $FILE_PATH"
        exit 0
    fi
    
    # 拡張子を取得
    EXTENSION="${FILE_PATH##*.}"
    BASENAME=$(basename "$FILE_PATH")
    DIRNAME=$(dirname "$FILE_PATH")
    
    # プロジェクトルートを探す
    PROJECT_ROOT=$(find_project_root "$DIRNAME")
    cd "$PROJECT_ROOT" || exit 1
    
    debug_log "Project root: $PROJECT_ROOT"
    
    # 拡張子に応じて処理を分岐
    case "$EXTENSION" in
        js|ts|tsx|jsx|mjs|cjs)
            echo "🚀 TypeScript/JavaScript ファイルを処理中: $BASENAME"
            
            # package.jsonが存在する場合のみ実行
            if [ -f "package.json" ]; then
                # jqで高速にscriptsセクションを解析
                local scripts=$(jq -r '.scripts | keys[]' package.json 2>/dev/null)
                
                # 並列実行用のコマンド配列
                local commands=()
                
                # formatスクリプトが存在するか確認
                if echo "$scripts" | rg -q '^format$'; then
                    debug_log "Running: nr format"
                    commands+=("nr format")
                fi
                
                # lintスクリプトが存在するか確認
                if echo "$scripts" | rg -q '^lint$'; then
                    debug_log "Running: nr lint"
                    commands+=("nr lint")
                fi
                
                # testスクリプトが存在するか確認（CIモードで実行）
                if echo "$scripts" | rg -q '^test$'; then
                    debug_log "Running: nr test"
                    commands+=("CI=true nr test --run")
                fi
                
                # コマンドを並列実行（GNU parallelがある場合）
                if command -v parallel &> /dev/null && [ ${#commands[@]} -gt 0 ]; then
                    printf "%s\n" "${commands[@]}" | parallel --jobs 3 --keep-order "{} 2>&1" || true
                else
                    # parallelがない場合は順次実行
                    for cmd in "${commands[@]}"; do
                        eval "$cmd 2>&1" || true
                    done
                fi
            else
                debug_log "package.jsonが見つかりません"
            fi
            ;;
            
        py)
            echo "🐍 Python ファイルを処理中: $BASENAME"
            
            # uvが利用可能か確認
            if command -v uv &> /dev/null; then
                # 並列実行用のコマンド配列
                local commands=()
                
                # 特定のファイルのみフォーマット（高速化）
                commands+=("uv run ruff format '$FILE_PATH'")
                commands+=("uv run ruff check '$FILE_PATH' --fix")
                
                # pytestが利用可能な場合は関連テストのみ実行
                if uv pip list 2>/dev/null | rg -q pytest; then
                    # ファイル名からテストファイルを推測
                    local test_file=$(echo "$FILE_PATH" | sed 's/\.py$/\_test.py/')
                    if [ -f "$test_file" ]; then
                        commands+=("uv run pytest -xvs '$test_file'")
                    fi
                fi
                
                # コマンドを並列実行
                if command -v parallel &> /dev/null && [ ${#commands[@]} -gt 0 ]; then
                    printf "%s\n" "${commands[@]}" | parallel --jobs 3 --keep-order "eval {} 2>&1" || true
                else
                    for cmd in "${commands[@]}"; do
                        eval "$cmd 2>&1" || true
                    done
                fi
            else
                debug_log "uvが見つかりません"
            fi
            ;;
            
        sh)
            echo "🐚 Shell Script ファイルを処理中: $BASENAME"
            
            # 並列実行用のコマンド配列
            local commands=()
            
            # shfmtが利用可能か確認
            if command -v shfmt &> /dev/null; then
                debug_log "Running: shfmt -w"
                commands+=("shfmt -w '$FILE_PATH'")
            else
                debug_log "shfmtが見つかりません"
            fi
            
            # shellcheckが利用可能か確認
            if command -v shellcheck &> /dev/null; then
                debug_log "Running: shellcheck"
                commands+=("shellcheck '$FILE_PATH'")
            else
                debug_log "shellcheckが見つかりません"
            fi
            
            # コマンドを実行
            for cmd in "${commands[@]}"; do
                eval "$cmd 2>&1" || true
            done
            ;;
            
        *)
            debug_log "未対応の拡張子: $EXTENSION"
            ;;
    esac
    
    # 処理時間を計算
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    
    echo "✅ 処理完了 (${duration}秒): $BASENAME"
    debug_log "処理完了 (${duration}秒): $FILE_PATH"
}

# メイン処理を実行
main "$@"