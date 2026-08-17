// ============================================================
//  霓虹协议 · 桌面版主进程（Electron）
//  作用：创建游戏窗口，加载同目录下的 index.html，并支持自动更新
//  运行：npm start（开发调试） / npm run dist（打包发布）
// ============================================================
const { app, BrowserWindow, dialog } = require('electron');
const path = require('path');
const { autoUpdater } = require('electron-updater');

// 创建游戏窗口
function createWindow() {
  const win = new BrowserWindow({
    width: 1280,
    height: 720,
    title: '霓虹协议 · Neon Protocol',
    icon: path.join(__dirname, 'build', 'icon.ico'), // 游戏图标
    autoHideMenuBar: true,            // 隐藏菜单栏，更像游戏
    backgroundColor: '#05050d',       // 和游戏背景一致，启动不白屏
    webPreferences: {
      contextIsolation: true,         // 渲染进程与主进程隔离（更安全）
      nodeIntegration: false
    }
  });
  win.setMenuBarVisibility(false);
  // 加载游戏页面（本文件同目录下的 index.html）
  win.loadFile(path.join(__dirname, 'index.html'));
  return win;
}

// 自动更新（只对打包后的“安装版”生效；便携版不支持自更新，这是 Electron 的限制）
function setupAutoUpdater() {
  // 新版本下载完成 → 询问是否重启生效
  autoUpdater.on('update-downloaded', () => {
    dialog.showMessageBox({
      type: 'info',
      title: '发现新版本',
      message: '新版本已下载完成，重启后生效。',
      buttons: ['立即重启', '稍后']
    }).then(({ response }) => {
      if (response === 0) autoUpdater.quitAndInstall();
    });
  });
  // 更新出错不打断游戏，只打日志
  autoUpdater.on('error', (err) => {
    console.log('[自动更新] 出错：', err && err.message);
  });
  // 启动后静默检查更新（失败也不影响游戏）
  autoUpdater.checkForUpdatesAndNotify().catch(() => {});
}

// 应用就绪后创建窗口
app.whenReady().then(() => {
  createWindow();
  if (app.isPackaged) setupAutoUpdater(); // 只有正式打包版才检查更新
  // macOS 上点击 Dock 图标时若无窗口则重新创建
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

// 所有窗口关闭后退出（macOS 除外，macOS 习惯常驻 Dock）
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});