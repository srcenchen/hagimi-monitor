## 更新内容

同步上游 v1.7.0，并新增全局刷新频率控制。个人构建未使用苹果开发者证书：下载 zip 后解压，在终端执行 `xattr -cr HagimiMonitorDirect.app` 再打开；若系统仍拦截，对应用右键选「打开」。

### 中文

#### 新功能

- 新增独立「刷新频率」设置页：一个全局档位统一控制所有监控模块的后台采样间隔，档位为 1 / 2 / 3 / 6 / 10 / 15 秒。
- 移除原先只作用于系统功耗的功耗刷新间隔设置，改由全局刷新频率统一接管。

#### 优化与体验

- 采样心跳与全局频率对齐，低频档位下不再每秒空转唤醒，后台更省电。
- 统计的样本间隔上限随全局频率自适应，低频档位下不再把正常采样误判为中断而漏记。
- 同步上游 v1.7.0：系统功耗优先采用实时采样，部分机型不再滞后 30–60 秒；修复直连版供电状态在「交流供电」与「维持」之间横跳、直供时误报电池放电的问题。
- 同步上游 v1.7.0：数据统计口径与体验全面升级，报表支持上下文跳转与多维度趋势，面板动画改由系统原生图层驱动。

### English

#### New Features

- Added a dedicated "Refresh Rate" settings page: a single global level controls the background sampling interval for every monitored module, with levels of 1 / 2 / 3 / 6 / 10 / 15 seconds.
- Removed the old power-only refresh interval setting; the global refresh rate now covers it.

#### Improvements

- The sampling heartbeat now aligns with the global rate, so low-frequency levels no longer wake up every second and use less power in the background.
- The statistics sample-gap threshold adapts to the global rate, so slow levels no longer misread normal samples as interruptions and drop seconds.
- Synced upstream v1.7.0: system power now uses real-time sampling, so some Macs no longer lag by 30–60 seconds; fixed the direct edition flip-flopping between "AC power" and "maintaining" and falsely reporting battery discharge while on direct power.
- Synced upstream v1.7.0: statistics have a consistent experience and unified units, reports support context jump and multi-dimension trends, and panel animation is driven by the system's native layer motion.
