
#!/usr/bin/env bash
set -Eeuo pipefail

# ================== Runtime state ==================
APP="wf-recorder"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
STATE_DIR="$RUNTIME_DIR/wfrec"
PIDFILE="$STATE_DIR/pid"            # 存放 wf-recorder 进程 ID
SAVEPATH_FILE="$STATE_DIR/save_path"  # 存放当前录制的文件路径
LOGFILE="$STATE_DIR/wf-recorder.log"  # 存放 wf-recorder 的日志

# 存放持久化配置
CFG_CODEC="$STATE_DIR/codec"
CFG_FPS="$STATE_DIR/framerate"
CFG_MIC_AUDIO="$STATE_DIR/mic_audio"
CFG_SYS_AUDIO="$STATE_DIR/sys_audio"
CFG_DRM="$STATE_DIR/drm_device"
CFG_EXT="$STATE_DIR/container_ext"

mkdir -p "$STATE_DIR"
MODE_DECIDED="" # 临时存储选择的模式

# ================== Tunables (ENV overridable) ==================

# 默认值
_DEFAULT_CODEC="h264_vaapi"
_DEFAULT_FRAMERATE=""
_DEFAULT_MIC_AUDIO="off"
_DEFAULT_SYS_AUDIO="on"
_DEFAULT_SAVE_EXT="auto"

# 从文件加载持久化设置
codec_from_file=$(cat "$CFG_CODEC" 2>/dev/null || true)
fps_from_file=$(cat "$CFG_FPS" 2>/dev/null || true)
mic_audio_from_file=$(cat "$CFG_MIC_AUDIO" 2>/dev/null || true)
sys_audio_from_file=$(cat "$CFG_SYS_AUDIO" 2>/dev/null || true)
drm_from_file=$(cat "$CFG_DRM" 2>/dev/null || true)
ext_from_file=$(cat "$CFG_EXT" 2>/dev/null || true)

# 优先级: 环境变量 > 持久化文件 > 默认值
CODEC="${CODEC:-${codec_from_file:-$_DEFAULT_CODEC}}"
FRAMERATE="${FRAMERATE:-${fps_from_file:-$_DEFAULT_FRAMERATE}}"
MIC_AUDIO="${MIC_AUDIO:-${mic_audio_from_file:-$_DEFAULT_MIC_AUDIO}}"
SYS_AUDIO="${SYS_AUDIO:-${sys_audio_from_file:-$_DEFAULT_SYS_AUDIO}}"
DRM_DEVICE="${DRM_DEVICE:-${drm_from_file:-}}"
SAVE_EXT="${SAVE_EXT:-${ext_from_file:-$_DEFAULT_SAVE_EXT}}"

# 其他可配置变量
TITLE="${TITLE:-}"
SAVE_DIR_ENV="${SAVE_DIR:-}"
SAVE_SUBDIR_FS="${SAVE_SUBDIR_FS:-fullscreen}"
OUTPUT="${OUTPUT:-}"
OUTPUT_SELECT="${OUTPUT_SELECT:-auto}"
MENU_TITLE_OUTPUT="${MENU_TITLE_OUTPUT:-}"
MENU_BACKEND="${MENU_BACKEND:-auto}"
RECORD_MODE="${RECORD_MODE:-ask}"
MODE_MENU_TITLE="${MODE_MENU_TITLE:-Select recording mode}"
REC_AREA="${REC_AREA:-}"
GEOM_IN_NAME="${GEOM_IN_NAME:-off}"
PKILL_AFTER_STOP="${PKILL_AFTER_STOP:-on}"

# ================== Utils ==================

# 检查命令是否存在
has() { command -v "$1" >/dev/null 2>&1; }

# 语言设置 (只保留中文)
lang_code() { echo zh; }

