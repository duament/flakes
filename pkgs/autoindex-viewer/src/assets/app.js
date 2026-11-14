const API_PREFIX = "/.autoindex";
const PAGE_TITLE = "Files";

const crumbs = document.getElementById("crumbs");
const listing = document.getElementById("listing");
const statusEl = document.getElementById("status");
const titleEl = document.getElementById("title");
const itemTemplate = document.getElementById("item-template");

const collator = new Intl.Collator(undefined, {
  numeric: true,
  sensitivity: "base",
});

let controller = null;
let currentPath = "";

function asDirectory(path) {
  return path.endsWith("/") ? path : `${path}/`;
}

function decodeSegment(segment) {
  try {
    return decodeURIComponent(segment);
  } catch {
    return segment;
  }
}

function pathSegments(path) {
  return path.split("/").filter(Boolean);
}

function formatSize(bytes) {
  if (!Number.isFinite(bytes) || bytes < 0) return "\u2014";
  if (bytes < 1024) return `${bytes} B`;

  const units = ["KiB", "MiB", "GiB", "TiB"];
  let value = bytes;
  let unit = -1;

  do {
    value /= 1024;
    unit += 1;
  } while (value >= 1024 && unit < units.length - 1);

  const rounded = value >= 10 ? Math.round(value) : value.toFixed(1).replace(/\.0$/, "");
  return `${rounded} ${units[unit]}`;
}

function formatDate(mtime) {
  const date = new Date(mtime);
  return Number.isNaN(date.getTime()) ? null : date;
}

function formatIsoDateTime(date) {
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${date.getFullYear()}-${month}-${day} ${hours}:${minutes}`;
}

function compareItems(a, b) {
  if (a.type !== b.type) return a.type === "directory" ? -1 : 1;
  return collator.compare(a.name, b.name);
}

async function fetchListing(path, signal) {
  const response = await fetch(`${API_PREFIX}${path}`, {
    signal,
    cache: "no-store",
    headers: { Accept: "application/json" },
  });

  if (!response.ok) throw new Error(`Listing request failed with ${response.status}`);

  const data = await response.json();
  if (!Array.isArray(data)) throw new TypeError("Unexpected listing format");
  return data;
}

function setStatus(message) {
  statusEl.textContent = message ?? "";
}

function summarizePath(path) {
  const parts = pathSegments(path).map(decodeSegment);
  return parts.length === 0 ? PAGE_TITLE : parts.join(" / ");
}

function updateHeading(path) {
  const parts = pathSegments(path).map(decodeSegment);
  titleEl.textContent = summarizePath(path);
  document.title = parts.length === 0 ? PAGE_TITLE : `${parts.at(-1)} \u2013 ${PAGE_TITLE}`;
}

function renderCrumbs(path) {
  const fragment = document.createDocumentFragment();
  const rootItem = document.createElement("li");

  if (path === "/") {
    const current = document.createElement("span");
    current.textContent = "Home";
    current.setAttribute("aria-current", "page");
    rootItem.append(current);
  } else {
    const home = document.createElement("a");
    home.href = "/";
    home.textContent = "Home";
    home.dataset.nav = "";
    rootItem.append(home);
  }
  fragment.append(rootItem);

  const rawParts = pathSegments(path);
  let href = "/";

  rawParts.forEach((rawPart, index) => {
    href += `${rawPart}/`;
    const item = document.createElement("li");
    const isCurrent = index === rawParts.length - 1;

    if (isCurrent) {
      const current = document.createElement("span");
      current.textContent = decodeSegment(rawPart);
      current.setAttribute("aria-current", "page");
      item.append(current);
    } else {
      const link = document.createElement("a");
      link.href = href;
      link.textContent = decodeSegment(rawPart);
      link.dataset.nav = "";
      item.append(link);
    }

    fragment.append(item);
  });

  crumbs.replaceChildren(fragment);
  crumbs.scrollLeft = crumbs.scrollWidth;
}

function renderItems(items) {
  const fragment = document.createDocumentFragment();

  for (const entry of items.toSorted(compareItems)) {
    const item = itemTemplate.content.firstElementChild.cloneNode(true);
    const link = item.querySelector("a");
    const iconUse = item.querySelector("use");
    const name = item.querySelector(".name");
    const size = item.querySelector(".size");
    const date = item.querySelector(".date");
    const isDirectory = entry.type === "directory";

    link.href = `${currentPath}${encodeURIComponent(entry.name)}${isDirectory ? "/" : ""}`;
    if (isDirectory) link.dataset.nav = "";

    iconUse.setAttribute("href", isDirectory ? "#i-dir" : "#i-file");
    name.textContent = entry.name;
    name.title = entry.name;

    if (isDirectory) {
      size.textContent = "\u2014";
      size.setAttribute("aria-hidden", "true");
    } else {
      size.textContent = formatSize(Number(entry.size));
    }

    const modified = formatDate(entry.mtime);
    if (modified) {
      date.dateTime = modified.toISOString();
      date.textContent = formatIsoDateTime(modified);
    } else {
      date.remove();
    }

    fragment.append(item);
  }

  listing.replaceChildren(fragment);
}

async function render(path, { focusHeading = false } = {}) {
  path = asDirectory(path);
  currentPath = path;

  controller?.abort();
  const activeController = new AbortController();
  controller = activeController;

  listing.setAttribute("aria-busy", "true");
  listing.replaceChildren();
  setStatus("Loading\u2026");
  renderCrumbs(path);
  updateHeading(path);

  try {
    const items = await fetchListing(path, activeController.signal);
    if (activeController.signal.aborted) return;

    renderItems(items);
    setStatus(items.length === 0 ? "This folder is empty." : "");
    if (focusHeading) titleEl.focus({ preventScroll: true });
  } catch (error) {
    if (error?.name === "AbortError" || activeController.signal.aborted) return;

    setStatus("Could not load this folder.");
    console.error(error);
  } finally {
    if (controller === activeController) {
      listing.setAttribute("aria-busy", "false");
    }
  }
}

function navigate(path) {
  path = asDirectory(path);
  if (path === location.pathname) return;

  history.pushState(null, "", path);
  window.scrollTo(0, 0);
  render(path, { focusHeading: true });
}

document.addEventListener("click", (event) => {
  if (
    event.defaultPrevented ||
    event.button !== 0 ||
    event.metaKey ||
    event.ctrlKey ||
    event.shiftKey ||
    event.altKey
  ) {
    return;
  }

  const link = event.target.closest?.("a[data-nav]");
  if (!link || link.target || link.hasAttribute("download")) return;

  const url = new URL(link.href, location.href);
  if (url.origin !== location.origin) return;

  event.preventDefault();
  navigate(url.pathname);
});

window.addEventListener("popstate", () => {
  window.scrollTo(0, 0);
  render(location.pathname, { focusHeading: true });
});

if (location.pathname !== "/" && !location.pathname.endsWith("/")) {
  history.replaceState(null, "", asDirectory(location.pathname));
}

render(location.pathname);
