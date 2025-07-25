let xpContainer = document.getElementById('xp-container');
let xpGrid = document.getElementById('xp-grid');
let closeBtn = document.getElementById('close-btn');
let modeToggle = document.getElementById('mode-toggle');

function sanitizeString(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

window.addEventListener('DOMContentLoaded', () => {
    if (localStorage.getItem('mode') === 'light') {
        document.body.classList.add('light-mode');
        modeToggle.textContent = '🌙';
    } else {
        modeToggle.textContent = '☀️';
    }
});

window.addEventListener('message', function(event) {
    let data = event.data;

    if (
        typeof data !== 'object' || data === null ||
        data.action !== 'showUI' ||
        typeof data.categories !== 'object' || data.categories === null
    ) return;

    xpContainer.style.display = 'block';
    void xpContainer.offsetWidth;
    xpContainer.classList.remove('fade-out');

    xpGrid.innerHTML = '';

    for (let category in data.categories) {
        if (!Object.prototype.hasOwnProperty.call(data.categories, category)) continue;
        let catData = data.categories[category];

        if (
            typeof catData !== 'object' || catData === null ||
            typeof catData.label !== 'string' ||
            typeof catData.level !== 'number' ||
            typeof catData.xp !== 'number' ||
            typeof catData.maxXP !== 'number' ||
            catData.maxXP <= 0
        ) continue;

        let safeLabel = sanitizeString(catData.label);
        let safeLevel = Math.floor(catData.level);
        let safeXP = Math.max(0, catData.xp);
        let safeMaxXP = catData.maxXP;

        let progressPercent = Math.min(100, Math.max(0, (safeXP / safeMaxXP) * 100));

        let cardDiv = document.createElement('div');
        cardDiv.className = 'xp-card';
        cardDiv.innerHTML = `
            <div class="xp-card-header">
                <h2>${safeLabel}</h2>
                <span class="level">Level ${safeLevel}</span>
            </div>
            <div class="xp-bar">
                <div class="xp-progress" style="width: ${progressPercent}%"></div>
            </div>
            <p>XP ${safeXP} / ${safeMaxXP}</p>
        `;
        xpGrid.appendChild(cardDiv);
    }
});

closeBtn.addEventListener('click', () => {
    xpContainer.classList.add('fade-out');
    setTimeout(() => {
        xpContainer.style.display = 'none';
    }, 400);

    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

window.addEventListener('keydown', (e) => {
    if (e.key === "Escape" && xpContainer.style.display === 'block') {
        closeBtn.click();
    }
});

modeToggle.addEventListener('click', () => {
    document.body.classList.toggle('light-mode');
    if (document.body.classList.contains('light-mode')) {
        modeToggle.textContent = '🌙';
        localStorage.setItem('mode', 'light');
    } else {
        modeToggle.textContent = '☀️';
        localStorage.setItem('mode', 'dark');
    }
});