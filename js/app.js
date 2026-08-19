// ===== LOGIK POS =====
// Dimuatkan KEDUA (selepas bootstrap.bundle + data.js).
// Bergantung pada PRODUCTS, helper variasi/format dalam data.js,
// dan objek global `bootstrap` untuk komponen Modal & Toast.

// ===== STATE =====
let cart = [];
let activeCategory = "Semua";
let searchTerm = "";

// State modal variasi
let currentVariationProduct = null;
let variationSelections = {};   // { [groupId]: [optionId, ...] }
let variationQty = 1;

// ===== ELEMEN DOM =====
const categoryListEl = document.getElementById("categoryList");
const productGridEl = document.getElementById("productGrid");
const searchInputEl = document.getElementById("searchInput");
const cartItemsEl = document.getElementById("cartItems");
const emptyCartMsgEl = document.getElementById("emptyCartMsg");
const subtotalValueEl = document.getElementById("subtotalValue");
const taxValueEl = document.getElementById("taxValue");
const totalValueEl = document.getElementById("totalValue");
const discountInputEl = document.getElementById("discountInput");
const clearCartBtn = document.getElementById("clearCartBtn");
const checkoutBtn = document.getElementById("checkoutBtn");
const clockEl = document.getElementById("clock");

const variationModal = document.getElementById("variationModal");
const variationTitleEl = document.getElementById("variationTitle");
const variationSubtitleEl = document.getElementById("variationSubtitle");
const variationGroupsEl = document.getElementById("variationGroups");
const varQtyValueEl = document.getElementById("varQtyValue");
const varQtyMinusBtn = document.getElementById("varQtyMinus");
const varQtyPlusBtn = document.getElementById("varQtyPlus");
const addVariationBtn = document.getElementById("addVariationBtn");

const paymentModal = document.getElementById("paymentModal");
const modalTotalEl = document.getElementById("modalTotal");
const cashInputEl = document.getElementById("cashInput");
const changeValueEl = document.getElementById("changeValue");
const confirmPaymentBtn = document.getElementById("confirmPaymentBtn");

const receiptModal = document.getElementById("receiptModal");
const receiptContentEl = document.getElementById("receiptContent");
const printReceiptBtn = document.getElementById("printReceiptBtn");

const historyBtn = document.getElementById("historyBtn");
const historyModal = document.getElementById("historyModal");
const historyListEl = document.getElementById("historyList");

const toastEl = document.getElementById("toast");
const toastBodyEl = document.getElementById("toastBody");

// ===== HELPER BOOTSTRAP =====
function showModal(el) {
  bootstrap.Modal.getOrCreateInstance(el).show();
}

function hideModal(el) {
  bootstrap.Modal.getOrCreateInstance(el).hide();
}

function showToast(message) {
  toastBodyEl.textContent = message;
  bootstrap.Toast.getOrCreateInstance(toastEl, { delay: 1800 }).show();
}

function updateClock() {
  const now = new Date();
  clockEl.textContent = now.toLocaleDateString("ms-MY", {
    weekday: "short", day: "2-digit", month: "short", year: "numeric"
  }) + " • " + now.toLocaleTimeString("ms-MY");
}

// ===== KATEGORI =====
function renderCategories() {
  const categories = ["Semua", ...new Set(PRODUCTS.map(p => p.category))];
  categoryListEl.innerHTML = "";
  categories.forEach(cat => {
    const btn = document.createElement("button");
    btn.className = "btn btn-sm rounded-pill " +
      (cat === activeCategory ? "btn-primary" : "btn-outline-secondary");
    btn.textContent = cat;
    btn.addEventListener("click", () => {
      activeCategory = cat;
      renderCategories();
      renderProducts();
    });
    categoryListEl.appendChild(btn);
  });
}

