{{flutter_js}}
{{flutter_build_config}}

const pocketoolsServiceWorkerVersion = "pocketools-pwa-v3";

if ("serviceWorker" in navigator) {
  navigator.serviceWorker
    .register(
      `pocketools_service_worker.js?v=${pocketoolsServiceWorkerVersion}`,
      {scope: "./", updateViaCache: "none"},
    )
    .catch(() => {
      // Offline support is optional; app startup must remain independent.
    });
}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
