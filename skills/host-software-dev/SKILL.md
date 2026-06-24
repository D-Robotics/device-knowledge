---
name: host-software-dev
description: 当开发 RDK Studio 桌面客户端本体(Electron/React/Vite/Node.js/TypeScript 工程、打包、IPC、HMR 等前端与桌面工程问题)时使用,区别于板端 RDK 设备知识。
---

# RDK Studio 桌面端开发

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

面向 RDK Studio 桌面客户端本体的前端/桌面工程知识(非板端设备操作)。

## Host software ecosystem
- Desktop and frontend work usually spans browser runtimes, Electron main/preload/renderer processes, Node backends, Vite dev/build tooling, and TypeScript static analysis.
- Keep runtime boundaries explicit: browser/renderer code is not Node code; preload bridges should be narrow, typed, and reviewed as security boundaries.
- Use official framework documentation for contracts first, then local source, package versions, logs, and tests to resolve the project-specific behavior.

**Host software runtime boundaries**:
- First identify where code runs: browser, Electron main process, preload script, renderer, Node backend, build tool, or test runner.
- Do not use Node APIs from a browser/renderer path unless the app intentionally exposes a narrow preload bridge.
- Treat Vite dev server behavior, TypeScript typechecking, Electron packaging, and backend runtime behavior as separate failure surfaces.
- Prefer official framework docs for runtime contracts before changing bundler aliases, sandbox flags, or TypeScript module settings.

**Desktop/frontend debugging loop**:
- Reproduce the smallest failing path, then collect the exact console, terminal, and build error from the layer that failed.
- For Electron, check main-process logs, preload exposure, renderer console, and registered IPC handlers separately.
- For React/Vite, separate render bugs from dev-server/HMR bugs; Vite transforms TypeScript but does not replace `tsc --noEmit`.
- For packaging/signing, verify local build output first, then signing identity, certificate variables, entitlements, and notarization credentials.

**Electron IPC contract**:
1. Register `ipcMain.handle(channel, handler)` in the main process before any renderer calls `ipcRenderer.invoke(channel, ...)`.
2. Expose only a typed, minimal API through `contextBridge.exposeInMainWorld`; never expose raw `ipcRenderer` or unrestricted channel names.
3. Validate payloads on the main-process boundary and return serializable values only.
4. Keep channel names centralized so preload, renderer, and main process cannot drift silently.

**Frontend build contract**:
1. Run the narrow command that matches the failure: `tsc --noEmit` for types, `vite --host` or `npm run dev` for dev server, production build for bundling, and package build for Electron artifacts.
2. Confirm the active Node version, package manager lockfile, workspace root, and resolved package version before changing source.
3. Vite client env variables must use the project-defined public prefix, commonly `VITE_`; secrets stay in backend/main-process code.
4. Fix TypeScript errors at the declaration or call boundary; avoid hiding contract problems with unchecked casts.

## 常用命令

| 命令模式 | 说明 | 风险 | 适用范围 |
| --- | --- | --- | --- |
| `(npm\|pnpm\|yarn)\s+run\s+dev\|\bvite\b` | Run or inspect a Vite development server | safe | 通用 |
| `\btsc\b.*(--noEmit\|-p\s+[^\s]+)\|run\s+typecheck` | Run TypeScript compiler diagnostics | safe | 通用 |
| `electron-builder\|electron-builder\s+--(mac\|win\|linux\|publish)` | Build or sign Electron desktop artifacts | moderate | 通用 |

## 常见故障

