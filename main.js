// ============================================================
//  霓虹协议 · 桌面版主进程（Electron）
//  作用：创建游戏窗口，加载同目录下的 index.html
//  运行：npm start（开发调试） / npm run dist（打包安装程序）
// ============================================================
const { app, BrowserWindow } = require('electron');
const path = require('path');

// 创建游戏窗口
function createWindow() {
  const win = new BrowserWindow({
    width: 1280,
    height: 720,
    title: '霓虹协议 · Neon Protocol',
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

// 应用就绪后创建窗口
app.whenReady().then(() => {
  createWindow();
  // macOS 上点击 Dock 图标时若无窗口则重新创建
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

// 所有窗口关闭后退出（macOS 除外，macOS 习惯常驻 Dock）
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});