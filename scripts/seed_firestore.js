/**
 * 🏮 Vị Lai Quán (未来馆) – Firestore Seed Script
 * ------------------------------------------------
 * Yêu cầu:
 *   npm install firebase-admin
 *
 * Cách chạy:
 *   1. Tải serviceAccountKey.json từ Firebase Console:
 *      Project Settings → Service Accounts → Generate new private key
 *   2. Đặt file vào cùng thư mục này
 *   3. Chạy: node seed_firestore.js
 *
 * Firebase Project: quan-ly-nha-hang-20f37
 */

const admin = require('firebase-admin');
const path  = require('path');
const fs    = require('fs');

// ── Init Firebase Admin ──────────────────────────────────────────────────────
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── Load seed data ───────────────────────────────────────────────────────────
const seedData = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'seed_data.json'), 'utf8')
);

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Giả lập Supabase Storage URL (scheme đúng chuẩn) */
function supabaseImageUrl(dishId) {
  return `https://supabase.co/storage/v1/object/public/vilaiquan/dishes/${dishId}.jpg`;
}

/** Batch-write với giới hạn 500 operations/batch của Firestore */
async function batchWrite(collectionName, items, buildDoc) {
  const BATCH_LIMIT = 490;
  let batch   = db.batch();
  let opCount = 0;

  for (const item of items) {
    const docRef = db.collection(collectionName).doc(item.id || item.table_id?.toString());
    const data   = buildDoc(item);
    batch.set(docRef, data, { merge: false });
    opCount++;

    if (opCount >= BATCH_LIMIT) {
      await batch.commit();
      console.log(`  ✓ Committed ${opCount} docs to ${collectionName}`);
      batch   = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) {
    await batch.commit();
    console.log(`  ✓ Committed ${opCount} docs to ${collectionName}`);
  }
}

// ── 1. seedCategories() ──────────────────────────────────────────────────────
async function seedCategories() {
  console.log('\n📂 Seeding categories...');
  await batchWrite('categories', seedData.categories, (cat) => ({
    id:   cat.id,
    name: cat.name,
  }));
  console.log(`✅ ${seedData.categories.length} categories seeded.`);
}

// ── 2. seedDishes() ──────────────────────────────────────────────────────────
async function seedDishes() {
  console.log('\n🍽️  Seeding dishes...');
  await batchWrite('dishes', seedData.dishes, (dish) => ({
    id:           dish.id,
    name:         dish.name,
    price:        dish.price,
    category:     dish.category,
    description:  dish.description,
    image_url:    supabaseImageUrl(dish.id),   // Supabase URL giả lập
    status:       dish.status,
    isAvailable:  dish.isAvailable,
    isBestSeller: dish.isBestSeller,
    created_at:   admin.firestore.Timestamp.fromDate(new Date(dish.created_at)),
  }));
  console.log(`✅ ${seedData.dishes.length} dishes seeded.`);
}

// ── 3. seedTables() ──────────────────────────────────────────────────────────
async function seedTables() {
  console.log('\n🪑 Seeding tables...');
  await batchWrite('tables', seedData.tables, (table) => ({
    id:       table.id,
    name:     table.name,
    status:   table.status,
    capacity: table.capacity,
  }));
  console.log(`✅ ${seedData.tables.length} tables seeded.`);
}

// ── 4. seedChatbot() ─────────────────────────────────────────────────────────
async function seedChatbot() {
  console.log('\n🤖 Seeding chatbot_data...');
  await batchWrite('chatbot_data', seedData.chatbot_data, (faq) => ({
    id:       faq.id,
    question: faq.question,
    answer:   faq.answer,
  }));
  console.log(`✅ ${seedData.chatbot_data.length} FAQ entries seeded.`);
}

// ── 5. seedAll() – entry point ───────────────────────────────────────────────
async function seedAll() {
  console.log('🏮 ====================================');
  console.log('   Vị Lai Quán (未来馆) – Seed Script');
  console.log('   Firebase: quan-ly-nha-hang-20f37');
  console.log('🏮 ====================================');

  try {
    await seedCategories();
    await seedDishes();
    await seedTables();
    await seedChatbot();

    console.log('\n🎉 Seed hoàn tất! Database đã sẵn sàng sử dụng.');
    console.log('   → Categories : ' + seedData.categories.length);
    console.log('   → Dishes     : ' + seedData.dishes.length);
    console.log('   → Tables     : ' + seedData.tables.length);
    console.log('   → Chatbot FAQ: ' + seedData.chatbot_data.length);
  } catch (err) {
    console.error('\n❌ Lỗi khi seed:', err.message);
    process.exit(1);
  }

  process.exit(0);
}

// ── Run ──────────────────────────────────────────────────────────────────────
seedAll();
