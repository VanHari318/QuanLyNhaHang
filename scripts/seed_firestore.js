/**
 * 🏮 Vị Lai Quán (未来馆) – Firestore Seed Script
 * ------------------------------------------------
 * Cloud: dojcgjli4 (Cloudinary)  |  Folder: Food
 * Firebase Project: quan-ly-nha-hang-20f37
 *
 * Cách chạy (từ thư mục gốc QuanLyNhaHang/):
 *   node scripts/seed_firestore.js
 *
 * Hoặc từ thư mục scripts/:
 *   node seed_firestore.js
 */

const admin = require('firebase-admin');
const path  = require('path');
const fs    = require('fs');

// ── Tìm đúng đường dẫn bất kể chạy từ đâu ───────────────────────────────────
const SCRIPT_DIR = __dirname;                             // .../scripts
const PROJECT_DIR = path.join(SCRIPT_DIR, '..');          // project root

// Service account key (trong thư mục scripts/)
const KEY_FILE = path.join(SCRIPT_DIR,
  'quan-ly-nha-hang-20f37-firebase-adminsdk-fbsvc-90b24fb22e.json');

// Seed data JSON (trong thư mục scripts/)
const DATA_FILE = path.join(SCRIPT_DIR, 'seed_data.json');

// ── Init Firebase ─────────────────────────────────────────────────────────────
const serviceAccount = require(KEY_FILE);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── Load seed data ────────────────────────────────────────────────────────────
const seedData = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));

// ── Cloudinary URL helper ─────────────────────────────────────────────────────
// Cloud name: dojcgjli4  |  Upload preset: FoodPresents  |  Folder: Food
const CLOUD_NAME = 'dojcgjli4';
const FOLDER     = 'Food';

/** Tạo Cloudinary URL cho ảnh món ăn (placeholder – ảnh thật upload qua app) */
function cloudinaryUrl(dishId) {
  // Format: https://res.cloudinary.com/<cloud>/image/upload/v1/<folder>/<id>
  return `https://res.cloudinary.com/${CLOUD_NAME}/image/upload/v1/${FOLDER}/${dishId}`;
}

// ── Helper: batch write ───────────────────────────────────────────────────────
async function batchWrite(collectionName, items, buildDoc) {
  const LIMIT = 490;
  let batch   = db.batch();
  let count   = 0;

  for (const item of items) {
    const docId  = item.id ?? item.table_id?.toString();
    const docRef = db.collection(collectionName).doc(docId);
    batch.set(docRef, buildDoc(item), { merge: false });
    count++;

    if (count >= LIMIT) {
      await batch.commit();
      console.log(`  ✓ Committed ${count} docs to [${collectionName}]`);
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
    console.log(`  ✓ Committed ${count} docs to [${collectionName}]`);
  }
}

// ── 1. seedCategories() ───────────────────────────────────────────────────────
async function seedCategories() {
  console.log('\n📂 Seeding categories...');
  await batchWrite('categories', seedData.categories, (c) => ({
    id:   c.id,
    name: c.name,
  }));
  console.log(`✅ ${seedData.categories.length} categories OK`);
}

// ── 2. seedDishes() ───────────────────────────────────────────────────────────
async function seedDishes() {
  console.log('\n🍽️  Seeding dishes (Cloudinary URLs)...');
  await batchWrite('dishes', seedData.dishes, (d) => ({
    id:           d.id,
    name:         d.name,
    price:        d.price,
    category:     d.category,
    description:  d.description,
    // ← Cloudinary URL (ảnh placeholder; upload ảnh thật qua Admin app)
    imageUrl:     cloudinaryUrl(d.id),
    status:       'available',
    isAvailable:  true,
    isBestSeller: d.isBestSeller,
    createdAt:    admin.firestore.Timestamp.fromDate(new Date(d.created_at)),
  }));
  console.log(`✅ ${seedData.dishes.length} dishes OK`);
  console.log(`   → Cloudinary: res.cloudinary.com/${CLOUD_NAME}/image/upload/v1/${FOLDER}/<id>`);
}

// ── 3. seedTables() ───────────────────────────────────────────────────────────
async function seedTables() {
  console.log('\n🪑 Seeding tables...');
  await batchWrite('tables', seedData.tables, (t) => ({
    id:       t.id,
    name:     t.name,
    status:   'available',
    capacity: t.capacity,
  }));
  console.log(`✅ ${seedData.tables.length} tables OK`);
}

// ── 4. seedChatbot() ──────────────────────────────────────────────────────────
async function seedChatbot() {
  console.log('\n🤖 Seeding chatbot_data...');
  await batchWrite('chatbot_data', seedData.chatbot_data, (f) => ({
    id:       f.id,
    question: f.question,
    answer:   f.answer,
  }));
  console.log(`✅ ${seedData.chatbot_data.length} FAQ OK`);
}

// ── Main ───────────────────────────────────────────────────────────────────────
async function seedAll() {
  console.log('╔══════════════════════════════════════════╗');
  console.log('║  🏮 Vị Lai Quán (未来馆) – Seed Script   ║');
  console.log('║  Firebase : quan-ly-nha-hang-20f37       ║');
  console.log('║  Cloudinary: dojcgjli4 / Food            ║');
  console.log('╚══════════════════════════════════════════╝');

  try {
    await seedCategories();
    await seedDishes();
    await seedTables();
    await seedChatbot();

    console.log('\n🎉 Seed hoàn tất!');
    console.log('   Categories : ' + seedData.categories.length);
    console.log('   Dishes     : ' + seedData.dishes.length);
    console.log('   Tables     : ' + seedData.tables.length);
    console.log('   Chatbot FAQ: ' + seedData.chatbot_data.length);
    console.log('\n💡 Tip: Upload ảnh thật qua Admin Dashboard → Quản Lý Món → chỉnh sửa từng món.');
  } catch (err) {
    console.error('\n❌ Lỗi seed:', err.message);
    process.exit(1);
  }

  process.exit(0);
}

seedAll();
