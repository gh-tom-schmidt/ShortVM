chrome.runtime.onInstalled.addListener(() => {
    chrome.contextMenus.create({
      id: "shortvm",
      title: "Install and Run VM",
      contexts: ["link"]
    });
  });
  
chrome.contextMenus.onClicked.addListener((info) => {
if (info.menuItemId === "shortvm" && info.linkUrl) {
    console.log("Creat VM from link:", info.linkUrl);
    const port = chrome.runtime.connectNative("com.shortvm.install");
    // port.postMessage({ text: info.linkUrl });
}
});


  