// ===== PRODUK =====
function renderProducts() {
  const filtered = PRODUCTS.filter(p => {
    const matchCategory = activeCategory === "Semua" || p.category === activeCategory;
    const matchSearch = p.name.toLowerCase().includes(searchTerm.toLowerCase());
    return matchCategory && matchSearch;
  });

  productGridEl.innerHTML = "";

  if (filtered.length === 0) {
    productGridEl.innerHTML =
      `<p class="text-body-secondary small">Tiada produk dijumpai</p>`;
    return;
  }

  filtered.forEach(product => {
    const outOfStock = product.stock <= 0;
    const withVariations = hasVariations(product);

    const card = document.createElement("div");
    card.className = "card product-card border" + (outOfStock ? " disabled" : "");
    if (!outOfStock) {
      card.setAttribute("role", "button");
      card.setAttribute("tabindex", "0");
    }
    card.innerHTML = `
      ${withVariations
        ? `<span class="badge bg-primary-subtle text-primary-emphasis border border-primary-subtle variation-badge">Ada pilihan</span>`
        : ""}
      <div class="card-body d-flex flex-column align-items-center text-center p-3 pb-2">
        <div class="product-icon mb-2">${product.icon}</div>
        <div class="fw-semibold small lh-sm mb-1">${escapeHtml(product.name)}</div>
        <div class="text-primary fw-bold small mb-1">
          ${withVariations ? `<span class="fw-normal text-body-secondary">dari </span>` : ""}${formatRM(product.price)}
        </div>
        <div class="text-body-secondary" style="font-size:.72rem">
          ${outOfStock ? "Stok habis" : "Stok: " + product.stock}
        </div>
      </div>
      <div class="card-footer bg-transparent border-0 p-2 pt-0">
        <span class="btn btn-sm w-100 ${outOfStock ? "btn-secondary disabled" : "btn-primary"}">
          ${outOfStock ? "Habis" : (withVariations ? "Pilih pilihan" : "+ Tambah")}
        </span>
      </div>
    `;

    if (!outOfStock) {
      const activate = () => {
        if (withVariations) openVariationModal(product);
        else addToCart(product, [], 1);
      };
      card.addEventListener("click", activate);
      card.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          activate();
        }
      });
    }

    productGridEl.appendChild(card);
  });
}

// ===== MODAL VARIASI =====
function openVariationModal(product) {
  currentVariationProduct = product;
  variationQty = 1;
  variationSelections = {};

  // Pra-pilih pilihan pertama bagi kumpulan `single` yang wajib.
  product.variations.forEach(group => {
    if (group.type === "single" && group.required && group.options.length > 0) {
      variationSelections[group.id] = [group.options[0].id];
    } else {
      variationSelections[group.id] = [];
    }
  });

  variationTitleEl.textContent = product.name;
  variationSubtitleEl.textContent = `Harga asas ${formatRM(product.price)} • Stok ${product.stock}`;
  varQtyValueEl.textContent = variationQty;

  renderVariationGroups();
  updateVariationPrice();
  showModal(variationModal);
}

function renderVariationGroups() {
  const product = currentVariationProduct;
  variationGroupsEl.innerHTML = "";

  product.variations.forEach(group => {
    const selected = variationSelections[group.id] || [];
    const inputType = group.type === "single" ? "radio" : "checkbox";
    const inputClass = group.type === "single" ? "form-check-input" : "form-check-input";
    const hint = group.type === "single" ? "pilih satu" : "pilih berbilang";

    const optionsHtml = group.options.map(opt => {
      const checked = selected.includes(opt.id) ? "checked" : "";
      const delta = formatDelta(opt.priceDelta);
      return `
        <label class="variation-option">
          <input class="${inputClass}" type="${inputType}"
                 name="grp_${escapeHtml(group.id)}" value="${escapeHtml(opt.id)}" ${checked}>
          <span class="variation-option-label">${escapeHtml(opt.label)}</span>
          <span class="fw-semibold small text-primary">${delta}</span>
        </label>
      `;
    }).join("");

    const groupEl = document.createElement("div");
    groupEl.innerHTML = `
      <div class="d-flex justify-content-between align-items-baseline mb-2">
        <span class="fw-semibold small">
          ${escapeHtml(group.name)}${group.required ? ` <span class="text-danger">*</span>` : ""}
        </span>
        <span class="badge text-bg-light fw-normal">${hint}</span>
      </div>
      <div class="d-flex flex-column gap-2">${optionsHtml}</div>
    `;

    // Kemas kini state pada setiap perubahan — tiada render semula,
    // jadi radio/checkbox kekal responsif dan tiada kehilangan fokus.
    groupEl.querySelectorAll("input").forEach(input => {
      input.addEventListener("change", () => {
        if (group.type === "single") {
          variationSelections[group.id] = [input.value];
        } else {
          const set = new Set(variationSelections[group.id] || []);
          if (input.checked) set.add(input.value);
          else set.delete(input.value);
          variationSelections[group.id] = [...set];
        }
        updateVariationPrice();
      });
    });

    variationGroupsEl.appendChild(groupEl);
  });
}