# 消息字典
msg() {
  local id="$1"; shift
  case "$(lang_code)" in
    zh)
      case "$id" in
        err_wf_not_found) printf "未找到 wf-recorder" ;;
        err_need_slurp)   printf "需要 slurp 以进行区域选择" ;;
        warn_drm_ignored) printf "警告：DRM_DEVICE=%s 不存在或不可读，将忽略。" "$@" ;;
        warn_invalid_fps) printf "警告：FRAMERATE=\"%s\" 非法，已忽略。" "$@" ;;
        warn_render_unreadable) printf "警告：无效的 render 节点：%s" "$@" ;;
        cancel_no_mode)   printf "已取消：未选择录制模式。" ;;
        cancel_no_output) printf "已取消：未选择输出。" ;;
        cancel_no_region) printf "已取消：未选择区域。" ;;
        warn_multi_outputs_cancel) printf "检测到多个输出但未选择，已取消。" ;;
        notif_started_full)   printf "开始录制（全屏：%s）→ %s" "$@" ;;
        notif_started_region) printf "开始录制（区域）→ %s" "$@" ;;
        notif_device_suffix)  printf "（设备 %s）" "$@" ;;
        notif_saved)    printf "录制已保存：%s" "$@" ;;
        notif_stopped)  printf "录制已停止（未保存文件）。" ;;
        notif_failed_start) printf "录制启动失败！" ;;
        already_running) printf "录制已在运行中。" ;;
        not_running)     printf "录制未在运行。" ;;
        title_mode)      printf "选择录制模式" ;;
        title_output)    printf "选择输出" ;;
        menu_fullscreen) printf "全屏" ;;
        menu_region)     printf "选择区域" ;;
        title_settings)  printf "设置" ;;
        menu_settings)   printf "设置..." ;;
        menu_set_codec)  printf "编码格式：%s" "$@" ;;
        menu_set_fps)    printf "帧率：%s" "$@" ;;
        menu_set_filefmt) printf "文件格式：%s" "$@" ;;
        menu_toggle_audio) printf "麦克风：%s" "$@" ;;
        menu_toggle_sysaudio) printf "系统音频：%s" "$@" ;;
        menu_set_render) printf "渲染设备：%s" "$@" ;;
        menu_back)       printf "返回" ;;
        fps_unlimited)   printf "不限制" ;;
        render_auto)     printf "自动" ;;
        ext_auto)        printf "自动" ;;
        title_select_codec) printf "选择编码格式" ;;
        title_select_fps)   printf "选择帧率" ;;
        title_select_filefmt) printf "选择文件格式" ;;
        title_select_render) printf "选择渲染设备（/dev/dri/renderD*）" ;;
        mode_full)       printf "全屏" ;;
        mode_region)     printf "区域" ;;
        prompt_enter_number) printf "输入编号：" ;;
        menu_exit)       printf "退出" ;;
        *) printf "%s" "$id" ;;
      esac
      ;;
  esac
}

# 检查录制进程是否在运行
is_running() {
  [[ -r "$PIDFILE" ]] || return 1
  local pid; read -r pid <"$PIDFILE" 2>/dev/null || return 1
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

# 封装 notify-send
notify() { 
  local summary="${1:-}"
  local body="${2:-}"
  if has notify-send; then
    if [[ -n "$body" ]]; then
      notify-send "wf-recorder" "$summary" -b "$body"
    else
      notify-send "wf-recorder" "$summary"
    fi
  fi
}

# 获取视频保存目录
get_save_dir() {
  local videos
  if has xdg-user-dir; then videos="$(xdg-user-dir VIDEOS 2>/dev/null || true)"; fi
  videos="${videos:-"$HOME/Videos"}"
  echo "${SAVE_DIR_ENV:-"$videos/wf-recorder"}"
}

# --- render device helpers ---

# 列出可用的DRM渲染节点
list_render_nodes() {
  local d
  for d in /dev/dri/renderD*; do
    [[ -r "$d" ]] && printf '%s\n' "$d"
  done 2>/dev/null || true
}

# 显示当前选择的渲染节点
render_display() {
  local cur="${1:-}"
  if [[ -z "$cur" ]]; then
    msg render_auto
  else
    printf "%s" "$cur"
  fi
}

# 检查并返回有效的渲染节点
pick_render_device() {
  local dev="${DRM_DEVICE:-}"
  if [[ -n "$dev" && ! -r "$dev" ]]; then
    printf '%s\n' "$(msg warn_drm_ignored "$dev")" >&2
    dev=""
  fi
  echo -n "$dev"
}

# --- file format helpers ---

# 根据编码器推荐文件扩展名
ext_for_codec(){ case "${1,,}" in
  *h264*|*hevc*) echo mp4 ;;
  *vp9*)         echo webm ;;
  *av1*)         echo mkv ;;
  *)             echo mp4 ;;
