// ===========================================================
// Investigación PL/SQL — índice, resaltado y seguimiento de lectura
// ===========================================================
document.addEventListener('DOMContentLoaded', () => {
  // ---- Resaltado de sintaxis PL/SQL ----
  const KW = ['CREATE','OR','REPLACE','PACKAGE','BODY','PROCEDURE','FUNCTION','TRIGGER','TYPE','IS','AS','BEGIN','END','DECLARE',
    'IF','THEN','ELSE','ELSIF','LOOP','FOR','WHILE','IN','OUT','RETURN','EXCEPTION','WHEN','OTHERS','RAISE','SELECT','FROM','WHERE',
    'INSERT','INTO','VALUES','UPDATE','SET','DELETE','COMMIT','ROLLBACK','SAVEPOINT','TO','CURSOR','OPEN','FETCH','CLOSE','BULK',
    'COLLECT','LIMIT','FORALL','SAVE','EXCEPTIONS','INDICES','OF','PRAGMA','AUTONOMOUS_TRANSACTION','EXCEPTION_INIT','RESULT_CACHE',
    'DETERMINISTIC','PIPELINED','PIPE','ROW','TABLE','INDEX','BY','NUMBER','VARCHAR2','CHAR','DATE','TIMESTAMP','CLOB','BOOLEAN',
    'PLS_INTEGER','CONSTANT','DEFAULT','NULL','NOT','AND','EXISTS','AUTHID','CURRENT_USER','DEFINER','ACCESSIBLE','COMPOUND',
    'AFTER','BEFORE','EACH','STATEMENT','ON','EXECUTE','IMMEDIATE','USING','RETURNING','SKIP','LOCKED','NOWAIT','WAIT','ORDER',
    'GROUP','JOIN','UNION','MULTISET','INTERSECT','EXCEPT','DISTINCT','EXTEND','ALTER','SESSION','GRANT','REVOKE','DIRECTORY',
    'PRIMARY','KEY','UNIQUE','CHECK','REFERENCES','GENERATED','ALWAYS','IDENTITY','CASE','WITH','REF','PRAGMA','SQL_MACRO',
    'INSTEAD','FOLLOWS','COMPILE','REUSE','SETTINGS','NATIVE','LOG','ERRORS','REJECT','UNLIMITED','DESC','NULLS','LAST','LEVEL','CONNECT'];
  const kwRe = new RegExp('\\b(' + KW.join('|') + ')\\b', 'gi');
  const tokRe = new RegExp("(--[^\\n]*)|('(?:[^']|'')*')|(\\$\\$?[A-Za-z_]+|\\$(?:IF|THEN|END))|(\\b\\d+(?:[.,]\\d+)?\\b)|" + kwRe.source, 'gi');
  const esc = t => t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

  document.querySelectorAll('code[data-sql]').forEach(el => {
    const raw = el.textContent;
    let out = '', last = 0, m;
    tokRe.lastIndex = 0;
    while ((m = tokRe.exec(raw)) !== null) {
      out += esc(raw.slice(last, m.index));
      const t = esc(m[0]);
      if (m[1]) out += `<span class="tok-cm">${t}</span>`;
      else if (m[2]) out += `<span class="tok-str">${t}</span>`;
      else if (m[3]) out += `<span class="tok-kw">${t}</span>`;
      else if (m[4]) out += `<span class="tok-num">${t}</span>`;
      else out += `<span class="tok-kw">${t}</span>`;
      last = m.index + m[0].length;
    }
    out += esc(raw.slice(last));
    el.innerHTML = out;
  });

  // ---- Resaltado de sintaxis MQL / JavaScript ----
  const mqlRe = /(\/\/[^\n]*)|("(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*')|(\/[^\/\n*][^\/\n]*\/[a-z]*)|(\$[A-Za-z_]+)|(\b\d+(?:\.\d+)?\b)|\b(const|let|try|catch|use|true|false|null|new|ObjectId|NumberDecimal|print|db)\b|\.(insertOne|insertMany|find|findOne|updateOne|updateMany|aggregate|sort|limit|getCollection)\b/g;
  document.querySelectorAll('code[data-mql]').forEach(el => {
    const raw = el.textContent;
    let out = '', last = 0, m;
    mqlRe.lastIndex = 0;
    while ((m = mqlRe.exec(raw)) !== null) {
      out += esc(raw.slice(last, m.index));
      const t = esc(m[0]);
      if (m[1]) out += `<span class="tok-cm">${t}</span>`;
      else if (m[2] || m[3]) out += `<span class="tok-str">${t}</span>`;
      else if (m[4]) out += `<span class="tok-kw">${t}</span>`;
      else if (m[5]) out += `<span class="tok-num">${t}</span>`;
      else if (m[6]) out += `<span class="tok-kw">${t}</span>`;
      else out += `.<span class="tok-kw">${esc(m[0].slice(1))}</span>`;
      last = m.index + m[0].length;
    }
    out += esc(raw.slice(last));
    el.innerHTML = out;
  });

  // ---- Índice (lateral e inline para impresión) ----
  const sections = [...document.querySelectorAll('.doc > section[id]')];
  const side = document.getElementById('tocList');
  const inline = document.getElementById('tocInline');
  let inlineHtml = '<h2>Contenido</h2><ol>';
  sections.forEach(sec => {
    const h2 = sec.querySelector('h2');
    if (!h2) return;
    const title = h2.textContent.trim();
    if (side) {
      const li = document.createElement('li');
      li.innerHTML = `<a href="#${sec.id}">${title}</a>`;
      side.appendChild(li);
    }
    inlineHtml += `<li><a href="#${sec.id}">${title}</a></li>`;
    sec.querySelectorAll('h3').forEach(h3 => {
      inlineHtml += `<li class="is-sub">${h3.textContent.trim()}</li>`;
    });
  });
  inlineHtml += '</ol>';
  if (inline) inline.innerHTML = inlineHtml;

  // ---- Seguimiento de lectura ----
  const links = side ? [...side.querySelectorAll('a')] : [];
  if ('IntersectionObserver' in window && links.length) {
    const obs = new IntersectionObserver(entries => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          links.forEach(a => a.classList.toggle('is-active', a.getAttribute('href') === '#' + e.target.id));
        }
      });
    }, { rootMargin: '-20% 0px -70% 0px' });
    sections.forEach(s => obs.observe(s));
  }
});
