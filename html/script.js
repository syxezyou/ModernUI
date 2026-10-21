const menuEl    = document.getElementById('menu');
const titleEl   = document.getElementById('title');
const subEl     = document.getElementById('subtitle');
const counterEl = document.getElementById('counter');
const itemsEl   = document.getElementById('items');
const descEl    = document.getElementById('desc');

let scrollStart = 1;

function esc(s) {
    return String(s ?? '').replace(/[&<>"']/g, c => ({
        '&': '&', '<': '<', '>': '>', '"': '"', "'": '''
    }[c]));
}

function renderItem(item, selected) {
    if (item.type === 'separator') {
        const empty = !item.label ? ' empty' : '';
        return `<div class="separator${empty}">${esc(item.label)}</div>`;
    }

    const cls   = ['item', selected ? 'selected' : '', item.disabled ? 'disabled' : ''].join(' ');
    const color = item.color ? ` style="color:${esc(item.color)}"` : '';
    const icon  = item.icon ? `<span class="icon">${esc(item.icon)}</span>` : '';
    let right   = '';

    switch (item.type) {
        case 'button':
            if (item.badge) right += `<span class="badge">${esc(item.badge)}</span>`;
            if (item.right) right += `<span>${esc(item.right)}</span>`;
            if (item.arrow) right += `<span class="arrow">▶</span>`;
            break;
        case 'checkbox':
            right = `<span class="check ${item.checked ? 'on' : ''}">${item.checked ? '✔' : ''}</span>`;
            break;
        case 'list':
            right = `<span class="list-val"><span class="chev">◀</span><span>${esc(item.value)}</span><span class="chev">▶</span></span>`;
            break;
        case 'slider': {
            const pct = item.max > item.min ? ((item.value - item.min) / (item.max - item.min)) * 100 : 0;
            right = `<span class="slider"><span class="bar"><span class="fill" style="width:${pct}%"></span></span><span class="val">${esc(item.value)}${esc(item.suffix || '')}</span></span>`;
            break;
        }
    }

    return `<div class="${cls}">${icon}<span class="label"${color}>${esc(item.label)}</span><span class="right">${right}</span></div>`;
}

function show(data) {
    const s = data.settings || {};
    const max = s.MaxItems || 10;
    const total = data.items.length;
    const index = data.index;

    menuEl.style.left  = (s.Position?.x ?? 2) + '%';
    menuEl.style.top   = (s.Position?.y ?? 2) + '%';
    menuEl.style.width = (s.Width ?? 420) + 'px';

    titleEl.textContent   = data.title || '';
    subEl.textContent     = data.subtitle || '';
    counterEl.textContent = `${index} / ${total}`;

    // Fenêtre de scroll
    if (index < scrollStart) scrollStart = index;
    if (index >= scrollStart + max) scrollStart = index - max + 1;
    if (scrollStart < 1) scrollStart = 1;
    if (scrollStart > Math.max(1, total - max + 1)) scrollStart = Math.max(1, total - max + 1);

    let html = '';
    if (scrollStart > 1) html += `<div class="scroll-hint">▲</div>`;
    for (let i = scrollStart; i < scrollStart + max && i <= total; i++) {
        html += renderItem(data.items[i - 1], i === index);
    }
    if (scrollStart + max - 1 < total) html += `<div class="scroll-hint">▼</div>`;
    itemsEl.innerHTML = html;

    const current = data.items[index - 1];
    if (current && current.desc) {
        descEl.textContent = current.desc;
        descEl.classList.remove('hidden');
    } else {
        descEl.classList.add('hidden');
    }

    menuEl.classList.remove('hidden');
}

window.addEventListener('message', e => {
    const d = e.data;
    if (d.action === 'show') show(d);
    else if (d.action === 'hide') {
        menuEl.classList.add('hidden');
        scrollStart = 1;
    }
});