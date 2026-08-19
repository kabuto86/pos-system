// ===== DATA & STORAN =====
// Dimuatkan PERTAMA. Menyediakan katalog produk, variasi lalai,
// storan localStorage, dan helper pengiraan harga/lineId.

const TAX_RATE = 0.06;
const HISTORY_KEY = "pos_transaction_history";
const VARIATIONS_KEY = "pos_variations_v1";

// ===== KATALOG PRODUK =====
// `variations` adalah pilihan. Produk tanpa `variations` terus masuk troli.
const PRODUCTS = [
  {
    id: 1, name: "Nasi Lemak", price: 4.50, icon: "🍛", category: "Makanan", stock: 20,
    variations: [
      {
        id: "lauk", name: "Lauk", type: "single", required: true,
        options: [
          { id: "biasa", label: "Biasa (ikan bilis)", priceDelta: 0 },
          { id: "ayam", label: "Ayam goreng", priceDelta: 3.00 },
          { id: "rendang", label: "Rendang daging", priceDelta: 4.50 }
        ]
      },
      {
        id: "pedas", name: "Kepedasan", type: "single", required: true,
        options: [
          { id: "kurang", label: "Kurang pedas", priceDelta: 0 },
          { id: "sederhana", label: "Sederhana", priceDelta: 0 },
          { id: "extra", label: "Extra pedas", priceDelta: 0.30 }
        ]
      },
      {
        id: "tambah_nl", name: "Tambahan", type: "multi", required: false,
        options: [
          { id: "telur", label: "Telur mata", priceDelta: 1.50 },
          { id: "sambal", label: "Sambal extra", priceDelta: 1.00 },
          { id: "timun", label: "Tanpa timun", priceDelta: 0 }
        ]
      }
    ]
  },
  { id: 2, name: "Roti Canai", price: 2.00, icon: "🫓", category: "Makanan", stock: 30 },
  { id: 3, name: "Mee Goreng", price: 5.00, icon: "🍜", category: "Makanan", stock: 15 },
  { id: 4, name: "Ayam Goreng", price: 6.50, icon: "🍗", category: "Makanan", stock: 12 },
  {
    id: 5, name: "Burger", price: 7.00, icon: "🍔", category: "Makanan", stock: 10,
    variations: [
      {
        id: "patty", name: "Jenis Patty", type: "single", required: true,
        options: [
          { id: "ayam", label: "Ayam", priceDelta: 0 },
          { id: "daging", label: "Daging", priceDelta: 1.50 },
          { id: "double", label: "Double daging", priceDelta: 4.00 }
        ]
      },
      {
        id: "tambah_bg", name: "Tambahan", type: "multi", required: false,
        options: [
          { id: "keju", label: "Keju", priceDelta: 1.00 },
          { id: "telur", label: "Telur", priceDelta: 1.20 },
          { id: "bawang", label: "Tanpa bawang", priceDelta: 0 }
        ]
      }
    ]
  },
  { id: 6, name: "Pizza Slice", price: 8.00, icon: "🍕", category: "Makanan", stock: 8 },
  {
    id: 7, name: "Teh Tarik", price: 2.20, icon: "🍵", category: "Minuman", stock: 40,
    variations: [
      {
        id: "saiz", name: "Saiz", type: "single", required: true,
        options: [
          { id: "kecil", label: "Kecil", priceDelta: 0 },
          { id: "besar", label: "Besar", priceDelta: 0.80 }
        ]
      },
      {
        id: "suhu", name: "Suhu", type: "single", required: true,
        options: [
          { id: "panas", label: "Panas", priceDelta: 0 },
          { id: "ais", label: "Ais", priceDelta: 0.50 }
        ]
      },
      {
        id: "tambah_tt", name: "Tambahan", type: "multi", required: false,
        options: [
          { id: "kurang_manis", label: "Kurang manis", priceDelta: 0 },
          { id: "extra_susu", label: "Extra susu", priceDelta: 0.60 },
          { id: "tanpa_ais", label: "Tanpa ais", priceDelta: -0.20 }
        ]
      }
    ]
  },
  {
    id: 8, name: "Kopi O", price: 1.80, icon: "☕", category: "Minuman", stock: 40,
    variations: [
      {
        id: "saiz", name: "Saiz", type: "single", required: true,
        options: [
          { id: "kecil", label: "Kecil", priceDelta: 0 },
          { id: "besar", label: "Besar", priceDelta: 0.70 }
        ]
      },
      {
        id: "gula", name: "Paras Gula", type: "single", required: true,
        options: [
          { id: "normal", label: "Normal", priceDelta: 0 },
          { id: "kurang", label: "Kurang gula", priceDelta: 0 },
          { id: "kosong", label: "Kosong", priceDelta: 0 }
        ]
      }
    ]
  },
  { id: 9, name: "Air Sirap", price: 1.50, icon: "🥤", category: "Minuman", stock: 25 },
  { id: 10, name: "Jus Oren", price: 3.00, icon: "🧃", category: "Minuman", stock: 18 },
  { id: 11, name: "Air Mineral", price: 1.20, icon: "💧", category: "Minuman", stock: 50 },
  { id: 12, name: "Milkshake", price: 4.00, icon: "🥛", category: "Minuman", stock: 0 },
  { id: 13, name: "Kerepek", price: 1.50, icon: "🍟", category: "Snek", stock: 35 },
  { id: 14, name: "Biskut", price: 2.50, icon: "🍪", category: "Snek", stock: 22 },
  { id: 15, name: "Donut", price: 3.20, icon: "🍩", category: "Snek", stock: 14 },
  { id: 16, name: "Kek Coklat", price: 5.50, icon: "🍰", category: "Snek", stock: 9 },
  { id: 17, name: "Aiskrim", price: 3.50, icon: "🍦", category: "Snek", stock: 0 },
  { id: 18, name: "Coklat Bar", price: 2.00, icon: "🍫", category: "Snek", stock: 28 },
];

