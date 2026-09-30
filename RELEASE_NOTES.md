## 更新内容

### 中文

#### 优化与体验

- 系统功耗优先读取 SMC PSTR，不再被固件每分钟才更新的 SystemLoad 拖住。
- 电源设置可自选功耗刷新间隔（1 / 2 / 5 / 10 秒）。
- 面板收起且关闭数据统计时，后台只采集状态栏实际要用的模块。
- 收紧状态栏图标左右留白。

### English

#### Improvements

- System power now prefers the SMC PSTR reading over the firmware SystemLoad value, which only publishes once a minute.
- Power refresh interval can be set to 1, 2, 5, or 10 seconds.
- With the panel closed and statistics off, background sampling keeps only the modules the menu bar actually shows.
- Tightened the menu bar icon's horizontal padding.