esac; }

# 决定最终的文件扩展名
choose_ext(){
  local e="${SAVE_EXT,,}"
  if [[ -z "$e" || "$e" == "auto" ]]; then
    ext_for_codec "$CODEC"
  else
    case "$e" in mp4|mkv|webm) echo "$e" ;; *) echo mp4 ;; esac
  fi
}

# ================== Menus ==================

# 规范化菜单输出
__norm() { printf '%s' "$1" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

# 自动选择菜单后端
_pick_menu_backend() {
  local pref="${MENU_BACKEND,,}"
  case "$pref" in fuzzel|wofi|rofi|bemenu|fzf|term) : ;; auto|"") pref="auto" ;; *) pref="auto" ;; esac
  if [[ "$pref" != "auto" ]]; then
    if has "$pref"; then echo "$pref"; else [[ -t 0 ]] && echo "term" || echo "none"; fi
    return
  fi
  for b in fuzzel wofi rofi bemenu fzf; do has "$b" && { echo "$b"; return; }; done
  [[ -t 0 ]] && echo "term" || echo "none"
}

# 弹出选择菜单
menu_pick() { # $1:title; items...
  local title="${1:-Select}"; shift
  local items=("$@")
  ((${#items[@]})) || return 130

  local backend; backend="$(_pick_menu_backend)"
  local sel rc=130
  case "$backend" in
    fuzzel) set +e; sel="$(printf '%s\n' "${items[@]}" | fuzzel --dmenu -p "$title")"; rc=$?; set -e ;;
    wofi)   set +e; sel="$(printf '%s\n' "${items[@]}" | wofi --dmenu --prompt "$title")"; rc=$?; set -e ;;
    rofi)   set +e; sel="$(printf '%s\n' "${items[@]}" | rofi -dmenu -p "$title")"; rc=$?; set -e ;;
    bemenu) set +e; sel="$(printf '%s\n' "${items[@]}" | bemenu -p "$title")"; rc=$?; set -e ;;
    fzf)    set +e; sel="$(printf '%s\n' "${items[@]}" | fzf --prompt "$title> ")"; rc=$?; set -e ;;
    term)
      echo "$title"
      local i=1; for it in "${items[@]}"; do printf '  %d) %s\n' "$i" "$it"; ((i++)); done
      printf "%s" "$(msg prompt_enter_number)"
      local idx; set +e; read -r idx; rc=$?; set -e
      if [[ $rc -eq 0 && -n "$idx" && "$idx" =~ ^[0-9]+$ ]]; then
        if (( idx>=1 && idx<=${#items[@]} )); then sel="${items[$((idx-1))]}"; rc=0; fi
      fi
      ;;
    none) return 130 ;;
  esac
  [[ $rc -ne 0 || -z "${sel:-}" ]] && return 130
  printf '%s' "$(__norm "$sel")"
}

# ---------- Outputs ----------

# 列出所有显示器输出
list_outputs() {
  local raw
  if raw="$(wf-recorder -L 2>/dev/null)"; then :; elif has wlr-randr; then raw="$(wlr-randr 2>/dev/null | awk '/^[^ ]/{print $1}')"; else raw=""; fi
  awk 'BEGIN{RS="[ \t\r\n,]+"} /^[A-Za-z0-9_.:-]+$/ { if ($0 ~ /^(e?DP|HDMI|DVI|VGA|LVDS|Virtual|XWAYLAND)/) seen[$0]=1 } END{for(k in seen) print k}' <<<"$raw" | sort -u
}

# 决定录制哪个输出
decide_output() {
  if [[ -n "$OUTPUT" ]]; then printf '%s' "$OUTPUT"; return 0; fi
  local -a outs; mapfile -t outs < <(list_outputs || true)
  local out_title; out_title="${MENU_TITLE_OUTPUT:-$(msg title_output)}"
  if [[ "${OUTPUT_SELECT}" == "menu" ]] || { [[ "${OUTPUT_SELECT}" == "auto" ]] && ((${#outs[@]} > 1)); }; then
    local pick; pick="$(menu_pick "$out_title" "${outs[@]}")" || return 130
    printf '%s' "$pick"; return 0
  fi
  if ((${#outs[@]} == 1)); then printf '%s' "${outs[0]}"; else notify "$(msg warn_multi_outputs_cancel)"; return 130; fi
}

# ---------- Settings ----------

# 渲染设备选择菜单
choose_render_menu() {
  local -a nodes
  mapfile -t nodes < <(list_render_nodes | sort -V || true)
  local auto_item; auto_item="$(msg render_auto)"
  local pick
  if ! pick="$(menu_pick "$(msg title_select_render)" "$auto_item" "${nodes[@]}")"; then
    return 0
  fi
  if [[ "$pick" == "$auto_item" ]]; then
    DRM_DEVICE=""
    rm -f "$CFG_DRM"
    return 0
  fi
  local sel="$pick"
  if [[ -n "$sel" && -r "$sel" ]]; then
    DRM_DEVICE="$sel"
    printf '%s' "$DRM_DEVICE" >"$CFG_DRM"
  else
    notify "$(msg warn_render_unreadable "$sel")"
  fi
}

# 文件格式选择菜单
choose_filefmt_menu() {
  local auto_item; auto_item="$(msg ext_auto)"
  local pick
  if ! pick="$(menu_pick "$(msg title_select_filefmt)" "$auto_item" "mp4" "mkv" "webm")"; then
    return 0
  fi
  if [[ "$pick" == "$auto_item" ]]; then
    SAVE_EXT="auto"
    rm -f "$CFG_EXT"
  else
    case "$pick" in
      mp4|mkv|webm) SAVE_EXT="$pick"; printf '%s' "$SAVE_EXT" >"$CFG_EXT" ;;
      *) : ;;
    esac
  fi
}

# 主设置菜单
show_settings_menu() {
  while :; do
    local fps_display="${FRAMERATE:-$(msg fps_unlimited)}"
    local micaudio_display="${MIC_AUDIO}"
    local sysaudio_display="${SYS_AUDIO}"
    local render_display_now; render_display_now="$(render_display "$DRM_DEVICE")"
    local ff_display; if [[ -z "$SAVE_EXT" || "${SAVE_EXT,,}" == "auto" ]]; then ff_display="$(msg ext_auto)"; else ff_display="$SAVE_EXT"; fi

    local pick; pick="$(menu_pick "$(msg title_settings)" \
                      "$(msg menu_set_fps "$fps_display")" \
                      "$(msg menu_toggle_sysaudio "$sysaudio_display")" \
                      "$(msg menu_toggle_audio "$micaudio_display")" \
                      "$(msg menu_set_codec "$CODEC")" \
                      "$(msg menu_set_filefmt "$ff_display")" \
                      "$(msg menu_set_render "$render_display_now")" \
                      "$(msg menu_back)")" || return 0

    if [[ "$pick" == "$(msg menu_set_fps "$fps_display")" ]]; then
      local newf; newf="$(menu_pick "$(msg title_select_fps)" "60" "30" "120" "144" "165" "240" "$(msg fps_unlimited)")" || continue
      if [[ "$newf" == "$(msg fps_unlimited)" ]]; then
        FRAMERATE=""; rm -f "$CFG_FPS"
      else
        if [[ "$newf" =~ ^[0-9]+$ && "$newf" -gt 0 ]]; then FRAMERATE="$newf"; printf '%s' "$FRAMERATE" >"$CFG_FPS"; fi
      fi
    elif [[ "$pick" == "$(msg menu_toggle_sysaudio "$sysaudio_display")" ]]; then
      if [[ "$SYS_AUDIO" == "on" ]]; then SYS_AUDIO="off"; else SYS_AUDIO="on"; fi
      printf '%s' "$SYS_AUDIO" >"$CFG_SYS_AUDIO"
    elif [[ "$pick" == "$(msg menu_toggle_audio "$micaudio_display")" ]]; then
      if [[ "$MIC_AUDIO" == "on" ]]; then MIC_AUDIO="off"; else MIC_AUDIO="on"; fi
      printf '%s' "$MIC_AUDIO" >"$CFG_MIC_AUDIO"
    elif [[ "$pick" == "$(msg menu_set_codec "$CODEC")" ]]; then
      local newc; newc="$(menu_pick "$(msg title_select_codec)" \
                       "h264_vaapi" "libx264" "hevc_vaapi" \
                       "av1_vaapi"  "libsvtav1" "libaom-av1" "libvpx-vp9")" || continue
      CODEC="$newc"; printf '%s' "$CODEC" >"$CFG_CODEC"
    elif [[ "$pick" == "$(msg menu_set_filefmt "$ff_display")" ]]; then
      choose_filefmt_menu
    elif [[ "$pick" == "$(msg menu_set_render "$render_display_now")" ]]; then
      choose_render_menu
    elif [[ "$pick" == "$(msg menu_back)" ]]; then
      return 0
    fi
  done
}

# ---------- Mode selection ----------

# 录制模式选择菜单
decide_mode() {
  case "${RECORD_MODE,,}" in
    full|fullscreen) MODE_DECIDED="full";   return 0 ;;
    region|area)     MODE_DECIDED="region"; return 0 ;;
    *) ;;
  esac
  local L_FULL L_REGION L_SETTINGS L_EXIT
  L_FULL="$(msg menu_fullscreen)"; L_REGION="$(msg menu_region)"; L_SETTINGS="$(msg menu_settings)"; L_EXIT="$(msg menu_exit)";
  local title; title="$(msg title_mode)"
  while :; do
    local pick; pick="$(menu_pick "$title" "$L_FULL" "$L_REGION" "$L_SETTINGS" "$L_EXIT")" || return 130
    if   [[ "$pick" == "$L_FULL"    ]]; then MODE_DECIDED="full";   return 0
    elif [[ "$pick" == "$L_REGION"  ]]; then MODE_DECIDED="region"; return 0
    elif [[ "$pick" == "$L_SETTINGS" ]]; then show_settings_menu; continue
    elif [[ "$pick" == "$L_EXIT"    ]]; then return 130
    else return 130; fi
  done
}

# ================== Start / Stop ==================

# 开始录制
start_rec() {
  if is_running; then notify "$(msg already_running)"; exit 0; fi
  has wf-recorder || { notify "$(msg err_wf_not_found)"; exit 1; }

  MODE_DECIDED=""
  if ! decide_mode; then
    notify "$(msg cancel_no_mode)"; exit 130
  fi
  local mode="$MODE_DECIDED"

  local marker="" output="" GEOM=""
  local -a args
  
  local ROOT_DIR TARGET_DIR
  ROOT_DIR="$(get_save_dir)"
  if [[ "$mode" == "full" ]]; then TARGET_DIR="$ROOT_DIR/${SAVE_SUBDIR_FS}"; else TARGET_DIR="$ROOT_DIR"; fi
  mkdir -p "$TARGET_DIR"

  # 全屏模式
  if [[ "$mode" == "full" ]]; then
    output="$(decide_output)" || { exit 130; } 
    [[ -n "$output" ]] && args+=( -o "$output" )
    marker="FS${output:+-$output}"
  # 区域模式
  else
    if [[ -n "$REC_AREA" ]]; then
      GEOM="$REC_AREA"
    else
      has slurp || { notify "$(msg err_need_slurp)"; exit 1; }
      set +e; GEOM="$(slurp)"; local rc=$?; set -e
      if [[ $rc -ne 0 || -z "${GEOM// /}" ]]; then notify "$(msg cancel_no_region)"; exit 130; fi
    fi
    GEOM="$(echo -n "$GEOM" | tr -s '[:space:]' ' ')"
    args+=( -g "$GEOM" )
    marker="REGION"
  fi

  # 
  local ts safe_title base SAVE_PATH ext
  ts="$(date +'%Y-%m-%d-%H%M%S')"; safe_title="${TITLE// /_}"
  base="$ts${safe_title:+-$safe_title}-${marker}"
  ext="$(choose_ext)"
  SAVE_PATH="$TARGET_DIR/$base.$ext"

  args=( --file "$SAVE_PATH" "${args[@]}" )
  local dev; dev="$(pick_render_device)"; [[ -n "$dev" ]] && args+=( -d "$dev" )

  # 音频参数
  local -a audio_args=() 
  if [[ "$SYS_AUDIO" == "on" ]]; then
      audio_args+=( --audio="@DEFAULT_AUDIO_SINK@.monitor" )
  fi
  if [[ "$MIC_AUDIO" == "on" ]]; then
      audio_args+=( --audio="@DEFAULT_AUDIO_SOURCE@" )
  fi
  
  # 编码器参数
  args+=( -c "$CODEC" )
  if ((${#audio_args[@]} > 0)); then
      args+=( "${audio_args[@]}" ) 
  fi
  if [[ "$CODEC" == *"_vaapi" ]]; then
      args+=( -F "scale_vaapi=format=nv12:out_range=full:out_color_primaries=bt709" )
  else
      args+=( -F "format=yuv420p" ) 
  fi
  
  # 帧率参数
  if [[ -n "$FRAMERATE" ]]; then
    if [[ "$FRAMERATE" =~ ^[0-9]+$ && "$FRAMERATE" -gt 0 ]]; then args+=( --framerate "$FRAMERATE" )
    else notify "$(msg warn_invalid_fps "$FRAMERATE")"; fi
  fi

  # 启动 wf-recorder 进程
  >"$LOGFILE" 
  setsid nohup wf-recorder "${args[@]}" >>"$LOGFILE" 2>&1 &
  local pid=$!
  
  # 检查是否立即启动失败
  sleep 0.5 
  if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$PIDFILE"
      local err_msg; err_msg=$(tail -n 5 "$LOGFILE")
      notify "$(msg notif_failed_start)" "$err_msg"
      exit 1
  fi

  # 保存状态
  echo "$pid" >"$PIDFILE"
  echo "$SAVE_PATH" >"$SAVEPATH_FILE"

  # 发送录制开始通知
  local note; if [[ "$mode" == "full" ]]; then note="$(msg notif_started_full "$output" "$SAVE_PATH")"; else note="$(msg notif_started_region "$SAVE_PATH")"; fi
  [[ -n "$dev" ]] && note+="$(msg notif_device_suffix "$dev")"
  notify "$note"
}

# 停止录制
stop_rec() {
  if ! is_running; then notify "$(msg not_running)"; exit 0; fi
  local pid; read -r pid <"$PIDFILE"

  # 
  kill -INT "$pid" 2>/dev/null || true
  for _ in {1..40}; do sleep 0.1; is_running || break; done
  is_running && kill -TERM "$pid" 2>/dev/null || true
  sleep 0.2
  is_running && kill -KILL "$pid" 2>/dev/null || true

  # 
  rm -f "$PIDFILE"

  local save_path=""; [[ -r "$SAVEPATH_FILE" ]] && read -r save_path <"$SAVEPATH_FILE"
  if [[ -n "$save_path" && -f "$save_path" ]]; then
    ln -sf "$(basename "$save_path")" "$(dirname "$save_path")/latest.${save_path##*.}" || true
    # 
    local s; s="$(msg notif_saved "$save_path")"; notify "$s"
  else
    # 
    local s; s="$(msg notif_stopped)"
    local err_log; err_log=$(tail -n 5 "$LOGFILE" 2>/dev/null)
    [[ -n "$err_log" ]] && notify "$s" "错误详情: $err_log" || notify "$s"
  fi

  # 
  if [[ "${PKILL_AFTER_STOP,,}" != "off" ]]; then
    for sig in INT TERM KILL; do
      pgrep -x -u "$UID" "$APP" >/dev/null || break
      pkill --"$sig" -x -u "$UID" "$APP" 2>/dev/null || true
      sleep 0.1
    done
  fi
}

# ================== Main ==================

# 
case "${1:-toggle}" in
  start)        start_rec ;;
  stop)         stop_rec ;;
  is-active)    if is_running; then exit 0; else exit 1; fi ;;
  toggle)       is_running && stop_rec || start_rec ;;
  settings)     show_settings_menu ;;
  *)            echo "Usage: $0 {start|stop|toggle|is-active|settings}"; exit 2 ;;
esac

