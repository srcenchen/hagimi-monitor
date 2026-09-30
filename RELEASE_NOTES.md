## 更新内容

### 中文

#### 优化与体验

- 系统功耗优先读取 SMC PSTR，不再被固件每分钟才更新的 SystemLoad 拖住。
- 电源设置可自选功耗刷新间隔（1 / 2 / 5 / 10 秒）。
- 面板收起且关闭数据统计时，后台只采集状态栏实际要用的模块。
- 收紧状态栏图标左右留白。紧凑模式下的指标列宽改为贴合当前文字，不再为 100% / 888W 预留空白。

个人构建未使用苹果开发者证书。下载 zip 后解压，在终端执行 `xattr -cr HagimiMonitorDirect.app`，再打开。若系统仍拦截，对应用右键选「打开」。

### English

#### Improvements

- System power now prefers the SMC PSTR reading over the firmware SystemLoad value, which only publishes once a minute.
- Power refresh interval can be set to 1, 2, 5, or 10 seconds.
- With the panel closed and statistics off, background sampling keeps only the modules the menu bar actually shows.
- Tightened the menu bar icon's horizontal padding.

