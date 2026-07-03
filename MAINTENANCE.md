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

前提：镜像在部署服务器（`root@159.65.133.196`）**就地构建**（无 registry/CI 推送，`build.sh` 直接在服务器的 fork 检出目录里跑 `docker build`），这是当前采用的方式（见"不做的事"之外的现状说明）——第 8 步默认按这个假设写；如果后续接了 §（建议）CI 与巡检 里的 GHCR 推送，再改成 `docker pull`。

1. **冻结新 baseline 前先确认旧 baseline 仍可回滚**：检查 `/opt/nocodb/baselines/<当前版本>/` 存在且 `docker images` 里对应 tag 还在。
2. 确认上游新版本有对应的**官方 Docker 镜像**发布（不只是 GitHub tag）：`docker pull nocodb/nocodb:<vNext候选tag>` 试拉，记下其 digest。
3. 本地 fork 工作区：`git fetch upstream --tags`，基于该 digest 对应的 **release tag `vNext`** 新建 `zh-release/vNext`（`git checkout -b zh-release/vNext vNext`，从 upstream tag 建，不从 develop 建）。
4. 对补丁清单 A 逐个用 `gh pr view <n> --repo nocodb/nocodb --json state,mergedAt` 检查：
   - 已合并（`state=MERGED`）→ 直接丢弃，不 cherry-pick，更新本文件补丁状态表，删除对应本地 topic 分支。
   - 仍未合并 → `git cherry-pick <commit>` 到 `zh-release/vNext`（挑单个补丁 commit，不是整条分支历史，做法同本次 `zh-release/2026.06.1` 的建立过程），解决冲突（多是 lang json key 顺序类的自然增量冲突，手工合并保留双方新增内容；若冲突涉及实际逻辑分歧，先评估该补丁是否仍适用于 `vNext`）。
5. `git cherry-pick`（按 `deploy/zh-build-config` 分支的 3 个 commit 逐个来，不要整分支 merge）到 `zh-release/vNext`（补丁清单 B）。
6. `git cherry-pick`（按 `tooling/build-scripts` 分支的 commit）到 `zh-release/vNext`，带上 `build.sh` / `selfcheck.sh` / `selfcheck-attachments.sh`。
7. 若 Crowdin 仍未合并，cherry-pick 临时 Crowdin 覆盖补丁（补丁清单 C，来自 `crowdin/` 目录里记录的翻译源）。
8. 编辑 `zh-release/vNext` 上的 `Dockerfile.zh` stage2，把官方基础镜像 digest 重新 pin 到第 2 步记录的 `vNext` digest（**铁律 1**：必须是 release 镜像 digest，不是 `latest`/`develop` 构建产物）。
9. push `zh-release/vNext` 到 fork。
10. 登录服务器，把 `/opt/nocodb-build` fast-forward 到 `zh-release/vNext`（`git fetch origin && git checkout zh-release/vNext`），确认 `git status` 干净（`build.sh` 会拒绝脏工作区）。
11. 服务器上执行 `./build.sh vNext`：完整构建（frontend `nuxi generate` + backend `rspack` + overlay 官方 digest）→ 自动跑 `selfcheck.sh`（含链式的 `selfcheck-attachments.sh`）。任一 `[FAIL]` 则停止，不进入第 12 步。
12. selfcheck 全部 `PASSED` 后灰度切换：先改 `docker-compose.yml` 里 `worker` 服务的 image tag 为新构建产物，`docker compose up -d worker`，观察日志/无报错；再切 `nocodb` 服务同样操作。
13. 人工冒烟：登录、打开一张已有数据表、上传并预览一张图片和一个视频附件（确认走 carousel 不出现"未找到记录"误报）、检查界面语言是否按浏览器语言自动切换、检查字段类型中文名。
14. 稳定运行（建议观察 ≥ 3 天无异常）后：更新本文件"当前线上状态"表 + 补丁状态表；按"回滚基线"一节的步骤，把新 tag 的 compose/Caddyfile/image-digests 快照写入 `/opt/nocodb/baselines/vNext/`，旧 baseline 目录保留不删（按时间戳/版本号区分，供更早版本回退用）。
15. 任一步失败：立即执行"回滚基线"一节的一键回滚命令退回上一个稳定 tag，**不在生产环境上尝试就地修复**（呼应铁律 2、3）。

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

## （建议）CI 与巡检

- GitHub Actions 工作流已写好：`.github/workflows/zh-build-smoke.yml`（本地分支 `ci/zh-build-smoke`，基于 tag `2026.06.1`）。push/PR 到 `zh-release/**`、`deploy/**`、`tooling/**` 时用 `docker build -f Dockerfile.zh` 完整构建，并串联 `selfcheck.sh` + `selfcheck-attachments.sh`（存在即跑），不推送任何 registry（未配置 secret）。
  - **未推送到 GitHub**：用于本次维护操作的 GitHub PAT 缺少 `workflow` scope，推送 `.github/workflows/*.yml` 被 remote 拒绝（`refusing to allow a Personal Access Token to create or update workflow ... without workflow scope`）。commit 已导出为 patch：`/tmp/0001-ci-add-build-only-smoke-workflow-for-zh-release-depl.patch`。
  - **需要人工处理**：给 PAT 补上 `workflow` scope 后，`git push origin ci/zh-build-smoke`（分支已在本地 `nocodb-src` 检出里），或者直接在 GitHub 网页端把 `archive`/该 patch 内容手工建一个 PR。
  - 后续如果要推 GHCR 供服务器 `docker pull`（替代当前"服务器就地构建"），需要额外加 registry secret，视需要再做。
- 补丁清单 A 巡检命令（见上）建议定期跑，合并的 PR 从清单移除，让 fork 逐步瘦身到只剩补丁清单 B（3 个部署配置 commit）+ 补丁清单 C（Crowdin 合并前）。可以配 `ci/zh-build-smoke` 里加一个 `schedule` cron job 跑巡检 + 发通知（未实现，属于可选增强的可选增强）。
