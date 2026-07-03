# NocoDB 中文翻译 Crowdin 提交清单

来源：release tag 2026.06.1。下列译文已随自建镜像 `nocodb-zh:2026.06.1-zh1` 生效；同时建议提交到官方 Crowdin（zh-Hans / zh-Hant），源串为 en.json。

## A. 字段类型（datatype.*，飞书风格）

| key | en | zh-Hans | zh-Hant |
|---|---|---|---|
| datatype.ID | ID | ID | ID |
| datatype.ForeignKey | Foreign Key | 外键 | 外鍵 |
| datatype.SingleLineText | Single Line Text | 文本 | 文字 |
| datatype.LongText | Long Text | 多行文本 | 多行文字 |
| datatype.Attachment | Attachment | 附件 | 附件 |
| datatype.Checkbox | Checkbox | 复选框 | 勾選框 |
| datatype.MultiSelect | Multi Select | 多选 | 多選 |
| datatype.SingleSelect | Single Select | 单选 | 單選 |
| datatype.Collaborator | Collaborator | 人员 | 人員 |
| datatype.Date | Date | 日期 | 日期 |
| datatype.Year | Year | 年 | 年 |
| datatype.Time | Time | 时间 | 時間 |
| datatype.PhoneNumber | Phone Number | 电话号码 | 電話號碼 |
| datatype.Email | Email | 电子邮件 | 電子郵件 |
| datatype.URL | URL | 超链接 | 超連結 |
| datatype.Number | Number | 数字 | 數字 |
| datatype.Decimal | Decimal | 小数 | 小數 |
| datatype.Currency | Currency | 货币 | 貨幣 |
| datatype.Percent | Percent | 百分比 | 百分比 |
| datatype.Duration | Duration | 时长 | 時長 |
| datatype.GeoData | GeoData | 地理位置 | 地理位置 |
| datatype.Rating | Rating | 评分 | 評分 |
| datatype.Formula | Formula | 公式 | 公式 |
| datatype.Rollup | Rollup | 汇总 | 匯總 |
| datatype.Count | Count | 计数 | 計數 |
| datatype.Lookup | Lookup | 查找引用 | 查找引用 |
| datatype.DateTime | Date Time | 日期时间 | 日期時間 |
| datatype.CreatedTime | Create Time | 创建时间 | 建立時間 |
| datatype.LastModifiedTime | Last Modified Time | 最后更新时间 | 最後更新時間 |
| datatype.AutoNumber | Auto Number | 自动编号 | 自動編號 |
| datatype.Barcode | Barcode | 条形码 | 條碼 |
| datatype.Button | Button | 按钮 | 按鈕 |
| datatype.Password | Password | 密码 | 密碼 |
| datatype.LinkToAnotherRecord | Link to Another Record | 关联 | 關聯 |
| datatype.Links | Links | 关联 | 關聯 |
| datatype.Order | Order | 排序 | 排序 |
| datatype.RichText | Rich Text | 富文本 | 富文字 |
| datatype.SmartText | Smart Text | 智能文本 | 智慧文字 |
| datatype.Colour | Colour | 颜色 | 顏色 |
| datatype.Geometry | Geometry | 几何 | 幾何 |
| datatype.JSON | JSON | JSON | JSON |
| datatype.SpecificDBType | Specific DB Type | 指定数据库类型 | 指定資料庫類型 |
| datatype.QrCode | QR Code | 二维码 | 二維碼 |
| datatype.User | User | 人员 | 人員 |
| datatype.CreatedBy | Created By | 创建人 | 建立人 |
| datatype.LastModifiedBy | Last Modified By | 修改人 | 修改人 |
| datatype.Deleted | Deleted | 已删除 | 已刪除 |
| datatype.Meta | Row Meta | 行元数据 | 列元資料 |
| datatype.UUID | UUID | UUID | UUID |
| datatype.AIButton | AI Button | AI 按钮 | AI 按鈕 |
| datatype.AIPrompt | AI Text | AI 文本 | AI 文字 |
| datatype.relationProperties | {'noAction': 'No Action', 'cascade': 'Cascade', 'restrict': 'Restrict', 'setNull': 'Set NULL', 'setDefault': 'Set Default'} | {'noAction': '无操作', 'cascade': '级联', 'restrict': '严格', 'setNull': '设为空（NULL）', 'setDefault': '设为默认值（Default）'} | {'noAction': '沒有任何行動', 'cascade': '級聯', 'restrict': '嚴格', 'setNull': '設置 null', 'setDefault': '設為預設'} |

## B. 散落漏译（86 条）

