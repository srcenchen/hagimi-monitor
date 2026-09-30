## 更新内容

### 中文

#### 优化与体验

- 系统功耗优先读取 SMC PSTR，不再被固件每分钟才更新的 SystemLoad 拖住。
- 电源设置可自选功耗刷新间隔（1 / 2 / 5 / 10 秒）。
- 面板收起且关闭数据统计时，后台只采集状态栏实际要用的模块。
- 状态栏左右只保留系统自带的边距，不再在图标外侧另加一圈空白。
- 菜单栏指标列宽至少按三位数预留，3%、23%、100% 切换时不再把旁边的图标挤动。

个人构建未使用苹果开发者证书。下载 zip 后解压，在终端执行 `xattr -cr HagimiMonitorDirect.app`，再打开。若系统仍拦截，对应用右键选「打开」。

### English

#### Improvements

- System power now prefers the SMC PSTR reading over the firmware SystemLoad value, which only publishes once a minute.
- Power refresh interval can be set to 1, 2, 5, or 10 seconds.
- With the panel closed and statistics off, background sampling keeps only the modules the menu bar actually shows.
- Menu bar items now keep only the system status-item inset, without an extra margin on either side.
- Menu bar metric columns reserve at least three digits, so 3%, 23%, and 100% no longer shift neighboring icons.

