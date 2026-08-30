(chapterId) => {
  // Prefer span.content-text (VIP), then p tags.
  function chapterTitle() {
    const titleEl = document.querySelector("h1.j_chapterName, h1.chapter-name, .chapter-name, h1");
    if (!titleEl) return "Untitled";
    const clone = titleEl.cloneNode(true);
    clone.querySelectorAll(".review").forEach((n) => n.remove());
    return clone.innerText.replace(/\s+/g, " ").trim() || "Untitled";
  }

  function chapterLocked(bodyText) {
    const lockSels = [".lock-chapter", ".vip-tips", ".chapter-buy-tips", ".buy-chapter-wrap"];
    return bodyText.includes("这是VIP章节") || bodyText.includes("订阅本章") ||
      lockSels.some((sel) => document.querySelector(sel));
  }

  function chapterContainer() {
    const selectors = [];
    if (chapterId) selectors.push("#c-" + chapterId);
    selectors.push("main.content", "main[id^='c-']", ".read-content", ".chapter-content");
    for (const sel of selectors) {
      const el = document.querySelector(sel);
      if (el) return el;
    }
    return null;
  }

  function chapterBody(container) {
    const fromSpans = Array.from(container.querySelectorAll("span.content-text"))
      .map((n) => n.textContent.trim())
      .filter((t) => t.length > 0);
    if (fromSpans.length > 0) return fromSpans.join("\n");
    return Array.from(container.querySelectorAll("p")).map((p) => {
      const clone = p.cloneNode(true);
      clone.querySelectorAll(".review, i, em, a").forEach((n) => n.remove());
      return clone.textContent.trim();
    }).filter((t) => t.length > 0).join("\n");
  }

  const bodyText = document.body ? document.body.innerText : "";
  const title = chapterTitle();
  if (bodyText.includes("章节加载失败")) return { title, body: "", locked: false, loadFailed: true };
  if (chapterLocked(bodyText)) return { title, body: "", locked: true };
  const container = chapterContainer();
  if (!container) return { title, body: "", locked: false };
  return { title, body: chapterBody(container), locked: false };
}
