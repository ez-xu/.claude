#!/bin/bash
# ============================================================================
# esp32p4_flash.sh — ESP32-P4X-C5-Function-EV-Board 自动化烧录脚本
#
# 核心价值: 通过 esptool 的 USB-JTAG 虚拟 DTR/RTS 信号自动完成
#   "按 BOOT + 按 EN/RESET + 松开 BOOT" (进入下载模式) 的动作,
#   无需任何手动按钮操作, 也无需额外硬件 (继电器/GPIO板)。
#
# 原理:
#   esptool 检测到 USB-Serial/JTAG (PID 303a:1001) 时, 自动使用
#   USBJTAGSerialReset 策略 (reset.py): 通过 USB CDC 控制线模拟
#   DTR(BOOT/GPIO0) 和 RTS(EN) 的高低电平时序, 触发芯片复位进下载模式。
#   因此 `--before default_reset` 是让 USB-JTAG 自动复位进下载模式的关键。
#
# 用法:
#   esp32p4_flash.sh <firmware.bin> [port] [baud]
#   默认 port=/dev/ttyACM0 (USJ), baud=921600
#
# 依赖: esptool.py v4.12+ (pip install esptool)
# ============================================================================
set -euo pipefail

FW=${1:?用法: esp32p4_flash.sh <firmware.bin> [port] [baud]}
PORT=${2:-/dev/ttyACM0}
BAUD=${3:-921600}

if [ ! -f "$FW" ]; then
  echo "错误: 固件文件不存在: $FW" >&2
  exit 1
fi

echo "=============================================="
echo " ESP32-P4 自动烧录 (USB-JTAG 软复位, 无需按键)"
echo " 固件: $FW"
echo " 端口: $PORT @ ${BAUD}bps"
echo "=============================================="

# --before default_reset : esptool 自动检测 USB-JTAG, 用虚拟 DTR/RTS
#                          模拟 BOOT+EN 复位进入下载模式 (替代手动按键)
# --after  hard_reset    : 烧录完成后自动硬复位运行固件
# --flash_freq 40m --flash_mode dio : SIMPLE_BOOT ram-only 固件稳定参数
esptool.py --chip esp32p4 -p "$PORT" -b "$BAUD" \
  --before default_reset \
  --after hard_reset \
  write_flash \
  --flash_freq 40m \
  --flash_mode dio \
  0x0 "$FW"

echo "=============================================="
echo " ✅ 烧录完成: Hash of data verified"
echo "    芯片已自动硬复位, 正在运行固件..."
echo "=============================================="
