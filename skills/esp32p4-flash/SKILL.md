---
name: esp32p4-flash
description: "ESP32-P4X-C5-Function-EV-Board 通过 USB-JTAG 自动复位烧录固件，无需手动按 BOOT/EN 按钮。Use when: 烧录 esp32p4、刷固件、esp32p4 flash、自动进入下载模式、无需按键烧录、reset 下载模式、USB-JTAG 复位。核心价值：用 esptool 的 USBJTAGSerialReset（虚拟 DTR/RTS）自动完成『按 BOOT + 按 EN + 松 BOOT』进入下载模式的动作。"
---

# ESP32-P4 USB-JTAG 自动复位烧录

ESP32-P4X-C5-Function-EV-Board 通过 **USB-Serial/JTAG（USJ）** 接口烧录固件，
**不需要手动按住 BOOT 按钮 + 按 EN/RESET**——esptool 用 USB CDC 的虚拟 DTR/RTS
信号自动模拟这个动作。

## 关键原理（为什么不用按键）

esptool 检测到 USB-Serial/JTAG 端口（PID `303a:1001`，即 `/dev/ttyACM0`）时，
自动采用 `USBJTAGSerialReset` 复位策略（esptool/reset.py）。它通过 USB 控制线
模拟 BOOT(IO0/GPIO0) 和 EN(RTS) 的电平时序：

```
DTR=0 → RTS=0 (idle) → DTR=1 (拉 BOOT) → RTS=1 (EN 复位) → RTS=0 (松开 EN 运行) → DTR=0
```

这等价于"按住 BOOT → 按 EN → 松 BOOT"，芯片进入 ROM 下载模式，停在 `waiting for download`。

**关键参数**：`--before default_reset`（让 esptool 自动复位进下载模式）
+ `--after hard_reset`（烧完自动复位运行固件）。

**注意**：不要用 `--before no_reset` —— 那会绕过复位逻辑，且会导致擦除/写入
在旧 stub 状态下失败（历史教训：`MD5 of file does not match data in flash`）。

## 前置条件

1. 板子 USB-JTAG 接口接入电脑（`/dev/ttyACM0`，`lsusb` 显示 `303a:1001 Espressif USB JTAG/serial debug unit`）
2. `esptool.py` v4.12+（`pip install esptool`）
3. 固件为 SIMPLE_BOOT ram-only 镜像（`nuttx.bin`）

## 一键烧录命令

```bash
# 方式一：使用封装脚本（推荐）
bash /home/ez/share/openvela/tools/esp32p4_flash.sh <firmware.bin> [port] [baud]

# 方式二：直接 esptool（等效）
esptool.py --chip esp32p4 -p /dev/ttyACM0 -b 921600 \
  --before default_reset --after hard_reset \
  write_flash --flash_freq 40m --flash_mode dio 0x0 <firmware.bin>
```

**成功标志**：
- `Wrote <N> bytes ... at 0x00000000`
- `Hash of data verified.`（MD5 校验通过，flash 内容正确）
- `Hard resetting via RTS pin...`（自动复位运行固件）

## 常用操作

### 只进入下载模式（等效手动按 BOOT+EN）

```bash
esptool.py --chip esp32p4 -p /dev/ttyACM0 -b 115200 --before default_reset chip_id
# 或 flash_id（读 flash 型号）
```

执行后芯片复位进下载模式，停住等待。日志会出现 `boot:0x307 (DOWNLOAD(USB/UART0/SPI))`。

### 只复位运行固件（等效按 EN）

```bash
esptool.py --chip esp32p4 -p /dev/ttyACM0 -b 115200 \
  --before default_reset --after hard_reset chip_id
```

### 擦除 flash

```bash
esptool.py --chip esp32p4 -p /dev/ttyACM0 -b 115200 \
  --before default_reset --after hard_reset erase_flash
```

### 读回验证 flash 内容

```bash
esptool.py --chip esp32p4 -p /dev/ttyACM0 -b 115200 \
  --before default_reset read_flash 0x0 0x1000 /tmp/head.bin
```

## 常见问题排查

| 现象 | 原因 | 解决 |
|---|---|---|
| `MD5 of file does not match data in flash!` | 用了 `--before no_reset` 或 USB 直通丢字节 | 改用 `--before default_reset`；必要时降波特率/降 `--flash_freq` |
| `Wrong boot mode detected` | 芯片没进下载模式 | 确认用 `default_reset`；检查 USB-JTAG 是否真的是 303a:1001 |
| `SerialException: device disconnected` | 复位时 USJ 重枚举，串口短暂断开 | esptool 自动重试；脚本/操作间隔留 1-2 秒 |
| 烧录成功但无 boot 输出 | 固件本身问题（如 ai_agent 无 PSRAM 时堆不足 boot 卡死） | 检查固件配置，非烧录问题 |

## 板子硬件信息

- USB-JTAG/Serial：`/dev/ttyACM0`（PID 303a:1001），也是 NuttX 的 USJ console（`CONFIG_ESPRESSIF_USBSERIAL=y`）
- UART0（可选调试）：`/dev/ttyUSB0`（CP2102，GPIO37=U0TXD / GPIO38=U0RXD）
- Flash：16MB（GigaDevice GD25Q128）
- SIMPLE_BOOT ram-only 固件稳定参数：`--flash_freq 40m --flash_mode dio`