// Simpan salinan variasi asal supaya "Reset ke asal" boleh pulihkan.
const DEFAULT_VARIATIONS = {};
PRODUCTS.forEach(p => {
  if (p.variations) DEFAULT_VARIATIONS[p.id] = clone(p.variations);
});

// ===== HELPER UMUM =====
function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function formatRM(value) {
  return "RM " + value.toFixed(2);
}

function formatDelta(value) {
  const n = Number(value) || 0;
  if (n === 0) return "";
  return (n > 0 ? "+" : "−") + "RM " + Math.abs(n).toFixed(2);
}

function uid(prefix) {
  return prefix + "_" + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

// ===== STORAN VARIASI =====
function loadVariationOverrides() {
  try {
    return JSON.parse(localStorage.getItem(VARIATIONS_KEY)) || {};
  } catch {
    return {};
  }
}

function saveVariationOverrides(map) {
  localStorage.setItem(VARIATIONS_KEY, JSON.stringify(map));
  applyVariationOverrides();
}

function resetVariations() {
  localStorage.removeItem(VARIATIONS_KEY);
  applyVariationOverrides();
}

// Gantikan `variations` setiap produk dengan versi tersimpan (jika ada),
// jika tidak pulihkan kepada lalai.
function applyVariationOverrides() {
  const overrides = loadVariationOverrides();
  PRODUCTS.forEach(p => {
    if (overrides[p.id]) {
      p.variations = clone(overrides[p.id]);
    } else if (DEFAULT_VARIATIONS[p.id]) {
      p.variations = clone(DEFAULT_VARIATIONS[p.id]);
    } else {
      delete p.variations;
    }
  });
}

function hasVariations(product) {
  return Array.isArray(product.variations) && product.variations.length > 0;
}

// ===== HELPER VARIASI =====
// `selections` = [{ groupId, groupName, optionIds: [], labels: [] }]

// Kunci unik bagi satu kombinasi produk + pilihan.
// Disusun (sort) supaya kombinasi sama sentiasa hasilkan kunci sama.
function makeLineId(productId, selections) {
  const sig = (selections || [])
    .filter(s => s.optionIds.length > 0)
    .map(s => s.groupId + ":" + [...s.optionIds].sort().join(","))
    .sort()
    .join("|");
  return productId + "#" + sig;
}

function calcUnitPrice(product, selections) {
  let price = product.price;
  (selections || []).forEach(sel => {
    const group = (product.variations || []).find(g => g.id === sel.groupId);
    if (!group) return;
    sel.optionIds.forEach(optId => {
      const opt = group.options.find(o => o.id === optId);
      if (opt) price += Number(opt.priceDelta) || 0;
    });
  });
  return Math.max(0, price);
}

function buildVariantLabel(selections) {
  return (selections || [])
    .flatMap(s => s.labels)
    .join(", ");
}