// Bina struktur `selections` daripada state semasa modal.
function getCurrentSelections() {
  const product = currentVariationProduct;
  return product.variations
    .map(group => {
      const optionIds = variationSelections[group.id] || [];
      return {
        groupId: group.id,
        groupName: group.name,
        optionIds,
        labels: optionIds
          .map(id => (group.options.find(o => o.id === id) || {}).label)
          .filter(Boolean)
      };
    })
    .filter(sel => sel.optionIds.length > 0);
}

function isVariationValid() {
  return currentVariationProduct.variations.every(group => {
    if (!group.required) return true;
    return (variationSelections[group.id] || []).length > 0;
  });
}

function updateVariationPrice() {
  const product = currentVariationProduct;
  const selections = getCurrentSelections();
  const unitPrice = calcUnitPrice(product, selections);
  const valid = isVariationValid();

  addVariationBtn.disabled = !valid;
  addVariationBtn.textContent = valid
    ? `Tambah — ${formatRM(unitPrice * variationQty)}`
    : "Sila pilih pilihan wajib";
}

function changeVariationQty(delta) {
  if (!currentVariationProduct) return;
  variationQty = Math.max(1, variationQty + delta);
  varQtyValueEl.textContent = variationQty;
  updateVariationPrice();
}

function confirmVariation() {
  if (!currentVariationProduct || !isVariationValid()) return;
  // Rakam nilai dahulu — modal dikosongkan bila `hidden.bs.modal` berlaku.
  const product = currentVariationProduct;
  const selections = getCurrentSelections();
  const qty = variationQty;
  hideModal(variationModal);
  addToCart(product, selections, qty);
}

// ===== TROLI =====
// Stok dikongsi satu kolam per produk — jumlahkan semua baris produk itu.
function qtyInCartForProduct(productId) {
  return cart
    .filter(i => i.productId === productId)
    .reduce((sum, i) => sum + i.qty, 0);
}

function addToCart(product, selections, qty) {
  const addQty = qty || 1;

  if (qtyInCartForProduct(product.id) + addQty > product.stock) {
    showToast(`Stok "${product.name}" tidak mencukupi`);
    return;
  }

  const lineId = makeLineId(product.id, selections);
  const existing = cart.find(item => item.lineId === lineId);

  if (existing) {
    existing.qty += addQty;
  } else {
    cart.push({
      lineId,
      productId: product.id,
      name: product.name,
      icon: product.icon,
      basePrice: product.price,
      price: calcUnitPrice(product, selections),
      variantLabel: buildVariantLabel(selections),
      selections,
      qty: addQty
    });
  }

  renderCart();
  showToast(`${product.name} ditambah`);
}

function changeQty(lineId, delta) {
  const item = cart.find(i => i.lineId === lineId);
  if (!item) return;

  const newQty = item.qty + delta;

  if (newQty <= 0) {
    cart = cart.filter(i => i.lineId !== lineId);
  } else {
    const product = PRODUCTS.find(p => p.id === item.productId);
    // Kira baki stok tanpa mengambil kira baris ini sendiri.
    const otherQty = qtyInCartForProduct(item.productId) - item.qty;
    if (product && otherQty + newQty > product.stock) {
      showToast(`Stok "${item.name}" tidak mencukupi`);
      return;
    }
    item.qty = newQty;
  }

  renderCart();
}

function removeFromCart(lineId) {
  cart = cart.filter(i => i.lineId !== lineId);
  renderCart();
}

function clearCart() {
  if (cart.length === 0) return;
  cart = [];
  discountInputEl.value = 0;
  renderCart();
}

function getTotals() {
  const subtotal = cart.reduce((sum, item) => sum + item.price * item.qty, 0);
  const tax = subtotal * TAX_RATE;
  let discount = parseFloat(discountInputEl.value) || 0;
  if (discount < 0) discount = 0;
  if (discount > subtotal + tax) discount = subtotal + tax;
  const total = Math.max(0, subtotal + tax - discount);
  return { subtotal, tax, discount, total };
}

