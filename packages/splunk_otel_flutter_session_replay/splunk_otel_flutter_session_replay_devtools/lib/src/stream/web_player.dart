/*
 * Copyright 2026 Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/// The wireframe player, as a single self-contained page.
///
/// Held as a string rather than a Flutter asset so that the server can serve it
/// with no configuration in the consuming application: an asset would have to
/// be declared in every `pubspec.yaml` that wanted to stream, which is a poor
/// trade for a page this size.
///
/// It has no external references of any kind, so it loads over a socket that
/// reaches nothing but the device.
const String webPlayerHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Session replay wireframes</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; height: 100vh; display: flex; flex-direction: column;
    background: #14181b; color: #e6edf3;
    font: 13px/1.5 ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  }
  header, footer {
    display: flex; align-items: center; gap: 12px; padding: 8px 12px;
    background: #1b2126; border-color: #2b343b; border-style: solid; border-width: 0;
    flex: 0 0 auto;
  }
  header { border-bottom-width: 1px; }
  footer { border-top-width: 1px; }
  h1 { font-size: 13px; font-weight: 600; margin: 0; }
  main { flex: 1 1 auto; display: flex; min-height: 0; }
  #stage {
    flex: 1 1 auto; display: flex; align-items: center; justify-content: center;
    padding: 16px; min-width: 0; overflow: hidden;
  }
  canvas { background: #000; box-shadow: 0 0 0 1px #2b343b; }
  #inspector {
    flex: 0 0 320px; display: flex; flex-direction: column;
    border-left: 1px solid #2b343b; min-height: 0;
  }
  #tree { flex: 1 1 auto; overflow: auto; padding: 4px 0; }
  #details {
    flex: 0 0 auto; max-height: 40%; overflow: auto;
    border-top: 1px solid #2b343b; padding: 8px 12px;
  }
  .row {
    display: flex; align-items: center; gap: 6px; padding: 1px 8px;
    cursor: pointer; white-space: nowrap; font-size: 12px;
  }
  .row:hover { background: #232c33; }
  .row.selected { background: #1f6feb44; }
  .twisty { width: 12px; color: #8b949e; text-align: center; flex: 0 0 auto; }
  .type { overflow: hidden; text-overflow: ellipsis; }
  .meta { color: #8b949e; font-size: 11px; margin-left: auto; flex: 0 0 auto; }
  .lock { color: #ff6b6b; }
  button, select {
    background: #232c33; color: #e6edf3; border: 1px solid #2b343b;
    border-radius: 4px; padding: 4px 10px; font: inherit; cursor: pointer;
  }
  button:hover, select:hover { background: #2b343b; }
  button.active { background: #1f6feb; border-color: #1f6feb; }
  button:disabled { opacity: .5; cursor: default; }
  #scrub { flex: 1 1 auto; accent-color: #1f6feb; }
  .dot { width: 8px; height: 8px; border-radius: 50%; background: #f85149; flex: 0 0 auto; }
  .dot.on { background: #3fb950; }
  .spacer { flex: 1 1 auto; }
  dl { margin: 0; display: grid; grid-template-columns: auto 1fr; gap: 2px 10px; font-size: 12px; }
  dt { color: #8b949e; }
  dd { margin: 0; font-variant-numeric: tabular-nums; }
  .empty { color: #8b949e; padding: 12px; font-size: 12px; }
</style>
</head>
<body>
<header>
  <span class="dot" id="status-dot"></span>
  <h1>Session replay wireframes</h1>
  <span class="meta" id="status-text">connecting</span>
  <span class="spacer"></span>
  <select id="mode">
    <option value="fills">fills</option>
    <option value="bounds">bounds</option>
    <option value="both">both</option>
  </select>
</header>

<main>
  <section id="stage"><canvas id="canvas" width="1" height="1"></canvas></section>
  <aside id="inspector">
    <div id="tree"><p class="empty">Waiting for a frame.</p></div>
    <div id="details"><p class="empty">No node selected.</p></div>
  </aside>
</main>

<footer>
  <button id="live" class="active">live</button>
  <input type="range" id="scrub" min="0" max="0" value="0" disabled>
  <span class="meta" id="frame-info">no frames</span>
</footer>

<script>
(function () {
  "use strict";

  var MAX_FRAMES = 600;

  var frames = [];
  var cursor = -1;
  var live = true;
  var selectedId = null;
  var collapsed = Object.create(null);
  var mode = "fills";
  var scale = 1;
  var socket = null;
  var reconnectDelay = 500;

  var canvas = document.getElementById("canvas");
  var ctx = canvas.getContext("2d");
  var stage = document.getElementById("stage");
  var treeEl = document.getElementById("tree");
  var detailsEl = document.getElementById("details");
  var scrubEl = document.getElementById("scrub");
  var liveEl = document.getElementById("live");
  var modeEl = document.getElementById("mode");
  var statusDot = document.getElementById("status-dot");
  var statusText = document.getElementById("status-text");
  var frameInfo = document.getElementById("frame-info");

  function connect() {
    var url = (location.protocol === "https:" ? "wss://" : "ws://") + location.host + "/ws";
    socket = new WebSocket(url);

    socket.onopen = function () {
      reconnectDelay = 500;
      statusDot.classList.add("on");
      statusText.textContent = "connected";
    };
    socket.onclose = function () {
      statusDot.classList.remove("on");
      statusText.textContent = "reconnecting";
      setTimeout(connect, reconnectDelay);
      reconnectDelay = Math.min(reconnectDelay * 2, 5000);
    };
    socket.onerror = function () { socket.close(); };
    socket.onmessage = function (event) {
      var frame;
      try { frame = JSON.parse(event.data); } catch (e) { return; }
      pushFrame(frame);
    };
  }

  function pushFrame(frame) {
    frames.push(frame);
    if (frames.length > MAX_FRAMES) { frames.shift(); if (cursor > 0) cursor--; }
    if (live) cursor = frames.length - 1;

    scrubEl.max = String(Math.max(frames.length - 1, 0));
    scrubEl.disabled = frames.length < 2;
    if (live) scrubEl.value = String(cursor);

    render();
  }

  function currentFrame() {
    return cursor >= 0 && cursor < frames.length ? frames[cursor] : null;
  }

  // Colour arrives as #RRGGBB with opacity carried separately, because the wire
  // format has no alpha channel.
  function fillStyle(hex, opacity) {
    var r = parseInt(hex.substr(1, 2), 16);
    var g = parseInt(hex.substr(3, 2), 16);
    var b = parseInt(hex.substr(5, 2), 16);
    return "rgba(" + r + "," + g + "," + b + "," + opacity + ")";
  }

  function drawNode(node, inherited) {
    // Nodes report only the opacity they contribute themselves, so a consumer
    // has to accumulate on the way down.
    var opacity = inherited * (node.opacity === undefined ? 1 : node.opacity);

    if (mode !== "bounds" && node.skeletons) {
      for (var i = 0; i < node.skeletons.length; i++) {
        var s = node.skeletons[i];
        var a = opacity * (s.opacity === undefined ? 1 : s.opacity);
        ctx.fillStyle = fillStyle(s.color, Math.max(0, Math.min(1, a)));
        ctx.fillRect(s.left, s.top, s.width, s.height);
      }
    }

    if (mode !== "fills") {
      ctx.strokeStyle = "rgba(0,229,255,0.35)";
      ctx.lineWidth = 1 / scale;
      ctx.strokeRect(node.left, node.top, node.width, node.height);
    }

    if (node.isSensitive) {
      ctx.fillStyle = "rgba(255,23,68,0.55)";
      ctx.fillRect(node.left, node.top, node.width, node.height);
    }

    if (node.id === selectedId) {
      ctx.strokeStyle = "#ffea00";
      ctx.lineWidth = 2 / scale;
      ctx.strokeRect(node.left, node.top, node.width, node.height);
    }

    if (node.children) {
      for (var c = 0; c < node.children.length; c++) drawNode(node.children[c], opacity);
    }
  }

  function render() {
    var frame = currentFrame();
    if (!frame) return;

    var bounds = stage.getBoundingClientRect();
    var available = { w: bounds.width - 32, h: bounds.height - 32 };
    scale = Math.max(0.05, Math.min(available.w / frame.width, available.h / frame.height));
    var dpr = window.devicePixelRatio || 1;

    canvas.width = Math.round(frame.width * scale * dpr);
    canvas.height = Math.round(frame.height * scale * dpr);
    canvas.style.width = (frame.width * scale) + "px";
    canvas.style.height = (frame.height * scale) + "px";

    ctx.setTransform(scale * dpr, 0, 0, scale * dpr, 0, 0);
    ctx.clearRect(0, 0, frame.width, frame.height);
    ctx.fillStyle = "#212121";
    ctx.fillRect(0, 0, frame.width, frame.height);

    drawNode(frame.tree, 1);

    var counts = summarise(frame.tree);
    frameInfo.textContent =
      "frame " + (cursor + 1) + "/" + frames.length +
      " \u00b7 " + counts.nodes + " nodes \u00b7 " + counts.fills + " fills" +
      " \u00b7 " + Math.round(frame.width) + "\u00d7" + Math.round(frame.height) +
      " @" + frame.devicePixelRatio + "x" + gap();

    renderTree(frame);
    renderDetails(frame);
  }

  function gap() {
    if (cursor < 1) return "";
    var delta = (frames[cursor].capturedAt - frames[cursor - 1].capturedAt) / 1000;
    return " \u00b7 +" + Math.round(delta) + "ms";
  }

  function summarise(node) {
    var nodes = 1;
    var fills = node.skeletons ? node.skeletons.length : 0;
    if (node.children) {
      for (var i = 0; i < node.children.length; i++) {
        var child = summarise(node.children[i]);
        nodes += child.nodes;
        fills += child.fills;
      }
    }
    return { nodes: nodes, fills: fills };
  }

  function renderTree(frame) {
    var rows = document.createDocumentFragment();

    function visit(node, depth) {
      var row = document.createElement("div");
      row.className = "row" + (node.id === selectedId ? " selected" : "");
      row.style.paddingLeft = (8 + depth * 12) + "px";

      var hasChildren = node.children && node.children.length > 0;
      var isCollapsed = collapsed[node.id];

      var twisty = document.createElement("span");
      twisty.className = "twisty";
      twisty.textContent = hasChildren ? (isCollapsed ? "\u25b8" : "\u25be") : "";
      twisty.onclick = function (event) {
        event.stopPropagation();
        if (!hasChildren) return;
        if (isCollapsed) delete collapsed[node.id]; else collapsed[node.id] = true;
        render();
      };

      var type = document.createElement("span");
      type.className = "type";
      type.textContent = node.type;

      var meta = document.createElement("span");
      meta.className = "meta";
      meta.textContent = Math.round(node.width) + "\u00d7" + Math.round(node.height);

      row.appendChild(twisty);
      if (node.isSensitive) {
        var lock = document.createElement("span");
        lock.className = "lock";
        lock.textContent = "\u25cf";
        row.appendChild(lock);
      }
      row.appendChild(type);
      row.appendChild(meta);
      row.onclick = function () {
        selectedId = node.id === selectedId ? null : node.id;
        render();
      };

      rows.appendChild(row);

      if (hasChildren && !isCollapsed) {
        for (var i = 0; i < node.children.length; i++) visit(node.children[i], depth + 1);
      }
    }

    visit(frame.tree, 0);

    var scrollTop = treeEl.scrollTop;
    treeEl.textContent = "";
    treeEl.appendChild(rows);
    treeEl.scrollTop = scrollTop;
  }

  function find(node, id) {
    if (node.id === id) return node;
    if (node.children) {
      for (var i = 0; i < node.children.length; i++) {
        var found = find(node.children[i], id);
        if (found) return found;
      }
    }
    return null;
  }

  function renderDetails(frame) {
    if (!selectedId) {
      detailsEl.textContent = "";
      var empty = document.createElement("p");
      empty.className = "empty";
      empty.textContent = "No node selected.";
      detailsEl.appendChild(empty);
      return;
    }

    var node = find(frame.tree, selectedId);
    if (!node) {
      detailsEl.textContent = "";
      var gone = document.createElement("p");
      gone.className = "empty";
      gone.textContent = "Selected node is not in this frame.";
      detailsEl.appendChild(gone);
      return;
    }

    var pairs = [
      ["type", node.type],
      ["id", node.id],
      ["left", Math.round(node.left * 10) / 10],
      ["top", Math.round(node.top * 10) / 10],
      ["size", Math.round(node.width * 10) / 10 + " \u00d7 " + Math.round(node.height * 10) / 10],
      ["opacity", node.opacity === undefined ? 1 : node.opacity],
      ["fills", node.skeletons ? node.skeletons.length : 0],
      ["children", node.children ? node.children.length : 0],
      ["private", node.isSensitive ? "yes" : "no"]
    ];
    if (node.nativeViewId !== undefined) pairs.push(["nativeViewId", node.nativeViewId]);

    var list = document.createElement("dl");
    for (var i = 0; i < pairs.length; i++) {
      var dt = document.createElement("dt");
      dt.textContent = pairs[i][0];
      var dd = document.createElement("dd");
      dd.textContent = String(pairs[i][1]);
      list.appendChild(dt);
      list.appendChild(dd);
    }

    detailsEl.textContent = "";
    detailsEl.appendChild(list);
  }

  function hitTest(node, x, y, best) {
    var inside = x >= node.left && x <= node.left + node.width &&
                 y >= node.top && y <= node.top + node.height;
    if (inside) best = node;
    if (node.children) {
      for (var i = 0; i < node.children.length; i++) best = hitTest(node.children[i], x, y, best);
    }
    return best;
  }

  canvas.onclick = function (event) {
    var frame = currentFrame();
    if (!frame) return;
    var box = canvas.getBoundingClientRect();
    var hit = hitTest(frame.tree, (event.clientX - box.left) / scale, (event.clientY - box.top) / scale, null);
    selectedId = hit ? hit.id : null;
    render();
  };

  scrubEl.oninput = function () {
    live = false;
    liveEl.classList.remove("active");
    cursor = Number(scrubEl.value);
    render();
  };

  liveEl.onclick = function () {
    live = !live;
    liveEl.classList.toggle("active", live);
    if (live && frames.length > 0) {
      cursor = frames.length - 1;
      scrubEl.value = String(cursor);
      render();
    }
  };

  modeEl.onchange = function () { mode = modeEl.value; render(); };
  window.onresize = render;

  connect();
})();
</script>
</body>
</html>
''';
