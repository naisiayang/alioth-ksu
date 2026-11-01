#!/usr/bin/env bash
# ============================================================
# alioth (POCO F3 / Mi 11) KernelSU 内核编译脚本  -- 在 WSL Ubuntu 内运行
# 用法:  sudo apt update && sudo apt install -y ...(见 deps) ; bash build-alioth-ksu.sh
# 产物:  /mnt/e/alioth_ksu/out/alioth-KernelSU-kernel.zip  (AnyKernel3, 可 fastboot/sideload 刷)
# ============================================================
set -e
KSU_TAG="v0.9.5"          # 4.19 非 GKI 最后支持版本
WORK="/mnt/e/alioth_ksu"
KERNEL="$WORK/kernel"
TOOL="$WORK/toolchain"
OUT="$WORK/out"
DEFCONFIG_BASE="alioth_defconfig"

echo "[*] 1/6 安装依赖 (首次)"
sudo apt-get update
sudo apt-get install -y bc bison build-essential ccache curl flex g++-multilib \
  gcc-multilib git gnupg gperf imagemagick lib32z1-dev libelf-dev liblz4-tool \
  libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop \
  pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev python3 cpio \
  kmod device-tree-compiler unzip wget

echo "[*] 2/6 拉取内核源码 alioth-r-oss"
mkdir -p "$WORK"
if [ ! -d "$KERNEL/.git" ]; then
  git clone --depth=1 -b alioth-r-oss https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git "$KERNEL"
fi

echo "[*] 3/6 拉取工具链 (gcc-arm64/gcc-arm + AOSP clang)"
mkdir -p "$TOOL"; cd "$TOOL"
[ -d gcc-arm64 ] || git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git gcc-arm64
[ -d gcc-arm   ] || git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git   gcc-arm
if [ ! -d clang ]; then
  mkdir clang
  curl -sL "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/tags/android-12.0.0_r1/clang-r416183b.tar.gz" -o clang.tar.gz
  tar xzf clang.tar.gz -C clang
fi

echo "[*] 4/6 集成 KernelSU (非GKI drivers/ 结构)"
cd "$KERNEL"
wget -q "https://cdn.jsdelivr.net/gh/tiann/KernelSU@${KSU_TAG}/kernel/setup.sh" -O /tmp/ksu-setup.sh
bash /tmp/ksu-setup.sh "$KSU_TAG"
# 验证接入
grep -q kernelsu drivers/Makefile || { echo "[!] setup.sh 未写入驱动, 手动接入"; 
  echo 'obj-$(CONFIG_KSU) += kernelsu/' >> drivers/Makefile; }
grep -q "drivers/kernelsu/Kconfig" drivers/Kconfig || \
  sed -i '/endmenu/i source "drivers/kernelsu/Kconfig"' drivers/Kconfig

echo "[*] 5/6 配置并编译 Image"
export ARCH=arm64 SUBARCH=arm64
export CC="$TOOL/clang/bin/clang"
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE="$TOOL/gcc-arm64/bin/aarch64-elf-"
export CROSS_COMPILE_ARM32="$TOOL/gcc-arm/bin/arm-eabi-"
export PATH="$TOOL/clang/bin:$PATH"

# 选 defconfig: alioth 常见为 vendor/alioth_defconfig
DEFCONFIG=""
for c in vendor/alioth_defconfig vendor/alioth_user_defconfig arch/arm64/configs/alioth_defconfig vendors/alioth_defconfig; do
  f="arch/arm64/configs/$c"; [ -f "$f" ] && DEFCONFIG="$(basename $c .defconfig)" && { echo "  使用 defconfig: $c"; break; }
done
[ -z "$DEFCONFIG" ] && { echo "[!] 未找到 alioth defconfig, 列出候选:"; ls arch/arm64/configs | grep -i alioth; exit 1; }

mkdir -p "$OUT" && rm -rf "$OUT"/*
make O="$OUT" ARCH=arm64 "$DEFCONFIG"
# 确保 KSU 编入
scripts/config --file "$OUT/.config" -e KSU 2>/dev/null || echo "CONFIG_KSU=y" >> "$OUT/.config"
make O="$OUT" ARCH=arm64 olddefconfig
make -j"$(nproc)" O="$OUT" ARCH=arm64 \
  CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
  CROSS_COMPILE="$TOOL/gcc-arm64/bin/aarch64-elf-" \
  CROSS_COMPILE_ARM32="$TOOL/gcc-arm/bin/arm-eabi-" \
  Image
IMG="$(find "$OUT" -name Image | head -1)"
echo "[+] 内核镜像: $IMG"; ls -la "$IMG"

echo "[*] 6/6 AnyKernel3 打包"
cd "$WORK"
[ -d AnyKernel3-master ] || (unzip -o anykernel3/ak3.zip -d anykernel3 >/dev/null && cp -r anykernel3/AnyKernel3-master ./AnyKernel3)
cp "$IMG" AnyKernel3/Image
cd AnyKernel3
# 设备名改写
sed -i 's/^kernel.string=.*/kernel.string=alioth KernelSU/' anykernel.sh 2>/dev/null || true
grep -q "alioth" anykernel.sh || echo 'device.name1=alioth' >> anykernel.sh
zip -r9 "$OUT/alioth-KernelSU-kernel.zip" * -x .git README.md '*placeholder'
echo "[+] 成品: $OUT/alioth-KernelSU-kernel.zip"
echo "    刷入: fastboot flash boot <img> 或 recovery sideload 该zip"
