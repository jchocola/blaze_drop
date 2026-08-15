/* BlazeDrop — guest web client logic.
 *
 * Talks to the host hub:
 *   GET  /api/ping?client=<name>  keep the connected list live
 *   GET  /files                   list shareable assets
 *   POST /upload                  multipart upload (one file per request)
 *   GET  /download/{id}           download an asset
 *
 * Files are uploaded sequentially so each row in TRANSFER_LOG gets its own
 * live progress bar and speed readout.
 */
(function () {
  'use strict';

  const state = { files: [], uploading: false };

  /* --- Guest identity (stable codename, persisted in localStorage) ----- */
  const storageKey = 'blazedrop_guest';
  let guest = null;
  try {
    guest = JSON.parse(localStorage.getItem(storageKey) || 'null');
  } catch (_) {
    guest = null;
  }
  if (!guest || !guest.id) {
    const rand = (n) => Math.random().toString(16).slice(2, 2 + n).toUpperCase();
    guest = { id: 'node-' + rand(8), name: 'NODE-' + rand(4) };
    try {
      localStorage.setItem(storageKey, JSON.stringify(guest));
    } catch (_) {
      /* storage unavailable — session-only identity */
    }
  }

  const $ = (sel) => document.querySelector(sel);
  const els = {
    dropZone: $('#dropZone'),
    fileInput: $('#fileInput'),
    chooseBtn: $('#chooseBtn'),
    uploadBtn: $('#uploadBtn'),
    selectedCount: $('#selectedCount'),
    log: $('#transferLog'),
    downloadList: $('#downloadList'),
    status: $('#statusLine'),
    connBadge: $('#connBadge'),
  };

  /* --- Liveness ping ----------------------------------------------------- */
  async function ping() {
    try {
      const r = await fetch(
        '/api/ping?client=' + encodeURIComponent(guest.name),
        { cache: 'no-store' },
      );
      setConn(r.ok);
    } catch (_) {
      setConn(false);
    }
  }
  setInterval(ping, 5000);
  ping();

  function setConn(ok) {
    els.connBadge.textContent = ok
      ? '● SERVER CONNECTION ESTABLISHED'
      : '○ CONNECTION LOST';
    els.connBadge.classList.toggle('ok', ok);
    els.connBadge.classList.toggle('lost', !ok);
  }

  /* --- Download area ----------------------------------------------------- */
  async function loadFiles() {
    try {
      const r = await fetch('/files', { cache: 'no-store' });
      const data = await r.json();
      renderFiles(data.files || []);
    } catch (_) {
      /* host offline — leave the list as-is */
    }
  }

  function renderFiles(files) {
    els.downloadList.innerHTML = '';
    if (!files.length) {
      const empty = document.createElement('div');
      empty.className = 'empty';
      empty.textContent = 'NO ASSETS ON HOST';
      els.downloadList.appendChild(empty);
      return;
    }
    files.forEach((f) => {
      const row = document.createElement('div');
      row.className = 'file-row';
      const link = document.createElement('a');
      link.className = 'get-btn';
      link.href = '/download/' + encodeURIComponent(f.id);
      link.setAttribute('download', '');
      link.textContent = 'GET';

      const ico = document.createElement('span');
      ico.className = 'file-ico';
      ico.textContent = '📄';

      const meta = document.createElement('span');
      meta.className = 'file-meta';
      const name = document.createElement('span');
      name.className = 'file-name';
      name.textContent = f.name;
      const sub = document.createElement('span');
      sub.className = 'file-sub';
      sub.textContent = fmt(f.size) + ' • ' + (f.mimeType || 'FILE');
      meta.appendChild(name);
      meta.appendChild(sub);

      row.appendChild(ico);
      row.appendChild(meta);
      row.appendChild(link);
      els.downloadList.appendChild(row);
    });
  }

  /* --- Upload ------------------------------------------------------------ */
  function addFiles(fileList) {
    Array.prototype.forEach.call(fileList, (file) => {
      const dup = state.files.some(
        (f) => f.name === file.name && f.size === file.size,
      );
      if (!dup) {
        state.files.push(file);
      }
    });
    renderSelected();
  }

  function renderSelected() {
    els.selectedCount.textContent = state.files.length + ' FILE(S) STAGED';
    els.uploadBtn.disabled = state.files.length === 0 || state.uploading;
  }

  async function uploadAll() {
    if (state.uploading || state.files.length === 0) {
      return;
    }
    state.uploading = true;
    els.uploadBtn.disabled = true;
    setStatus('> UPLOAD SEQUENCE INITIATED…');

    const queue = state.files.slice();
    state.files = [];
    renderSelected();

    for (const file of queue) {
      await uploadOne(file);
    }

    state.uploading = false;
    els.uploadBtn.disabled = state.files.length === 0;
    setStatus('> SYSTEM STANDBY…');
    loadFiles();
  }

  function uploadOne(file) {
    return new Promise((resolve) => {
      const row = addLogRow(file);
      const form = new FormData();
      form.append('file', file);

      const xhr = new XMLHttpRequest();
      const started = Date.now();
      let lastLoaded = 0;
      let lastTime = started;

      xhr.open('POST', '/upload');
      xhr.upload.onprogress = (e) => {
        if (!e.lengthComputable) {
          return;
        }
        const now = Date.now();
        const dt = (now - lastTime) / 1000;
        const speed = dt > 0 ? (e.loaded - lastLoaded) / dt : 0;
        lastTime = now;
        lastLoaded = e.loaded;
        updateRow(row, e.loaded, e.total, speed);
      };
      xhr.onload = () => {
        row.classList.add('done');
        row.querySelector('.pct').textContent = 'DONE';
        setStatus('> ' + file.name + ' // DONE');
        resolve();
      };
      xhr.onerror = () => {
        row.classList.add('failed');
        row.querySelector('.pct').textContent = 'FAILED';
        setStatus('> ' + file.name + ' // FAILED');
        resolve();
      };
      xhr.send(form);
    });
  }

  function addLogRow(file) {
    const row = document.createElement('div');
    row.className = 'log-row';
    row.innerHTML =
      '<div class="log-head">' +
      '<span class="log-name"></span>' +
      '<span class="pct">0%</span>' +
      '</div>' +
      '<div class="log-sub">' +
      '<span class="log-size"></span>' +
      '<span class="log-speed"></span>' +
      '</div>' +
      '<div class="track"><div class="bar"></div></div>';
    row.querySelector('.log-name').textContent = file.name;
    row.querySelector('.log-size').textContent = '0 B / ' + fmt(file.size);
    els.log.prepend(row);
    return row;
  }

  function updateRow(row, loaded, total, speed) {
    const pct = total ? Math.round((loaded / total) * 100) : 0;
    row.querySelector('.pct').textContent = pct + '%';
    row.querySelector('.log-size').textContent =
      fmt(loaded) + ' / ' + fmt(total);
    row.querySelector('.log-speed').textContent = fmt(speed) + '/s';
    row.querySelector('.bar').style.width = pct + '%';
  }

  function setStatus(text) {
    els.status.textContent = text;
  }

  function fmt(bytes) {
    if (!bytes || bytes < 0) {
      return '0 B';
    }
    if (bytes < 1024) {
      return bytes + ' B';
    }
    const units = ['KB', 'MB', 'GB', 'TB'];
    let v = bytes;
    let u = -1;
    while (v >= 1024 && u < units.length - 1) {
      v /= 1024;
      u++;
    }
    return (v >= 100 ? v.toFixed(0) : v.toFixed(1)) + ' ' + units[u];
  }

  /* --- Wire up the UI ---------------------------------------------------- */
  els.chooseBtn.addEventListener('click', () => els.fileInput.click());
  els.dropZone.addEventListener('click', () => els.fileInput.click());
  els.fileInput.addEventListener('change', (e) => {
    addFiles(e.target.files);
    e.target.value = '';
  });
  els.uploadBtn.addEventListener('click', uploadAll);

  ['dragover', 'dragenter'].forEach((ev) =>
    els.dropZone.addEventListener(ev, (e) => {
      e.preventDefault();
      els.dropZone.classList.add('over');
    }),
  );
  ['dragleave', 'drop'].forEach((ev) =>
    els.dropZone.addEventListener(ev, (e) => {
      e.preventDefault();
      els.dropZone.classList.remove('over');
    }),
  );
  els.dropZone.addEventListener('drop', (e) => {
    if (e.dataTransfer && e.dataTransfer.files) {
      addFiles(e.dataTransfer.files);
    }
  });

  setStatus('> SYSTEM STANDBY…');
  loadFiles();
})();