| key | en | zh-Hans | zh-Hant |
|---|---|---|---|
| upgrade.UpgradeToInviteMoreSubtitle | The {activePlan} plan allows up to {editors} editors & {commenters} commenters per workspace. Upgrade to the {plan} plan for unlimited users. | {activePlan} 套餐每个工作区最多支持 {editors} 名编辑者和 {commenters} 名评论者。升级到 {plan} 套餐可享无限用户。 | {activePlan} 方案每個工作區最多支援 {editors} 名編輯者與 {commenters} 名評論者。升級到 {plan} 方案可享無限使用者。 |
| upgrade.updateToAddRecordFormViewSubtitle | You've reached the limit for number of records on your {activePlan} plan. Upgrade to increase your record limit. | 您已达到 {activePlan} 套餐的记录数量上限。升级以提升记录上限。 | 您已達到 {activePlan} 方案的記錄數量上限。升級以提升記錄上限。 |
| upgrade.planLimitReached | Limit reached: Upgrade Plan | 已达上限：升级套餐 | 已達上限：升級方案 |
| upgrade.upgradeToAccessWsAuditSubtitle | Upgrade to the {plan} plan to enable workspace audit logs and efficiently monitor key activities. | 升级到 {plan} 套餐以启用工作区审计日志，高效监控关键活动。 | 升級到 {plan} 方案以啟用工作區稽核日誌，高效監控關鍵活動。 |
| upgrade.upgradeToAddExternalSource | Upgrade to connect more external sources | 升级以连接更多外部数据源 | 升級以連接更多外部資料來源 |
| upgrade.upgradeToAddExternalSourceSubtitle | Your current {activePlan} plan supports only {limit} external source. Upgrade to the {plan} plan to connect multiple external sources. | 您当前的 {activePlan} 套餐仅支持 {limit} 个外部数据源。升级到 {plan} 套餐以连接多个外部数据源。 | 您目前的 {activePlan} 方案僅支援 {limit} 個外部資料來源。升級到 {plan} 方案以連接多個外部資料來源。 |
| upgrade.upgradeToDuplicateTableToOtherWs | Upgrade your plan to duplicate tables across different workspaces. | 升级套餐以在不同工作区之间复制数据表。 | 升級方案以在不同工作區之間複製資料表。 |
| upgrade.upgradeToDuplicateTableToOtherBase | Upgrade your plan to duplicate tables across different bases. | 升级套餐以在不同 Base 之间复制数据表。 | 升級方案以在不同 Base 之間複製資料表。 |
| upgrade.upgradeToUseCalendarRange | Upgrade to visualize records in a calendar range | 升级以在日历区间中可视化记录 | 升級以在日曆區間中視覺化記錄 |
| upgrade.upgradeToUseCalendarRangeSubtitle | Upgrade to the {plan} plan to visualize records in a calendar range. | 升级到 {plan} 套餐以在日历区间中可视化记录。 | 升級到 {plan} 方案以在日曆區間中視覺化記錄。 |
| upgrade.upgradeToUseAiTextField | Upgrade to use AI Text fields | 升级以使用 AI 文本字段 | 升級以使用 AI 文字欄位 |
| upgrade.upgradeToUseAiTextFieldSubtitle | Upgrade to the {plan} plan to use AI Text fields to generate text based on your prompt. | 升级到 {plan} 套餐，使用 AI 文本字段根据提示词生成文本。 | 升級到 {plan} 方案，使用 AI 文字欄位根據提示詞產生文字。 |
| upgrade.upgradeToUseAiButtonField | Upgrade to use AI Button fields | 升级以使用 AI 按钮字段 | 升級以使用 AI 按鈕欄位 |
| upgrade.upgradeToUseAiButtonFieldSubtitle | Upgrade to the {plan} plan to let AI Button use record data with NocoAI to fill multiple fields automatically. | 升级到 {plan} 套餐，让 AI 按钮借助 NocoAI 使用记录数据自动填充多个字段。 | 升級到 {plan} 方案，讓 AI 按鈕借助 NocoAI 使用記錄資料自動填入多個欄位。 |
| general.addRollupField | Add {count} rollup field | 添加 {count} 个汇总字段 | 新增 {count} 個匯總欄位 |
| general.addRollupFieldPlural | Add {count} rollup fields | 添加 {count} 个汇总字段 | 新增 {count} 個匯總欄位 |
| general.escape | Escape | 退出 | 退出 |
| general.selected | selected | 已选择 | 已選擇 |
| title.helpAndSupportSubtitle | Visit our Support Center for detailed guides, customer service contact options, and a community forum for additional help. | 访问我们的支持中心，获取详细指南、客服联系方式以及社区论坛的更多帮助。 | 造訪我們的支援中心，取得詳細指南、客服聯絡方式以及社群論壇的更多協助。 |
| title.upgradeToPlan | Upgrade to {plan} plan | 升级到 {plan} 套餐 | 升級到 {plan} 方案 |
| title.confirmLeaveWorkspaceTitle | Are you sure you want to leave this workspace? | 确定要离开此工作区吗？ | 確定要離開此工作區嗎？ |
| title.confirmLeaveWorkspaceSubtile | If you leave this workspace, you will lose access to all the bases and data within this workspace. You'll need an invitation to rejoin. | 若离开此工作区，您将失去对该工作区内所有 Base 和数据的访问权限。重新加入需要邀请。 | 若離開此工作區，您將失去對該工作區內所有 Base 與資料的存取權限。重新加入需要邀請。 |
| title.confirmRemoveMemberFromWorkspaceTitle | Are you sure you want to remove member from workspace? | 确定要将该成员从工作区移除吗？ | 確定要將該成員從工作區移除嗎？ |
| title.confirmRemoveMemberFromWorkspaceSubtitle | If you remove, they will lose access to all bases and data within this workspace. They'll need an invitation to rejoin. | 移除后，该成员将失去对此工作区内所有 Base 和数据的访问权限。重新加入需要邀请。 | 移除後，該成員將失去對此工作區內所有 Base 與資料的存取權限。重新加入需要邀請。 |
| labels.docHistory.currentVersionPrefix | Current version ·  | 当前版本 ·  | 目前版本 ·  |
| labels.docHistory.listAction.restoredVerb | · restored | · 已恢复 | · 已還原 |
| labels.docHistory.listAction.savedVerb | · saved | · 已保存 | · 已儲存 |
| labels.docHistory.listAction.editedVerb | · edited | · 已编辑 | · 已編輯 |
| labels.editNFieldPermissions | Edit {count} field permissions | 编辑 {count} 个字段权限 | 編輯 {count} 個欄位權限 |
| labels.hideNFields | Hide {count} fields | 隐藏 {count} 个字段 | 隱藏 {count} 個欄位 |
| labels.deleteNFields | Delete {count} fields | 删除 {count} 个字段 | 刪除 {count} 個欄位 |
| labels.nFieldsSelected | {count} fields selected | 已选择 {count} 个字段 | 已選擇 {count} 個欄位 |
| labels.ungrouped | Ungrouped | 未分组 | 未分組 |
| labels.docAiSummarize | Summarize | 总结 | 摘要 |
| labels.alignLeft | Align left | 左对齐 | 靠左對齊 |
| labels.alignCenter | Align center | 居中对齐 | 置中對齊 |
| labels.alignTop | Align top | 顶部对齐 | 靠上對齊 |
| labels.alignBottom | Align bottom | 底部对齐 | 靠下對齊 |
| labels.duplicateTableMessage | You can only duplicate tables into bases where you have creator access or above. | 您只能将数据表复制到拥有创建者及以上权限的 Base 中。 | 您只能將資料表複製到擁有建立者及以上權限的 Base 中。 |
| labels.goLive | Go live | 上线 | 上線 |
| labels.toggleExperimentalFeature | Easily toggle all experimental features on / off | 一键开启 / 关闭所有实验性功能 | 一鍵開啟 / 關閉所有實驗性功能 |
| labels.selectAFormatType | - -Select a format type (optional)- - | - -选择格式类型（可选）- - | - -選擇格式類型（可選）- - |
| labels.body | Body | 正文 | 內文 |
| labels.alphabetize | Alphabetize | 按字母排序 | 按字母排序 |
| labels.firstRowAsHeaders | Use first record as header | 将首行记录作为表头 | 將首列記錄作為標題 |
| labels.flattenNested | Flatten nested | 展平嵌套 | 展平巢狀 |
| labels.nextRow | Next record | 下一条记录 | 下一筆記錄 |
| labels.prevRow | Prev record | 上一条记录 | 上一筆記錄 |
| labels.autoSuggested | Auto Suggested | 自动建议 | 自動建議 |
| labels.usePrompt | Use Prompt | 使用提示词 | 使用提示詞 |
| labels.showJsonPayload | Show JSON payload | 显示 JSON 负载 | 顯示 JSON 負載 |
| labels.viewAllPlanDetails | View all plan details | 查看全部套餐详情 | 檢視全部方案詳情 |
| labels.editorSeat | Editor seat | 编辑者席位 | 編輯者席位 |
| labels.editorSeats | Editor seats | 编辑者席位 | 編輯者席位 |
| labels.enterFullscreen | Enter fullscreen | 进入全屏 | 進入全螢幕 |
| labels.exitFullscreen | Exit fullscreen | 退出全屏 | 退出全螢幕 |
| labels.selectRole | Select Role | 选择角色 | 選擇角色 |
| labels.navigate | Navigate | 导航 | 導覽 |
| activity.removeMember | Remove member | 移除成员 | 移除成員 |
| activity.filterByTheseFields | Filter by these fields | 按这些字段筛选 | 依這些欄位篩選 |
| activity.groupByNFields | Group by {count} fields | 按 {count} 个字段分组 | 依 {count} 個欄位分組 |
| activity.dontGroupByThisField | Don't group by this field | 不按此字段分组 | 不依此欄位分組 |
| activity.deleteAllSelectedRecords | Delete all selected records | 删除所有已选记录 | 刪除所有已選記錄 |
| tooltip.releasingPreviousFullscreenLock | Releasing previous fullscreen lock... | 正在释放上一个全屏锁定… | 正在釋放上一個全螢幕鎖定… |
| tooltip.youCantHideARequiredField | You can't hide a required field. | 无法隐藏必填字段。 | 無法隱藏必填欄位。 |
| tooltip.youCantRemoveARequiredField | You can't remove a required field. | 无法移除必填字段。 | 無法移除必填欄位。 |
| tooltip.removeFromForm | Remove from form | 从表单中移除 | 從表單中移除 |
| tooltip.fieldCannotBeUsedAsDisplayValueField | {field} field cannot be used as display value field | {field} 字段不能用作显示值字段 | {field} 欄位不能用作顯示值欄位 |
| tooltip.thisFieldTypeDoesNotSupportSorting | This field type doesn't support sorting | 该字段类型不支持排序 | 該欄位類型不支援排序 |
| tooltip.thisFieldTypeDoesNotSupportFiltering | This field type doesn't support filtering | 该字段类型不支持筛选 | 該欄位類型不支援篩選 |
| tooltip.thisFieldTypeDoesNotSupportGrouping | This field type doesn't support grouping | 该字段类型不支持分组 | 該欄位類型不支援分組 |
| tooltip.filterByLimitExceeded | Filter by limit exceeded | 筛选条件数量已超出上限 | 篩選條件數量已超出上限 |
| tooltip.groupByLimitExceeded | Group by limit exceeded | 分组数量已超出上限 | 分組數量已超出上限 |
| tooltip.displayValueFieldExcluded | Display value field cannot be hidden or deleted | 显示值字段不能被隐藏或删除 | 顯示值欄位不能被隱藏或刪除 |
| tooltip.pasteOperationLimitedToMaxRows | Paste operation limited to {max} rows. Additional rows were truncated. | 粘贴操作最多 {max} 行，多余行已被截断。 | 貼上操作最多 {max} 列，多餘列已被截斷。 |
| msg.chat.toolInput | Input | 输入 | 輸入 |
| msg.webhookBodyMsg2 | body | 正文 | 內文 |
| msg.areYouSureDeleteNFields | Are you sure you want to delete the following {count} fields? | 确定要删除以下 {count} 个字段吗？ | 確定要刪除以下 {count} 個欄位嗎？ |
| msg.fieldsCannotBeDeletedSkipped | {count} field(s) skipped — system, primary, or display value fields cannot be deleted. | 已跳过 {count} 个字段——系统、主键或显示值字段不可删除。 | 已略過 {count} 個欄位——系統、主鍵或顯示值欄位不可刪除。 |
| msg.info.computedFieldEditWarning | Contents are read-only | 内容为只读 | 內容為唯讀 |
| msg.info.computedFieldDeleteWarning | Contents are read-only | 内容为只读 | 內容為唯讀 |
| msg.error.someFieldsCouldNotBeDeleted | Some fields could not be deleted: {fields} | 部分字段无法删除：{fields} | 部分欄位無法刪除：{fields} |
| msg.error.webhookBodyEmpty | Body cannot be empty for {method} requests — set a custom payload | {method} 请求的正文不能为空——请设置自定义负载 | {method} 請求的內文不能為空——請設定自訂負載 |
| msg.error.promptHasDeletedColumn | Prompt has deleted column(s): {columns} | 提示词中包含已删除的列：{columns} | 提示詞中包含已刪除的欄：{columns} |
| msg.error.errorOccuredWhileDroppingAttachments | Error occured while dropping attachments | 拖放附件时发生错误 | 拖放附件時發生錯誤 |
| msg.success.tableDuplicatedInOtherBase | Table has successfully duplicated in another base. Open the specified base to see it. | 数据表已成功复制到另一个 Base。打开对应 Base 即可查看。 | 資料表已成功複製到另一個 Base。開啟對應 Base 即可檢視。 |
