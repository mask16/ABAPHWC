const vscode = require("vscode");
const path = require("path");

const VIEW_TYPE = "local.abapHtmlPreview";

function decodeListing(bytes) {
  const head = Buffer.from(bytes.slice(0, 800)).toString("latin1");
  const meta = /charset\s*=\s*["']?\s*([A-Za-z0-9_\-]+)/i.exec(head);
  const declared = meta ? meta[1].toLowerCase() : "";
  const useEucKr =
    declared === "euc-kr" ||
    declared === "cp949" ||
    declared === "ks_c_5601-1987" ||
    declared === "windows-949" ||
    declared === "";

  if (!useEucKr) {
    return new TextDecoder("utf-8").decode(bytes);
  }

  try {
    return new TextDecoder("euc-kr").decode(bytes);
  } catch (error) {
    return new TextDecoder("utf-8", { fatal: false }).decode(bytes);
  }
}

function toBrowserHtml(html) {
  const light = '<meta name="color-scheme" content="light">';
  const csp =
    '<meta http-equiv="Content-Security-Policy" content="default-src \'none\'; img-src data:; style-src \'unsafe-inline\'; script-src \'unsafe-inline\';">';
  const script = `<script>
(function () {
  const vscode = acquireVsCodeApi();
  document.addEventListener('click', function (event) {
    const link = event.target && event.target.closest ? event.target.closest('a') : null;
    if (!link) return;
    const href = link.getAttribute('href');
    if (!href || href.charAt(0) === '#' || /^[a-z]+:/i.test(href)) return;
    event.preventDefault();
    vscode.postMessage({ type: 'open', href: href });
  });
})();
</script>`;

  let page = html.replace(/charset\s*=\s*["']?EUC-KR["']?/gi, "charset=UTF-8");
  page = page.replace(/charset\s*=\s*["']?ks_c_5601-1987["']?/gi, "charset=UTF-8");
  if (/<head[^>]*>/i.test(page)) {
    page = page.replace(/<head[^>]*>/i, function (match) {
      return match + csp + light;
    });
  } else {
    page = csp + light + page;
  }
  if (/<\/body>/i.test(page)) {
    page = page.replace(/<\/body>/i, script + "</body>");
  } else {
    page += script;
  }
  return page;
}

function workspaceRoot() {
  const folders = vscode.workspace.workspaceFolders;
  if (folders && folders.length > 0) {
    return folders[0].uri.fsPath;
  }
  return undefined;
}

function isInsideRoot(root, target) {
  const relative = path.relative(root, target);
  return relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative));
}

async function render(panel, uri) {
  const bytes = await vscode.workspace.fs.readFile(uri);
  panel.webview.options = { enableScripts: true };
  panel.webview.html = toBrowserHtml(decodeListing(bytes));
}

function activate(context) {
  const provider = {
    openCustomDocument(uri) {
      return { uri, dispose() {} };
    },
    async resolveCustomEditor(document, panel) {
      const update = () => render(panel, document.uri);
      await update();

      const messages = panel.webview.onDidReceiveMessage(async (message) => {
        if (!message || message.type !== "open" || !message.href) return;
        const root = workspaceRoot();
        if (!root) return;
        const clean = String(message.href).split("#")[0].split("?")[0];
        const target = path.resolve(path.dirname(document.uri.fsPath), clean);
        if (!isInsideRoot(root, target)) return;
        await vscode.commands.executeCommand("vscode.open", vscode.Uri.file(target));
      });

      const watcher = vscode.workspace.createFileSystemWatcher("**/*.{html,htm}");
      const changed = watcher.onDidChange((changedUri) => {
        if (changedUri.toString() === document.uri.toString()) {
          update();
        }
      });

      panel.onDidDispose(() => {
        messages.dispose();
        changed.dispose();
        watcher.dispose();
      });
    },
  };

  context.subscriptions.push(
    vscode.window.registerCustomEditorProvider(VIEW_TYPE, provider, {
      webviewOptions: { retainContextWhenHidden: true },
      supportsMultipleEditorsPerDocument: false,
    })
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
