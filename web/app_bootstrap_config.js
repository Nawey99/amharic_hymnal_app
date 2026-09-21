window.SQL = window.SQL || {};
window.SQL.config = {
  locateFile: function (filename) {
    return filename.endsWith('.wasm') ? 'sql-wasm.wasm' : filename;
  },
};

if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('sqflite_sw.js').catch(function () {
      // The app remains usable without the optional local database worker.
    });
  });
}