function renderCart() {
  cartItemsEl.innerHTML = "";

  if (cart.length === 0) {
    emptyCartMsgEl.style.display = "block";
    cartItemsEl.appendChild(emptyCartMsgEl);
  } else {
    emptyCartMsgEl.style.display = "none";
    cart.forEach(item => {
      const row = document.createElement("div");
      row.className = "d-flex align-items-center gap-2 border rounded p-2 mb-2";
      row.innerHTML = `
        <span class="fs-5 lh-1">${item.icon}</span>
        <div class="flex-grow-1 min-w-0">
          <div class="fw-semibold small cart-item-name">${escapeHtml(item.name)}</div>
          ${item.variantLabel
            ? `<div class="text-body-secondary cart-item-variant">${escapeHtml(item.variantLabel)}</div>`
            : ""}
          <div class="text-body-secondary" style="font-size:.73rem">
            ${formatRM(item.price)} × ${item.qty} = <span class="fw-semibold">${formatRM(item.price * item.qty)}</span>
          </div>
        </div>
        <div class="btn-group btn-group-sm flex-shrink-0" role="group">
          <button class="btn btn-outline-secondary minus" aria-label="Kurang">−</button>
          <span class="btn btn-outline-secondary disabled px-2">${item.qty}</span>
          <button class="btn btn-outline-secondary plus" aria-label="Tambah">+</button>
        </div>
        <button class="btn btn-sm btn-link text-danger p-0 ms-1 remove-btn flex-shrink-0"
                title="Buang" aria-label="Buang">✕</button>
      `;
      row.querySelector(".minus").addEventListener("click", () => changeQty(item.lineId, -1));
      row.querySelector(".plus").addEventListener("click", () => changeQty(item.lineId, 1));
      row.querySelector(".remove-btn").addEventListener("click", () => removeFromCart(item.lineId));
      cartItemsEl.appendChild(row);
    });
  }

  const { subtotal, tax, total } = getTotals();
  subtotalValueEl.textContent = formatRM(subtotal);
  taxValueEl.textContent = formatRM(tax);
  totalValueEl.textContent = formatRM(total);

  checkoutBtn.disabled = cart.length === 0;
}

// ===== PEMBAYARAN =====
function openPaymentModal() {
  if (cart.length === 0) return;
  const { total } = getTotals();
  modalTotalEl.textContent = formatRM(total);
  cashInputEl.value = "";
  changeValueEl.textContent = formatRM(0);
  confirmPaymentBtn.disabled = true;
  showModal(paymentModal);
}

function updateChange() {
  const { total } = getTotals();
  const cash = parseFloat(cashInputEl.value) || 0;
  const change = cash - total;
  changeValueEl.textContent = formatRM(change > 0 ? change : 0);
  confirmPaymentBtn.disabled = cash < total;
}

function confirmPayment() {
  const { subtotal, tax, discount, total } = getTotals();
  const cash = parseFloat(cashInputEl.value) || 0;

  if (cash < total) {
    showToast("Wang diterima tidak mencukupi");
    return;
  }

  // Kurangkan stok mengikut produk (bukan baris troli).
  cart.forEach(item => {
    const product = PRODUCTS.find(p => p.id === item.productId);
    if (product) product.stock -= item.qty;
  });

  const transaction = {
    id: Date.now(),
    date: new Date().toISOString(),
    items: cart.map(i => ({ ...i })),
    subtotal, tax, discount, total,
    cash, change: cash - total
  };

  saveTransaction(transaction);

  // Tunggu modal bayaran betul-betul tertutup sebelum buka resit,
  // supaya backdrop Bootstrap tidak bertindih.
  paymentModal.addEventListener("hidden.bs.modal", () => showReceipt(transaction), { once: true });
  hideModal(paymentModal);

  cart = [];
  discountInputEl.value = 0;
  renderCart();
  renderProducts();
}