- 匹配 `require is not defined|Cannot find module .+ in preload|process is not defined|module is not defined` → Preload/renderer sandbox mismatch. Keep Node-only code in the main process or preload, expose a narrow API through `contextBridge`, and verify the preload path is loaded by the BrowserWindow configuration. (<https://www.electronjs.org/docs/latest/tutorial/tutorial-preload>)
- 匹配 `No handler registered|Error invoking remote method|Unable to deserialize cloned data|An object could not be cloned` → IPC contract drift. Confirm `ipcMain.handle` is registered before renderer invoke, channel names match exactly, and payload/return values are structured-clone serializable. (<https://www.electronjs.org/docs/latest/tutorial/ipc>)
- 匹配 `\[vite\].*(failed to connect|hmr)|WebSocket connection.*(failed|closed)|hmr update.*failed` → Vite HMR WebSocket failure. Check dev-server host/port, reverse proxy or Electron renderer origin, `server.hmr` settings, and browser console network errors before changing React state code. (<https://vite.dev/guide/features.html#hot-module-replacement>)
- 匹配 `TS(2322|2307|2741|7006)|Type .+ is not assignable|Cannot find module .+ or its corresponding type declarations` → TypeScript contract failure. Run `tsc --noEmit -p <tsconfig>` at the package boundary, inspect the first real diagnostic, and fix declarations/import paths rather than relying on unchecked casts. (<https://www.typescriptlang.org/docs/handbook/compiler-options.html>)
- 匹配 `TS18003|No inputs were found in config file` → tsconfig 未匹配到任何输入文件(**配置错误,非类型错误**)。检查 `include`/`files` 路径与 glob、`rootDir`/工作区根是否能命中 `.ts` 源,而非去改类型声明或 import。 (<https://www.typescriptlang.org/tsconfig/#include>)
- 匹配 `CSC_LINK|No identity found|codesign.*(failed|exited)|The specified item could not be found in the keychain|notarization.*failed|Developer ID Application` → Packaging signing failure. Verify certificate/keychain access or CI signing variables, confirm unsigned packaging works first, then check electron-builder signing and notarization configuration for the target OS. (<https://www.electron.build/code-signing.html>)
- 匹配 `EADDRINUSE|listen EADDRINUSE|address already in use|port\s+\d+\s+is\s+already\s+in\s+use` → Dev-server/HTTP port is already held — usually a leftover process from a previous run, not a code bug. Find the holder (`lsof -nP -iTCP:<port> -sTCP:LISTEN` on macOS/Linux, `netstat -ano | findstr :<port>` on Windows), stop it, then restart; or start on a different port. Confirm the port is free before assuming the new server bound. (<https://nodejs.org/api/errors.html#common-system-errors>)
- 匹配 `ERR_MODULE_NOT_FOUND|Cannot find module .+ imported from|ERR_UNSUPPORTED_DIR_IMPORT|Did you mean to import .+\.js` → Runtime ESM resolution failure (distinct from a TypeScript compile error). In "type":"module" / NodeNext projects, relative imports need an explicit ".js" extension even from .ts sources, directory imports need an explicit index file, and the path/case must match on disk. Fix the import specifier rather than switching module systems or adding casts. (<https://nodejs.org/api/esm.html#mandatory-file-extensions>)

## 官方资料

- [Electron Process Model](https://www.electronjs.org/docs/latest/tutorial/process-model)
- [Electron Preload Scripts](https://www.electronjs.org/docs/latest/tutorial/tutorial-preload)
- [Electron contextBridge API](https://www.electronjs.org/docs/latest/api/context-bridge)
- [Electron Inter-Process Communication](https://www.electronjs.org/docs/latest/tutorial/ipc)
- [electron-builder Code Signing](https://www.electron.build/code-signing.html)
- [React Learn](https://react.dev/learn)
- [React Hooks Reference](https://react.dev/reference/react/hooks)
- [React DOM createRoot](https://react.dev/reference/react-dom/client/createRoot)
- [Vite Getting Started](https://vite.dev/guide/)
- [Vite Hot Module Replacement](https://vite.dev/guide/features.html#hot-module-replacement)
- [Vite TypeScript Support](https://vite.dev/guide/features.html#typescript)
- [Vite Env Variables and Modes](https://vite.dev/guide/env-and-mode)
- [TypeScript Compiler Options](https://www.typescriptlang.org/docs/handbook/compiler-options.html)
- [TSConfig Reference](https://www.typescriptlang.org/tsconfig/)
- [TypeScript Everyday Types](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html)
- [Node.js HTTP API](https://nodejs.org/api/http.html)
- [Node.js Streams API](https://nodejs.org/api/stream.html)
- [Node.js child_process API](https://nodejs.org/api/child_process.html)
- [Node.js Test Runner](https://nodejs.org/api/test.html)
