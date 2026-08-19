// ===== PANEL ADMIN VARIASI =====
// Dimuatkan KETIGA. Membenarkan pengguna tambah/edit/buang kumpulan variasi
// dan pilihannya semasa runtime, disimpan dalam localStorage.

// Draf diedit secara berasingan daripada PRODUCTS — hanya ditulis
// ke localStorage bila pengguna tekan "Simpan".
let adminDraft = {};
let adminSelectedId = null;

const adminBtn = document.getElementById("adminBtn");
const adminModal = document.getElementById("adminModal");
const adminProductListEl = document.getElementById("adminProductList");
const adminEditorEl = document.getElementById("adminEditor");
const saveVariationsBtn = document.getElementById("saveVariationsBtn");
const resetVariationsBtn = document.getElementById("resetVariationsBtn");

function openAdminModal() {
  adminDraft = {};
  PRODUCTS.forEach(p => {
    adminDraft[p.id] = p.variations ? clone(p.variations) : [];
  });
  adminSelectedId = PRODUCTS[0].id;
  renderAdminProductList();
  renderAdminEditor();
  showModal(adminModal);
}

function renderAdminProductList() {
  adminProductListEl.innerHTML = "";
  PRODUCTS.forEach(p => {
    const count = (adminDraft[p.id] || []).length;
    const item = document.createElement("button");
    item.type = "button";
    item.className = "list-group-item list-group-item-action py-2 px-3" +
      (p.id === adminSelectedId ? " active" : "");
    item.innerHTML = `
      <div class="fw-semibold" style="font-size:.83rem">${p.icon} ${escapeHtml(p.name)}</div>
      <div class="${p.id === adminSelectedId ? "text-white-50" : "text-body-secondary"}"
           style="font-size:.71rem">
        ${count > 0 ? count + " kumpulan" : "tiada variasi"}
      </div>
    `;
    item.addEventListener("click", () => {
      adminSelectedId = p.id;
      renderAdminProductList();
      renderAdminEditor();
    });
    adminProductListEl.appendChild(item);
  });
}

function renderAdminEditor() {
  const product = PRODUCTS.find(p => p.id === adminSelectedId);
  const groups = adminDraft[adminSelectedId] || [];

  adminEditorEl.innerHTML = `
    <div class="mb-3">
      <h6 class="mb-0 fw-semibold">${product.icon} ${escapeHtml(product.name)}</h6>
      <span class="text-body-secondary" style="font-size:.76rem">
        Harga asas ${formatRM(product.price)}
      </span>
    </div>
    <div id="adminGroups"></div>
    <button class="btn btn-sm btn-outline-primary w-100 admin-add-group">
      + Tambah Kumpulan Variasi
    </button>
  `;

  const groupsWrap = adminEditorEl.querySelector("#adminGroups");

  if (groups.length === 0) {
    groupsWrap.innerHTML = `
      <div class="alert alert-light border small py-2 mb-3">
        Tiada variasi. Produk ini terus masuk troli bila ditekan.
      </div>
    `;
  }

  groups.forEach((group, gIndex) => {
    const optionsHtml = group.options.map((opt, oIndex) => `
      <div class="d-flex align-items-center gap-2 mb-2 opt-row">
        <input type="text" class="form-control form-control-sm opt-label"
               data-g="${gIndex}" data-o="${oIndex}"
               value="${escapeHtml(opt.label)}" placeholder="Nama pilihan">
        <div class="input-group input-group-sm opt-delta">
          <span class="input-group-text">RM</span>
          <input type="number" step="0.10" class="form-control text-end opt-delta-input"
                 data-g="${gIndex}" data-o="${oIndex}" value="${Number(opt.priceDelta) || 0}">
        </div>
        <button class="btn btn-sm btn-link text-danger p-0 px-1 opt-remove flex-shrink-0"
                data-g="${gIndex}" data-o="${oIndex}" title="Buang pilihan">✕</button>
      </div>
    `).join("");

    const groupEl = document.createElement("div");
    groupEl.className = "border rounded p-2 mb-2";
    groupEl.innerHTML = `
      <div class="d-flex align-items-center gap-2 mb-2 flex-wrap">
        <input type="text" class="form-control form-control-sm fw-semibold grp-name flex-grow-1"
               data-g="${gIndex}" value="${escapeHtml(group.name)}"
               placeholder="Nama kumpulan (cth. Saiz)">
        <select class="form-select form-select-sm w-auto grp-type" data-g="${gIndex}">
          <option value="single" ${group.type === "single" ? "selected" : ""}>Pilih satu</option>
          <option value="multi" ${group.type === "multi" ? "selected" : ""}>Pilih berbilang</option>
        </select>
        <div class="form-check mb-0">
          <input class="form-check-input grp-required" type="checkbox"
                 id="req_${gIndex}" data-g="${gIndex}" ${group.required ? "checked" : ""}>
          <label class="form-check-label small text-body-secondary" for="req_${gIndex}">Wajib</label>
        </div>
        <button class="btn btn-sm btn-link text-danger p-0 px-1 grp-remove"
                data-g="${gIndex}" title="Buang kumpulan">✕</button>
      </div>
      <div class="admin-options">${optionsHtml}</div>
      <button class="btn btn-sm btn-link text-decoration-none p-0 admin-add-option"
              data-g="${gIndex}">+ Tambah pilihan</button>
    `;
    groupsWrap.appendChild(groupEl);
  });

  bindAdminEditorEvents();
}