// ===== RESIT =====
function showReceipt(transaction) {
  const dateStr = new Date(transaction.date).toLocaleString("ms-MY");
  let itemsHtml = "";
  transaction.items.forEach(item => {
    itemsHtml += `
      <div class="receipt-line">
        <span class="receipt-item-name">${escapeHtml(item.name)} x${item.qty}</span>
        <span>${formatRM(item.price * item.qty)}</span>
      </div>
      ${item.variantLabel ? `<div class="receipt-variant">${escapeHtml(item.variantLabel)}</div>` : ""}
    `;
  });

  receiptContentEl.innerHTML = `
    <div class="text-center">
      <strong>KEDAI POS</strong><br>
      <span>Resit Rasmi</span><br>
      <span>${dateStr}</span>
    </div>
    <hr>
    ${itemsHtml}
    <hr>
    <div class="receipt-line"><span>Subjumlah</span><span>${formatRM(transaction.subtotal)}</span></div>
    <div class="receipt-line"><span>Cukai (6%)</span><span>${formatRM(transaction.tax)}</span></div>
    <div class="receipt-line"><span>Diskaun</span><span>-${formatRM(transaction.discount)}</span></div>
    <div class="receipt-line"><strong>Jumlah</strong><strong>${formatRM(transaction.total)}</strong></div>
    <hr>
    <div class="receipt-line"><span>Tunai</span><span>${formatRM(transaction.cash)}</span></div>
    <div class="receipt-line"><span>Baki</span><span>${formatRM(transaction.change)}</span></div>
    <hr>
    <div class="text-center">Terima kasih atas pembelian anda!</div>
  `;

  showModal(receiptModal);
}

// ===== SEJARAH (localStorage) =====
function getHistory() {
  try {
    return JSON.parse(localStorage.getItem(HISTORY_KEY)) || [];
  } catch {
    return [];
  }
}

function saveTransaction(transaction) {
  const history = getHistory();
  history.unshift(transaction);
  localStorage.setItem(HISTORY_KEY, JSON.stringify(history.slice(0, 50)));
}

function renderHistory() {
  const history = getHistory();
  historyListEl.innerHTML = "";

  if (history.length === 0) {
    historyListEl.innerHTML =
      `<p class="text-body-secondary text-center small py-4 mb-0">Tiada transaksi lagi</p>`;
    return;
  }

  history.forEach(t => {
    const dateStr = new Date(t.date).toLocaleString("ms-MY");
    const itemCount = t.items.reduce((sum, i) => sum + i.qty, 0);
    const itemLines = t.items.map(i =>
      `${escapeHtml(i.name)} ×${i.qty}` +
      (i.variantLabel ? ` <em class="text-body-tertiary">(${escapeHtml(i.variantLabel)})</em>` : "")
    ).join("<br>");

    const div = document.createElement("div");
    div.className = "border rounded p-2";
    div.innerHTML = `
      <div class="d-flex justify-content-between fw-semibold small">
        <span class="font-monospace">#${t.id.toString().slice(-6)}</span>
        <span class="text-primary">${formatRM(t.total)}</span>
      </div>
      <div class="text-body-secondary" style="font-size:.74rem">${dateStr} • ${itemCount} item</div>
      <div class="border-top mt-2 pt-2 text-body-secondary" style="font-size:.74rem; line-height:1.5">
        ${itemLines}
      </div>
    `;
    historyListEl.appendChild(div);
  });
}

function openHistoryModal() {
  renderHistory();
  showModal(historyModal);
}

// ===== EVENT LISTENERS =====
searchInputEl.addEventListener("input", (e) => {
  searchTerm = e.target.value;
  renderProducts();
});

discountInputEl.addEventListener("input", renderCart);
clearCartBtn.addEventListener("click", clearCart);
checkoutBtn.addEventListener("click", openPaymentModal);

addVariationBtn.addEventListener("click", confirmVariation);
varQtyMinusBtn.addEventListener("click", () => changeVariationQty(-1));
varQtyPlusBtn.addEventListener("click", () => changeVariationQty(1));

// Butang tutup guna data-bs-dismiss; bersihkan state bila modal benar-benar tertutup
// (termasuk bila ditutup dengan ESC atau klik latar).
variationModal.addEventListener("hidden.bs.modal", () => {
  currentVariationProduct = null;
});

confirmPaymentBtn.addEventListener("click", confirmPayment);
cashInputEl.addEventListener("input", updateChange);
paymentModal.addEventListener("shown.bs.modal", () => cashInputEl.focus());

printReceiptBtn.addEventListener("click", () => window.print());
historyBtn.addEventListener("click", openHistoryModal);

// ===== INIT =====
function init() {
  applyVariationOverrides();
  renderCategories();
  renderProducts();
  renderCart();
  updateClock();
  setInterval(updateClock, 1000);
}

init();
