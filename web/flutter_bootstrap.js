{{flutter_js}}
{{flutter_build_config}}

// Everything comes from this site, nothing from Google's servers: the
// drawing engine (CanvasKit) included, and Flutter's own service worker,
// deprecated, is left out for ours (sw.js, made by tool/web_offline.dart).
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    document.getElementById('loading')?.remove();
  },
});

// Keeps the app's files on the phone, so that it opens fast and works with
// no network. Only in the published app: sw.js is not there in debug.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    fetch('sw.js', { method: 'HEAD' })
      .then(function (response) {
        if (response.ok) navigator.serviceWorker.register('sw.js');
      })
      .catch(function () {});
  });
}
