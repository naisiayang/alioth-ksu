# ============================================================
# KernelSU root 隐藏环境 完整方案 (alioth / HyperOS V816 / A13)
# 目标: 骗过 SafetyNet/Play Integrity / 银行App / 游戏反作弊 / 检测 su、内核痕迹、SUSFS、Zygisk
# ============================================================

## 0. 组件清单
- KernelSU Manager (内核root管理, 自带 "卸载隐藏" 隐藏自身包名)
- ZygiskNext        (KernelSU 内建 Zygisk 的替代, 提供 Zygisk 环境)  -> 需装
- Shamiko           (隐藏 root / su / mount 痕迹, 配合 Zygisk)       -> 需装
- PlayIntegrityFix  (或 PIF + Tricky Store, 修复 Play Integrity)     -> 需装
- TrickyStore       (伪造 keystore/证书链, 过 STRONG integrity)      -> 视需要
- LSPosed (Zygisk版) (模块框架, 按需)
- Susfs4KernelSU    (内核级路径/挂载隐藏, 若内核编译时集成)          -> 可选但最强

## 1. KernelSU Manager 设置
1) 打开 KernelSU -> 设置 -> 打开 "启用 Zygisk" (若内核支持自带 zygsik; 否则用 ZygiskNext)
2) 设置 -> 打开 "卸载隐藏" / "Umount modules" 设为默认开 (对检测App默认不挂载模块)
3) 应用管理: 对 银行/游戏/检测类App 关闭 root 授权 (禁止其请求 su)
4) 设置 -> 隐藏 KernelSU App 图标 (随机包名)

## 2. 安装模块 (KernelSU Manager -> 模块 -> 从存储安装 zip)
按顺序装:
  a. ZygiskNext-*.zip
  b. Shamiko-*.zip
  c. PlayIntegrityFix-*.zip
  d. (可选) TrickyStore-*.zip  + keybox.xml
  e. (可选) LSPosed-zygisk-*.zip
每个装完重启。

## 3. Shamiko 配置
- Shamiko 免配置, 装即生效, 默认 "whitelist 模式"
- 在 KernelSU 设置里关闭 "Enforce DenyList" (Shamiko 用 DenyList 做黑名单但需 KernelSU 不强制)
- 需要隐藏的App加入 KernelSU 的 "DenyList"(排除列表), Shamiko 会对其 unmount 所有模块
- 文件: /data/adb/shamiko/whitelist (创建此文件切换到白名单模式)

## 4. Play Integrity 修复
- 装 PlayIntegrityFix, 重启, 清 com.google.android.gms 缓存
- 用 "Play Integrity API Checker" 验证: 目标 MEETS_DEVICE_INTEGRITY 绿, BASIC 绿
- 若 STRONG 红: 上 TrickyStore + 有效 keybox.xml(自行获取), 并 "attest keybox"
- 关闭 GMS 的 "Play 保护机制" 对 root 检测的干扰: 设备管理里 GMS 建议清数据一次

## 5. 内核级痕迹 (SUSFS, 最强, 需内核集成)
- 编译内核时若集成 susfs4ksu patch, 可在 KernelSU 里用 susfs 命令/模块隐藏:
  - 隐藏 /data/adb、/proc/self/maps 中 ksu 段、随机化 su 路径
  - 安装 "susfs4ksu" 模块 + 在 ksu 设置开 susfs
- 未集成 susfs 时, Shamiko + ZygiskNext 已能过绝大多数检测

## 6. 验证清单
adb shell commands:
  - su -v                 # 应能被 KernelSU 管理 (装 Manager 后才有)
  - 装 "RootBeer Fresh"   # 全绿
  - 装 "Play Integrity API Checker"  # DEVICE/BASIC 绿
  - 装 "YASNAC"           # 过
  - 银行App 正常打开

## 7. 隐藏 su 二进制/路径 (KernelSU 内核态默认无 /system su 文件)
- KernelSU 是内核态 su, 手机上不存在 su 可执行文件 -> 天然躲过 "找 su 文件" 类检测
- 仅 /data/adb/ksu 存在, Shamiko 会处理该路径的泄漏
- 内核版本字符串含 "ksu" 时: 编译时用 CONFIG_KSU + ksu 的 "uname 改写" 或在 anykernel.sh 里 sed 内核 cmdline

## 8. 关键: 别装 LSPosed 未隐藏 + 别开 KernelSU 自带的 su 日志