function bindAdminEditorEvents() {
  const groups = adminDraft[adminSelectedId];

  // --- Perubahan teks/nombor: kemas kini draf sahaja, TIADA render semula
  //     supaya fokus kursor tidak hilang semasa menaip.
  adminEditorEl.querySelectorAll(".grp-name").forEach(input => {
    input.addEventListener("input", () => {
      groups[+input.dataset.g].name = input.value;
    });
  });

  adminEditorEl.querySelectorAll(".grp-type").forEach(select => {
    select.addEventListener("change", () => {
      groups[+select.dataset.g].type = select.value;
    });
  });

  adminEditorEl.querySelectorAll(".grp-required").forEach(box => {
    box.addEventListener("change", () => {
      groups[+box.dataset.g].required = box.checked;
    });
  });

  adminEditorEl.querySelectorAll(".opt-label").forEach(input => {
    input.addEventListener("input", () => {
      groups[+input.dataset.g].options[+input.dataset.o].label = input.value;
    });
  });

  adminEditorEl.querySelectorAll(".opt-delta-input").forEach(input => {
    input.addEventListener("input", () => {
      groups[+input.dataset.g].options[+input.dataset.o].priceDelta = parseFloat(input.value) || 0;
    });
  });

  // --- Perubahan struktur: render semula editor.
  adminEditorEl.querySelectorAll(".grp-remove").forEach(btn => {
    btn.addEventListener("click", () => {
      groups.splice(+btn.dataset.g, 1);
      renderAdminProductList();
      renderAdminEditor();
    });
  });

  adminEditorEl.querySelectorAll(".opt-remove").forEach(btn => {
    btn.addEventListener("click", () => {
      groups[+btn.dataset.g].options.splice(+btn.dataset.o, 1);
      renderAdminEditor();
    });
  });

  adminEditorEl.querySelectorAll(".admin-add-option").forEach(btn => {
    btn.addEventListener("click", () => {
      groups[+btn.dataset.g].options.push({ id: uid("o"), label: "Pilihan baharu", priceDelta: 0 });
      renderAdminEditor();
    });
  });

  adminEditorEl.querySelector(".admin-add-group").addEventListener("click", () => {
    groups.push({
      id: uid("g"),
      name: "Kumpulan baharu",
      type: "single",
      required: true,
      options: [{ id: uid("o"), label: "Pilihan 1", priceDelta: 0 }]
    });
    renderAdminProductList();
    renderAdminEditor();
  });
}

// Pastikan draf sah sebelum disimpan.
function validateAdminDraft() {
  for (const product of PRODUCTS) {
    const groups = adminDraft[product.id] || [];
    for (const group of groups) {
      if (!group.name.trim()) {
        return `Kumpulan variasi dalam "${product.name}" tiada nama`;
      }
      if (group.options.length === 0) {
        return `Kumpulan "${group.name}" dalam "${product.name}" tiada pilihan`;
      }
      for (const opt of group.options) {
        if (!opt.label.trim()) {
          return `Ada pilihan tanpa nama dalam kumpulan "${group.name}"`;
        }
      }
    }
  }
  return null;
}

function saveAdmin() {
  const error = validateAdminDraft();
  if (error) {
    showToast(error);
    return;
  }

  // Simpan draf penuh (termasuk array kosong) supaya pembuangan
  // variasi lalai turut kekal selepas reload.
  saveVariationOverrides(adminDraft);
  renderProducts();
  hideModal(adminModal);
  showToast("Variasi disimpan");
}

function resetAdmin() {
  if (!confirm("Reset semua variasi kepada tetapan asal? Perubahan tersimpan akan hilang.")) return;
  resetVariations();
  renderProducts();
  // Bina semula draf daripada data lalai yang baru dipulihkan.
  openAdminModal();
  showToast("Variasi direset kepada asal");
}

// ===== EVENT LISTENERS =====
// Butang tutup (✕) guna data-bs-dismiss dalam HTML — tiada listener diperlukan.
adminBtn.addEventListener("click", openAdminModal);
saveVariationsBtn.addEventListener("click", saveAdmin);
resetVariationsBtn.addEventListener("click", resetAdmin);
