# goododeo-spec/nocodb 定制镜像维护索引

本文件是 `nocodb-zh` 定制镜像（中文本地化 + 附件/性能修复）的唯一维护索引。任何补丁、配置、升级操作都应先更新本文件。

维护背景与目标见对应 chat 计划：`NocoDB 定制镜像可持续维护流程`。

## 铁律（任何操作前必读）

1. **单一版本基准**：前端源码、后端 bundle、`nocodb/nocodb` 官方镜像 digest 必须对应**同一个 release tag**。禁止把 `develop` 分支的改动 cherry-pick 到面向 release 运行的构建里（历史教训：2026-06 曾发生 develop 前端装到 release 后端，导致所有数据表打不开）。
2. **先有回滚再动手**：任何 fork / 构建 / 部署操作之前，当前线上镜像必须处于"可一键回退"状态。回滚基线见下方"回滚基线"一节。
3. **服务器不是构建真相源**：`/opt/nocodb-build`（部署服务器上的构建工作区）只允许 `git fetch` + `checkout` 到 fork 的 `zh-release/*` 分支来构建镜像，**禁止**在服务器上手工 `scp` 替换源码文件或直接编辑后再打包（历史上 PR #14196 的改动就是先在服务器手工改的，之后才补提交到 fork，属于事后补救，不是常态流程）。

## 当前线上状态（截至本文档写入时）

| 项目 | 值 |
|---|---|
| 生产镜像 | `nocodb-zh:2026.06.1-zh6` |
| 镜像 digest | `sha256:677e07e2508252776f1dd7a70cc1e080d9b86108f394f40e661ce58d1e45762d` |
| 对应官方基础镜像 | `nocodb/nocodb@sha256:e5a6ac9cfa59f78b333b491efde4b6cd60bb866b49c76daf92295ef359ef710e`（release `2026.06.1`） |
| 部署位置 | `root@159.65.133.196:/opt/nocodb`（docker compose：`nocodb`/`worker`/`postgres`/`redis`/`caddy`） |
| 对象存储 | DigitalOcean Spaces（新加坡区，S3 兼容），附件走 `url` 类型 |

## 回滚基线

冻结于服务器 `/opt/nocodb/baselines/2026.06.1-zh6/`，包含：
- `docker-compose.yml`、`Caddyfile` 快照
- `image-digests.txt`（zh1~zh6 全部历史镜像 digest，均保留在本机，未清理）
- `env-keys.txt`（仅键名，不含密钥值）
- `ROLLBACK.md`（一键回滚命令 + 冒烟验证命令）

**规则**：每次升级构建产出新 tag 前，先确认这份基线仍然有效（即 `nocodb-zh:2026.06.1-zh6` 镜像仍在本机 `docker images` 中）。升级成功并稳定运行 ≥ 3 天后，才可以把基线滚动更新为新版本（旧基线不删除，重命名归档）。

## 补丁清单（三类）

### A. 可上游代码补丁（5 个 PR，全部 OPEN，合并后即删除本地对应分支/cherry-pick）

