# ============================================================
# 刷入 KernelSU 内核 / 回滚 stock boot  (Windows PowerShell + fastboot)
# 前提: bootloader 已解锁; 已有 stock boot.img 备份; 编译出 alioth-KernelSU-kernel.zip 或用任意内核 zip 里的 boot
# ============================================================
$W = "E:\alioth_ksu"
$adb = "adb"; $fb = "fastboot"

Write-Host "[*] 确认设备"
& $fb devices

# ---- 备份: 用官方 ROM 提取的 stock boot.img (必须已有) ----
$stockBoot = "$W\stock\boot_stock.img"
if (Test-Path $stockBoot) { Write-Host "[+] stock boot 备份存在: $stockBoot" }
else { Write-Host "[!] 缺少 stock boot 备份, 先放 $stockBoot 再刷" }

# ---- 刷入 KernelSU 内核 ----
# 方案1: 直接刷 boot 分区 (若已从 anykernel zip 提取 Image 打包成 boot.img)
# & $fb flash boot_a "$W\out\ksu_boot.img"

# 方案2: 用 AnyKernel3 的 boot.img (若有编译出的 boot.img)
Write-Host "[*] 刷入 boot_a (示例路径, 按实际改)"
# & $fb flash boot_a "$W\out\ksu_boot.img"

# ---- 回滚 stock ----
# & $fb flash boot_a $stockBoot

Write-Host "[*] 刷完执行: fastboot reboot"
# & $fb reboot
