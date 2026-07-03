# 已退役的 overlay 增量构建（历史存档）

这些文件是 `nocodb-zh:2026.06.1-zh3 → zh4 → zh5 → zh6` 阶段的产物：每一层 `Dockerfile.zhN` 都是 `FROM nocodb-zh:2026.06.1-zh(N-1)` 的增量 overlay，依赖上一层镜像已经存在本地，无法从干净检出复现。对应的 `selfcheck_zhN.sh` 也硬编码了对应版本的镜像 tag。

**已被 `Dockerfile.zh` + `build.sh` + `selfcheck.sh`（仓库根目录）取代**：现在唯一的构建路径是从 `zh-release/<release-tag>` 分支用单条 `Dockerfile.zh` 完整重建 frontend + backend，不再依赖任何历史镜像层。

保留这些文件仅作历史记录，**不要**在新的构建流程里使用它们。