| 分支 | PR | 状态 | 内容 | drop 条件 |
|---|---|---|---|---|
| `pr/browser-language-detect` | [#14171](https://github.com/nocodb/nocodb/pull/14171) | OPEN | 浏览器语言自适应（首次进入按系统/浏览器语言而非固定英文） | PR 合并进 `develop` |
| `pr/field-type-i18n` | [#14172](https://github.com/nocodb/nocodb/pull/14172) | OPEN | 字段类型名 i18n（`getUidtI18nName`） | PR 合并进 `develop` |
| `perf/disable-prefetch-lazy-chunks` | [#14180](https://github.com/nocodb/nocodb/pull/14180) | OPEN | 关闭 Nuxt 对懒加载 chunk 的激进 prefetch（首屏性能） | PR 合并进 `develop` |
| `fix/attachment-mimetype-backfill` | [#14183](https://github.com/nocodb/nocodb/pull/14183) | OPEN | 上传时按扩展名回填 mimetype，修复 `text/plain` 误判 | PR 合并进 `develop` |
| `fix/attachment-reload-crash-guard` | [#14196](https://github.com/nocodb/nocodb/pull/14196) | OPEN | 视频不再被当图片加载（grid/carousel/thumbnail 三处 gate）+ `loadRow`/`isURLExpired` 崩溃与误报守卫 | PR 合并进 `develop` |

> `i18n-improvements` 分支（commit `dfa48b4`）是 #14171/#14172 拆分前的合并版本，**已废弃**，不再使用，仅作历史记录保留，不参与 cherry-pick。

巡检命令（人工或后续 CI 定期跑）：

```bash
gh pr view 14171 --repo nocodb/nocodb --json state,mergedAt
gh pr view 14172 --repo nocodb/nocodb --json state,mergedAt
gh pr view 14180 --repo nocodb/nocodb --json state,mergedAt
gh pr view 14183 --repo nocodb/nocodb --json state,mergedAt
gh pr view 14196 --repo nocodb/nocodb --json state,mergedAt
```

### B. 部署专用构建配置（长期保留，不上游，收纳进 `deploy/zh-build-config` 分支）

- rspack 后端构建入口改为 `src/run/local.ts`（对应 fork 分支 `zh-build-2026.06.1` 的 commit）。
- vendored 2 个后端文件（附件 MIME 相关，随 backend bundle 重建带入）。
- `Dockerfile.zh`：stage2 官方基础镜像按 digest pin 到与生产 release 一致的版本。

### C. Crowdin 翻译（临时覆盖，非长期补丁）

- 主线策略：散落漏译的 86 条通过 [Crowdin 项目](https://crowdin.com) 走官方翻译流程提交。
- **临时覆盖**：在 Crowdin 合入并随官方发布下发之前，生产镜像里保留一份本地 `packages/nc-gui/lang/zh-Hans.json` 补丁（覆盖同一批 86 条）。
- **删除条件**：Crowdin 上的翻译被官方合并且出现在某个 release tag 的 `zh-Hans.json` 中之后，下一次升级构建时移除本地覆盖补丁，改用官方文件。
- 状态：⏳ 待 Crowdin 侧合并确认（未有自动化跟踪，需人工登录 Crowdin 项目检查）。

## 运行时配置（记档，不是补丁，随镜像/compose 走）

| 配置 | 值 | 用途 |
|---|---|---|
| `NC_THUMBNAIL_MAX_SIZE` | `10485760`（10MB） | 默认 3MB 上限会导致较大图片不返回缩略图 URL，调大到覆盖实际图片大小分布 |
| Caddy `encode zstd gzip` | 开启 | 静态资源压缩 |
| Caddy `Cache-Control` (immutable) | `public, max-age=31536000, immutable` + `defer` | `/_nuxt/*` 等内容哈希文件长缓存 |
| Caddy HTTP/3 | 开启（`443/udp` 映射） | 降低高延迟链路的握手开销 |

## 集成分支与构建（详见下方"升级手册"）

- 集成分支命名：`zh-release/<release-tag>`（例如 `zh-release/2026.06.1`），从**官方镜像对应的 release tag** 建立，仅用 `cherry-pick` 叠加补丁 A + B + C，不做 merge，保持线性、可逐条 drop。
- 完整构建：唯一构建文件是 `Dockerfile.zh`（frontend 从源码 `nuxi generate`，backend 从源码 `rspack` 重建 `docker/index.js`，两者一起 overlay 到官方基础镜像 digest 之上）。历史上的 `Dockerfile.zh4/zh5/zh6` 属于逐层 overlay 增量构建，已归档，不再作为生产构建路径（见仓库 `archive/overlay-builds/` 或对应 commit 历史）。
- 构建脚本：`build.sh <release-tag>`，产物打不可变 tag `nocodb-zh:<release-tag>-<n>+git.<sha>`。

### `zh-release/2026.06.1` 已建立（10 个 cherry-pick，线性、无 merge）

从 tag `2026.06.1` cherry-pick 顺序：`pr/browser-language-detect` → `pr/field-type-i18n` → `perf/disable-prefetch-lazy-chunks` → `fix/attachment-mimetype-backfill` → `fix/attachment-reload-crash-guard`（2 个 commit）→ `deploy/zh-build-config`（3 个 commit）→ 临时 Crowdin 覆盖（86 条散落翻译）。

冲突记录（均为文件内容自然增长导致，非逻辑冲突）：
- `packages/nc-gui/lang/en.json`：cherry-pick `pr/field-type-i18n` 时与 tag 基线的 key 顺序冲突，手工合并保留双方新增 key。
- `packages/nocodb/rspack.docker.config.js`：该文件历史上被意外夹带进 `fix/attachment-mimetype-backfill` 提交（补丁归类瑕疵，未拆分历史），导致 cherry-pick `deploy/zh-build-config` 的入口切换 commit 时报 modify/delete 冲突；已用该 commit 的最终版本整体落地，`deploy/zh-build-config` 分支上该文件是完整新增而非增量修改。

**已知与当前线上 `zh6` 的预期差异**（非漂移，是待发布的改进）：`pr/field-type-i18n` 分支（`21d4a4a`）中的字段类型翻译比线上 `zh6` 实际部署的版本（源自更早的组合 commit `3f50d9f`）更新，措辞更贴近飞书多维表格命名（如"单行文本"→"文本"、"合作者"→"人员"、"URL"→"超链接"），且补了 `LinkToAnotherRecord`/`RichText`/`QrCode` 等此前缺失的 key。下次从 `zh-release/2026.06.1` 构建并发布时，这批更好的翻译会随之上线——**这是预期行为**，发布前需要在 changelog/自测里提一句"字段类型中文名有调整"，避免被当成意外改动。

## 可复现构建（`build.sh` + `selfcheck.sh`）

来源分支 `tooling/build-scripts`（已 cherry-pick 进 `zh-release/2026.06.1`）。仓库根目录：

- `build.sh <release-tag>`：要求当前分支必须是干净的 `zh-release/<release-tag>`（工作区有未提交改动会直接拒绝构建——呼应铁律 3"服务器不是构建真相源"）。用 `docker build -f Dockerfile.zh` 构建，自动计算下一个构建序号 `N`，打不可变 tag `nocodb-zh:<release-tag>-<n>+git.<sha>`，然后自动跑 `selfcheck.sh`（后续接入 `selfcheck-attachments.sh`，见 selfcheck 附件专项一节）。
- `selfcheck.sh <image-tag>`：通用化自 `mime-fix/selfcheck_zh6.sh`（原来的四份 `selfcheck_zh3~6.sh` 硬编码各自版本 tag，已归档到 `archive/overlay-builds/`）。用**一次性** postgres + 该镜像跑：健康检查 → GUI 是否正常返回（防 zh6 那次"前端不渲染"回归）→ 迁移日志无报错 → 注册/登录 → 上传 `Content-Type: text/plain` 的 `.mp4` 验证 MIME 回填生效。全程隔离容器/网络，退出时清理，不碰生产。
- 已在服务器上用生产 `nocodb-zh:2026.06.1-zh6` 镜像实测通过：`ALL_SELFCHECKS_PASSED`（health 200 / GUI 200 / MIME 回填 `text/plain` → `video/mp4`）。
- 旧的 `Dockerfile.zh4/zh5/zh6` overlay 增量构建 + 对应版本 selfcheck 脚本已归档至 `archive/overlay-builds/`，附 `README.md` 说明退役原因，不再用于生产构建。

## 升级手册（上游发新版时）

1. 确认新版本有对应的**官方 Docker 镜像**发布（不只是 GitHub tag）。
2. `git fetch upstream --tags`，基于官方镜像对应的 **release tag `vNext`** 新建 `zh-release/vNext`（从 upstream tag 建，不从 develop 建）。
3. 对补丁清单 A 逐个检查：
   - 已被上游合并 → 直接丢弃，不 cherry-pick，更新本文件状态表。
   - 仍未合并 → 从对应分支 cherry-pick 到 `zh-release/vNext`，解决冲突（若与 `vNext` 冲突较大，先评估该补丁是否仍适用）。
4. cherry-pick `deploy/zh-build-config`（补丁清单 B）到 `zh-release/vNext`。
5. 若 Crowdin 尚未合并，cherry-pick 临时 Crowdin 覆盖补丁（补丁清单 C）。
6. 修改 `Dockerfile.zh` stage2，把官方基础镜像 digest 重新 pin 到 `vNext` 对应的 digest（**铁律 1**：查清楚该 digest 确实对应 `vNext` release，而不是 `latest`/`develop` 构建）。
7. `build.sh vNext` 完整构建 → 跑 selfcheck（含附件专项，见下）。
8. selfcheck 通过后灰度切换（先切 `worker`，观察，再切 `nocodb`），冒烟验证（登录、开表、图片/视频附件加载、语言自动检测）。
9. 稳定运行后更新本文件的"当前线上状态"表 + 补丁状态表；旧 baseline 归档保留、新 baseline 按"冻结基线"流程重新生成。
10. 任一步失败：按"回滚基线"一节的命令立即退回，不在生产上尝试就地修复。

### selfcheck 附件专项（升级必跑，防止本轮 bug 回滚）

已实现为 `selfcheck-attachments.sh <host_port> <token> <repo_root> <app_container>`（`tooling/build-scripts` 分支，已 cherry-pick 进 `zh-release/2026.06.1`），由 `build.sh` 在跑完基础 `selfcheck.sh` 后自动串联执行（复用同一个still-running 实例，`selfcheck.sh` 现已把 `NC_THUMBNAIL_MAX_SIZE=10485760` 写进吞吐量实例的启动 env，与生产运行时配置对齐）：

- 建一个临时 base + 带 Attachment 字段的表；用镜像自带的 `sharp`（`docker exec` 到刚启动的 app 容器里跑）生成一张 >3MB 的测试 JPEG，上传后插入到该字段。轮询读回该行，确认 `thumbnails.tiny` / `thumbnails.small` / `thumbnails.card_cover` 三档都出现，且逐个请求其 `signedPath` 返回 `200`（对生成时序做了重试，避免三档文件写入非原子导致的偶发 404）。
- 上传一个 `.mp4`，同样流程插入行、读回，确认响应里**不**包含 `thumbnails` 字段。
- 启动时先 grep `$REPO_ROOT`（即当前 checkout 的仓库路径）里的 `packages/nc-gui/components/smartsheet/grid/canvas/cells/Attachment.ts` 是否含 `isImage(` 调用、`packages/nc-gui/components/cell/attachment/Preview/Thumbnail.vue` 的 `srcs` 计算属性是否含 `isImage(` 短路判断，缺失直接 `[FAIL]` 退出。
- **已在服务器上对生产 `nocodb-zh:2026.06.1-zh6` 镜像实测通过**：`ALL_ATTACHMENT_SELFCHECKS_PASSED`（三档缩略图 200、视频无 thumbnails、gate 均在）。

未覆盖（后续可选增强）：Carousel 里"同时有图片+视频附件时不出现未找到记录误报 toast"的端到端 UI 断言，目前仍依赖人工冒烟（见升级手册第 8 步），因为需要浏览器自动化而非纯 API 调用。

## 未做/不做的事

- 不改 NocoDB 业务代码之外的范围（本轮 bug 均已提交对应 PR，见补丁清单 A）。
- 不迁移服务器、不动数据库、不重新触碰已验证通过的附件数据。
- 不引入 CDN（已评估无收益，新加坡单区延迟已可接受）。

## （建议）CI 与巡检（可选增强，未实施）

- GitHub Actions：push/PR 到 `zh-release/*` 自动跑 `Dockerfile.zh` build smoke 或 frontend/backend 构建 smoke，尽早暴露"源码构建失败/文件缺失"。是否推送到 GHCR 供服务器直接 `docker pull`，视后续需要再决定（需要 registry secret）。
- 定期（人工或用 loop 类自动化）执行上方"补丁清单 A 巡检命令"，合并的 PR 从清单移除，让 fork 逐步瘦身到只剩补丁清单 B（3 个部署配置 commit）。
