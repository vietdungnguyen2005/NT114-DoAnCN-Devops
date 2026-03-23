// =============================================================================
// Microservice Seed Script — seeds all 7 databases for the travel-web platform
// Uses pg directly with raw SQL (no TypeScript/Prisma ORM deps needed)
// Each service has its own database, so cross-service references use UUID values.
// =============================================================================
const { Pool } = require('pg');

// ---------------------------------------------------------------------------
// DATABASE CONNECTIONS (one per service)
// ---------------------------------------------------------------------------
const BASE_URL = process.env.DATABASE_BASE_URL || 'postgresql://travel:travel123@localhost:5432';

function makePool(dbName) {
  const url = process.env[dbName.toUpperCase().replace(/-/g, '_') + '_DATABASE_URL']
    || BASE_URL + '/' + dbName + '?schema=public';
  return new Pool({ connectionString: url });
}

const pools = {
  auth:         makePool('auth_db'),
  booking:      makePool('booking_db'),
  room:         makePool('room_db'),
  payment:      makePool('payment_db'),
  review:       makePool('review_db'),
  notification: makePool('notification_db'),
  content:      makePool('content_db'),
  blog:         makePool('blog_db'),
};

// ---------------------------------------------------------------------------
// SEED DATA
// ---------------------------------------------------------------------------
var users = [
  { email: 'admin@travel.com', name: 'Admin User', role: 'ADMIN', phone: '0123456789', pass: 'admin123' },
  { email: 'manager@travel.com', name: 'Hotel Manager', role: 'ADMIN', phone: '0123456780', pass: 'manager123' },
  { email: 'customer@example.com', name: 'John Doe', role: 'CUSTOMER', phone: '0987654321', pass: 'customer123' },
  { email: 'nguyenvana@gmail.com', name: 'Nguyen Van A', role: 'CUSTOMER', phone: '0901234567', pass: 'password123' },
  { email: 'tranthib@gmail.com', name: 'Tran Thi B', role: 'CUSTOMER', phone: '0912345678', pass: 'password123' },
  { email: 'levanc@gmail.com', name: 'Le Van C', role: 'CUSTOMER', phone: '0923456789', pass: 'password123' },
  { email: 'phamthid@gmail.com', name: 'Pham Thi D', role: 'CUSTOMER', phone: '0934567890', pass: 'password123' },
  { email: 'hoangvane@gmail.com', name: 'Hoang Van E', role: 'CUSTOMER', phone: '0945678901', pass: 'password123' },
  { email: 'dangthif@gmail.com', name: 'Dang Thi F', role: 'CUSTOMER', phone: '0956789012', pass: 'password123' },
  { email: 'vuvang@gmail.com', name: 'Vu Van G', role: 'CUSTOMER', phone: '0967890123', pass: 'password123' },
];

var roomTypes = [
  {
    name: 'Standard Room', slug: 'standard-room',
    desc: 'Phong Standard tien nghi va am cung, phu hop cho khach du lich tiet kiem. Dien tich 25m2 voi day du tien nghi co ban.',
    price: 800000, capacity: 2, beds: 1, size: 25, featured: false,
    amenities: "ARRAY['Wifi mien phi','Dieu hoa','TV LED 42 inch','Minibar','Tu quan ao','May say toc','Ban lam viec']",
    images: "ARRAY['https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800','https://images.unsplash.com/photo-1631049552057-403cdb8f0658?w=800','https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?w=800']"
  },
  {
    name: 'Superior Room', slug: 'superior-room',
    desc: 'Phong Superior voi thiet ke sang trong hon. Dien tich 30m2, ban cong rieng voi view thanh pho dep.',
    price: 1200000, capacity: 2, beds: 1, size: 30, featured: false,
    amenities: "ARRAY['Wifi mien phi','Dieu hoa','TV 4K 50 inch','Mini Bar','Ket sat','Ban cong rieng','Ao choang tam']",
    images: "ARRAY['https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800','https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=800','https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800']"
  },
  {
    name: 'Deluxe Room', slug: 'deluxe-room',
    desc: 'Phong Deluxe sang trong voi view bien tuyet dep, dien tich rong rai 35m2.',
    price: 1500000, capacity: 2, beds: 1, size: 35, featured: true,
    amenities: "ARRAY['Wifi mien phi','Dieu hoa','TV 4K 55 inch','Mini Bar','Ket sat','Bon tam','View bien','Ca phe mien phi']",
    images: "ARRAY['https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800','https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800','https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800']"
  },
  {
    name: 'Deluxe Ocean View', slug: 'deluxe-ocean-view',
    desc: 'Phong Deluxe huong bien voi tam nhin panorama 180 do. Dien tich 40m2.',
    price: 2000000, capacity: 2, beds: 1, size: 40, featured: true,
    amenities: "ARRAY['Wifi mien phi','Dieu hoa','TV 4K 55 inch','Mini Bar cao cap','Ket sat','Bon tam dung','View bien panorama','Ban cong rong']",
    images: "ARRAY['https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800','https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800','https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800']"
  },
  {
    name: 'Suite Room', slug: 'suite-room',
    desc: 'Phong Suite cao cap voi khong gian rieng biet. Dien tich 50m2.',
    price: 2500000, capacity: 4, beds: 2, size: 50, featured: true,
    amenities: "ARRAY['Wifi mien phi','Dieu hoa','TV 4K 65 inch','Mini Bar','Ket sat','Bon tam Jacuzzi','Phong khach rieng']",
    images: "ARRAY['https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800','https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800','https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800']"
  },
  {
    name: 'Executive Suite', slug: 'executive-suite',
    desc: 'Executive Suite danh cho khach doanh nhan va VIP. Dien tich 65m2.',
    price: 3500000, capacity: 2, beds: 1, size: 65, featured: true,
    amenities: "ARRAY['Wifi mien phi','Dieu hoa','TV 4K 75 inch','Mini Bar cao cap','Phong tam spa','Phong lam viec rieng','May pha ca phe Nespresso']",
    images: "ARRAY['https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800','https://images.unsplash.com/photo-1591088398332-8a7791972843?w=800','https://images.unsplash.com/photo-1621293954908-907159247fc8?w=800']"
  },
  {
    name: 'Family Room', slug: 'family-room',
    desc: 'Phong Family rong rai thiet ke danh rieng cho gia dinh. Dien tich 55m2.',
    price: 2800000, capacity: 5, beds: 2, size: 55, featured: false,
    amenities: "ARRAY['Wifi mien phi','Dieu hoa','TV 4K 55 inch','Mini Bar','Khu vui choi tre em','Giuong phu','Noi em be']",
    images: "ARRAY['https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800','https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800','https://images.unsplash.com/photo-1584132915807-fd1f5fbc078f?w=800']"
  },
  {
    name: 'Presidential Suite', slug: 'presidential-suite',
    desc: 'Presidential Suite - dinh cao cua su sang trong. Dien tich 120m2.',
    price: 8000000, capacity: 4, beds: 2, size: 120, featured: true,
    amenities: "ARRAY['Wifi mien phi','Dieu hoa','TV 4K 85 inch','Bar rieng','Bon tam Jacuzzi doi','View bien 360 do','Butler 24/7','Spa tai phong']",
    images: "ARRAY['https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800','https://images.unsplash.com/photo-1591088398332-8a7791972843?w=800','https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800']"
  },
];

var heroImages = [
  { title: 'Kham Pha Thien Duong Nghi Duong', subtitle: 'Trai nghiem ky nghi hoan hao tai resort 5 sao', imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1920&h=600&fit=crop', buttonText: 'Dat Phong Ngay', buttonLink: '/rooms', order: 0 },
  { title: 'Khong Gian Sang Trong & Hien Dai', subtitle: 'Phong khach san dang cap voi tien nghi cao cap', imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1920&h=600&fit=crop', buttonText: 'Xem Cac Phong', buttonLink: '/rooms', order: 1 },
  { title: 'Uu Dai Dac Biet Mua He 2026', subtitle: 'Giam gia len den 30% cho dat phong tu 3 dem tro len', imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=1920&h=600&fit=crop', buttonText: 'Kham Pha Ngay', buttonLink: '/rooms', order: 2 },
  { title: 'Am Thuc Dang Cap 5 Sao', subtitle: 'Thuong thuc nhung mon an tinh hoa', imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1920&h=600&fit=crop', buttonText: 'Tim Hieu Them', buttonLink: '/rooms', order: 3 },
  { title: 'Spa & Wellness', subtitle: 'Thu gian toan dien voi lieu trinh spa doc quyen', imageUrl: 'https://images.unsplash.com/photo-1540541338287-41700207dee6?w=1920&h=600&fit=crop', buttonText: 'Dat Lich Ngay', buttonLink: '/rooms', order: 4 },
];

var bookingData = [
  { ci: '2026-01-05', co: '2026-01-08', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 2 },
  { ci: '2026-01-10', co: '2026-01-13', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 0 },
  { ci: '2026-01-15', co: '2026-01-18', guests: 4, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 4 },
  { ci: '2026-02-01', co: '2026-02-04', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 3 },
  { ci: '2026-02-05', co: '2026-02-08', guests: 1, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 1 },
  { ci: '2026-02-10', co: '2026-02-14', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 5 },
  { ci: '2026-02-15', co: '2026-02-17', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 2 },
  { ci: '2026-02-20', co: '2026-02-23', guests: 5, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 6 },
  { ci: '2026-03-01', co: '2026-03-04', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 7 },
  { ci: '2026-03-05', co: '2026-03-08', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 2 },
  { ci: '2026-03-10', co: '2026-03-13', guests: 1, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 0 },
  { ci: '2026-03-12', co: '2026-03-15', guests: 4, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 4 },
  { ci: '2026-04-05', co: '2026-04-08', guests: 2, status: 'PENDING', payment: 'UNPAID', method: null, typeIdx: 3 },
  { ci: '2026-04-10', co: '2026-04-13', guests: 3, status: 'PENDING', payment: 'UNPAID', method: null, typeIdx: 5 },
  { ci: '2026-01-20', co: '2026-01-22', guests: 2, status: 'CANCELLED', payment: 'REFUNDED', method: 'VNPAY', typeIdx: 1 },
  { ci: '2026-02-25', co: '2026-02-28', guests: 2, status: 'CANCELLED', payment: 'REFUNDED', method: 'VNPAY', typeIdx: 0 },
];

var reviewComments = [
  { rating: 5, comment: 'Phong dep, sach se, nhan vien than thien. Se quay lai lan sau!' },
  { rating: 4, comment: 'Phong rong rai va tien nghi. View dep. An sang co the da dang hon.' },
  { rating: 5, comment: 'Trai nghiem tuyet voi! Phong view bien rat dep, gia ca hop ly.' },
  { rating: 4, comment: 'Phong sach se, nhan vien nhiet tinh. Vi tri thuan tien.' },
  { rating: 5, comment: 'Ky nghi hoan hao! Moi thu deu tuyet voi tu phong den dich vu.' },
  { rating: 3, comment: 'Phong ok nhung cach am chua tot. Wifi hoi cham.' },
  { rating: 5, comment: 'Resort tuyet dep! Phong sang trong, an sang ngon, be boi dep.' },
  { rating: 4, comment: 'Phong dep va sach se. Doi nhan phong hoi lau.' },
  { rating: 5, comment: '5 sao xung dang! Moi chi tiet deu hoan hao.' },
  { rating: 4, comment: 'Phong dep, gia hop ly. Nhan vien nhiet tinh ho tro.' },
  { rating: 5, comment: 'Lan dau den day va rat an tuong. Phong rong dep day du tien nghi.' },
  { rating: 4, comment: 'Tong the rat tot. View cuc dep. Se quay lai!' },
];

// ---------------------------------------------------------------------------
// SEED FUNCTIONS — one per service database
// ---------------------------------------------------------------------------

async function seedAuth(client) {
  console.log('🔐 Seeding auth_db ...');
  await client.query('CREATE EXTENSION IF NOT EXISTS pgcrypto');

  var userIds = {};
  for (var u of users) {
    var hashRes = await client.query("SELECT crypt($1, gen_salt('bf', 10)) as hash", [u.pass]);
    var res = await client.query(
      'INSERT INTO users (id, email, name, password, role, phone, "createdAt", "updatedAt") ' +
      "VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, NOW(), NOW()) " +
      'ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name, password = EXCLUDED.password RETURNING id',
      [u.email, u.name, hashRes.rows[0].hash, u.role, u.phone]
    );
    userIds[u.email] = res.rows[0].id;
  }
  console.log('  ✅ ' + users.length + ' users');
  return userIds;
}

async function seedRoom(client) {
  console.log('🏨 Seeding room_db ...');

  var roomTypeIds = {};
  for (var rt of roomTypes) {
    var res = await client.query(
      'INSERT INTO room_types (id, name, slug, description, "pricePerNight", capacity, "bedCount", size, amenities, images, featured, available, "createdAt", "updatedAt") ' +
      'VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, ' + rt.amenities + ', ' + rt.images + ', $8, true, NOW(), NOW()) ' +
      'ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, ' +
      '"pricePerNight" = EXCLUDED."pricePerNight", capacity = EXCLUDED.capacity, "bedCount" = EXCLUDED."bedCount", ' +
      'size = EXCLUDED.size, amenities = EXCLUDED.amenities, images = EXCLUDED.images, featured = EXCLUDED.featured ' +
      'RETURNING id',
      [rt.name, rt.slug, rt.desc, rt.price, rt.capacity, rt.beds, rt.size, rt.featured]
    );
    roomTypeIds[rt.slug] = res.rows[0].id;
  }
  console.log('  ✅ ' + roomTypes.length + ' room types');

  // Physical rooms
  var roomConfig = [
    { slug: 'standard-room', prefix: '1', floor: 1, view: 'City View', count: 10 },
    { slug: 'superior-room', prefix: '2', floor: 2, view: 'Garden View', count: 8 },
    { slug: 'deluxe-room', prefix: '3', floor: 3, view: 'Sea View', count: 6 },
    { slug: 'deluxe-ocean-view', prefix: '4', floor: 4, view: 'Ocean Panorama', count: 5 },
    { slug: 'suite-room', prefix: '5', floor: 5, view: 'Sea View', count: 4 },
    { slug: 'executive-suite', prefix: '6', floor: 6, view: 'Sea View', count: 3 },
    { slug: 'family-room', prefix: '7', floor: 7, view: 'Garden View', count: 4 },
    { slug: 'presidential-suite', prefix: '8', floor: 8, view: 'Ocean 360', count: 2 },
  ];

  var allRoomIds = [];
  var roomCount = 0;
  for (var rc of roomConfig) {
    for (var i = 1; i <= rc.count; i++) {
      var roomNum = rc.prefix + (i < 10 ? '0' + i : '' + i);
      var res = await client.query(
        'INSERT INTO rooms (id, "roomNumber", "roomTypeId", floor, view, status, "createdAt", "updatedAt") ' +
        "VALUES (gen_random_uuid(), $1, $2, $3, $4, 'AVAILABLE', NOW(), NOW()) " +
        'ON CONFLICT ("roomNumber") DO UPDATE SET "roomTypeId" = EXCLUDED."roomTypeId", status = \'AVAILABLE\' RETURNING id',
        [roomNum, roomTypeIds[rc.slug], rc.floor, rc.view]
      );
      allRoomIds.push({ id: res.rows[0].id, typeSlug: rc.slug });
      roomCount++;
    }
  }
  console.log('  ✅ ' + roomCount + ' physical rooms');

  // Seasonal prices
  var seasonalPrices = [
    { type: 'deluxe-room', name: 'Tet Nguyen Dan 2026', start: '2026-01-28', end: '2026-02-03', price: 2500000 },
    { type: 'suite-room', name: 'Tet Nguyen Dan 2026', start: '2026-01-28', end: '2026-02-03', price: 4000000 },
    { type: 'presidential-suite', name: 'Tet Nguyen Dan 2026', start: '2026-01-28', end: '2026-02-03', price: 12000000 },
    { type: 'standard-room', name: 'Mua He 2026', start: '2026-06-01', end: '2026-08-31', price: 1000000 },
    { type: 'deluxe-room', name: 'Mua He 2026', start: '2026-06-01', end: '2026-08-31', price: 2000000 },
    { type: 'deluxe-ocean-view', name: 'Mua He 2026', start: '2026-06-01', end: '2026-08-31', price: 3000000 },
    { type: 'suite-room', name: 'Mua He 2026', start: '2026-06-01', end: '2026-08-31', price: 3500000 },
    { type: 'family-room', name: 'Mua He 2026', start: '2026-06-01', end: '2026-08-31', price: 3800000 },
  ];

  await client.query('DELETE FROM seasonal_prices');
  for (var sp of seasonalPrices) {
    await client.query(
      'INSERT INTO seasonal_prices (id, "roomTypeId", name, "startDate", "endDate", "pricePerNight", "createdAt") ' +
      'VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, NOW())',
      [roomTypeIds[sp.type], sp.name, sp.start, sp.end, sp.price]
    );
  }
  console.log('  ✅ ' + seasonalPrices.length + ' seasonal prices');

  return { roomTypeIds, allRoomIds };
}

async function seedContent(client) {
  console.log('📝 Seeding content_db ...');

  await client.query('DELETE FROM hero_images');
  for (var hi of heroImages) {
    await client.query(
      'INSERT INTO hero_images (id, title, subtitle, "imageUrl", "buttonText", "buttonLink", "order", active, "createdAt", "updatedAt") ' +
      'VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, true, NOW(), NOW())',
      [hi.title, hi.subtitle, hi.imageUrl, hi.buttonText, hi.buttonLink, hi.order]
    );
  }
  console.log('  ✅ ' + heroImages.length + ' hero images');

  // Settings
  var settings = [
    { key: 'site_name', value: 'TravelBook - He Thong Dat Phong Khach San' },
    { key: 'site_description', value: 'He thong dat phong khach san truc tuyen hang dau Viet Nam' },
    { key: 'contact_email', value: 'contact@travelbook.vn' },
    { key: 'contact_phone', value: '1900 1234' },
    { key: 'address', value: '123 Tran Phu, Nha Trang, Khanh Hoa' },
    { key: 'currency', value: 'VND' },
    { key: 'timezone', value: 'Asia/Ho_Chi_Minh' },
    { key: 'check_in_time', value: '14:00' },
    { key: 'check_out_time', value: '12:00' },
    { key: 'max_booking_days', value: '30' },
    { key: 'cancellation_hours', value: '24' },
  ];

  for (var s of settings) {
    await client.query(
      'INSERT INTO settings (id, key, value, "updatedAt") ' +
      'VALUES (gen_random_uuid(), $1, $2, NOW()) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value',
      [s.key, s.value]
    );
  }
  console.log('  ✅ ' + settings.length + ' settings');
}

async function seedBooking(client, userIds, roomData) {
  console.log('📅 Seeding booking_db ...');

  await client.query('DELETE FROM bookings');

  var customerEmails = ['customer@example.com', 'nguyenvana@gmail.com', 'tranthib@gmail.com',
    'levanc@gmail.com', 'phamthid@gmail.com', 'hoangvane@gmail.com',
    'dangthif@gmail.com', 'vuvang@gmail.com'];

  var rtSlugs = ['standard-room', 'superior-room', 'deluxe-room', 'deluxe-ocean-view',
    'suite-room', 'executive-suite', 'family-room', 'presidential-suite'];

  var bookingIds = [];
  for (var bi = 0; bi < bookingData.length; bi++) {
    var b = bookingData[bi];
    var custEmail = customerEmails[bi % customerEmails.length];
    var custId = userIds[custEmail];
    var rtSlug = rtSlugs[b.typeIdx];
    var roomOfType = roomData.allRoomIds.filter(function (r) { return r.typeSlug === rtSlug; });
    var roomId = roomOfType[bi % roomOfType.length].id;
    var nights = Math.round((new Date(b.co) - new Date(b.ci)) / 86400000);
    var totalPrice = roomTypes[b.typeIdx].price * nights;
    var payRef = b.payment === 'PAID' || b.payment === 'REFUNDED' ? 'pay_' + Math.random().toString(36).substr(2, 12) : null;
    var paidAt = b.payment === 'PAID' ? b.ci : null;

    var res = await client.query(
      'INSERT INTO bookings (id, "userId", "roomId", "checkIn", "checkOut", "numberOfGuests", "totalPrice", status, ' +
      '"paymentMethod", "paymentRef", "paymentStatus", "paidAt", "createdAt", "updatedAt") ' +
      'VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW()) RETURNING id',
      [custId, roomId, b.ci, b.co, b.guests, totalPrice, b.status, b.method, payRef, b.payment, paidAt]
    );
    bookingIds.push({ id: res.rows[0].id, custId: custId, typeSlug: rtSlug, status: b.status, payment: b.payment });
  }
  console.log('  ✅ ' + bookingData.length + ' bookings');
  return bookingIds;
}

async function seedReview(client, bookingIds, roomTypeIds) {
  console.log('⭐ Seeding review_db ...');

  await client.query('DELETE FROM reviews');

  var confirmedPaid = bookingIds.filter(function (b) { return b.status === 'CONFIRMED' && b.payment === 'PAID'; });
  var count = 0;
  for (var ri = 0; ri < Math.min(confirmedPaid.length, reviewComments.length); ri++) {
    var bk = confirmedPaid[ri];
    var rv = reviewComments[ri];
    await client.query(
      'INSERT INTO reviews (id, rating, comment, "userId", "bookingId", "roomTypeId", "createdAt", "updatedAt") ' +
      'VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, NOW(), NOW())',
      [rv.rating, rv.comment, bk.custId, bk.id, roomTypeIds[bk.typeSlug]]
    );
    count++;
  }
  console.log('  ✅ ' + count + ' reviews');
}

async function seedBlog(client) {
  console.log('📰 Seeding blog_db ...');

  var posts = [
    { title: 'Top 10 Dia Diem Du Lich Viet Nam 2026', slug: 'top-10-dia-diem-2026', content: 'Kham pha nhung dia diem du lich hap dan nhat Viet Nam trong nam 2026...', published: true },
    { title: 'Huong Dan Dat Phong Khach San Online', slug: 'huong-dan-dat-phong', content: 'Meo dat phong khach san truc tuyen de co gia tot nhat...', published: true },
    { title: 'Am Thuc Nha Trang Khong The Bo Qua', slug: 'am-thuc-nha-trang', content: 'Nhung mon an dac san Nha Trang ban nen thu khi di du lich...', published: true },
  ];

  for (var p of posts) {
    await client.query(
      'INSERT INTO posts (id, title, slug, content, published, "createdAt", "updatedAt") ' +
      'VALUES (gen_random_uuid(), $1, $2, $3, $4, NOW(), NOW()) ON CONFLICT (slug) DO NOTHING',
      [p.title, p.slug, p.content, p.published]
    );
  }
  console.log('  ✅ ' + posts.length + ' blog posts');
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
async function main() {
  var clients = {};
  try {
    console.log('🌱 Starting microservice seed across 7 databases...\n');

    // Acquire connections
    for (var key of Object.keys(pools)) {
      clients[key] = await pools[key].connect();
    }

    // 1. Auth (must be first — provides userIds)
    var userIds = await seedAuth(clients.auth);

    // 2. Room (provides roomTypeIds + allRoomIds)
    var roomData = await seedRoom(clients.room);

    // 3. Content (hero images + settings)
    await seedContent(clients.content);

    // 4. Booking (needs userIds + roomData)
    var bookingIds = await seedBooking(clients.booking, userIds, roomData);

    // 5. Review (needs bookingIds + roomTypeIds)
    await seedReview(clients.review, bookingIds, roomData.roomTypeIds);

    // 6. Blog
    await seedBlog(clients.blog);

    // Done
    console.log('\n==============================================');
    console.log('🎉 MICROSERVICE SEED COMPLETED SUCCESSFULLY!');
    console.log('==============================================');
    console.log('📊 Data summary:');
    console.log('  auth_db:         ' + users.length + ' users');
    console.log('  room_db:         ' + roomTypes.length + ' room types + rooms + seasonal prices');
    console.log('  content_db:      ' + heroImages.length + ' hero images + settings');
    console.log('  booking_db:      ' + bookingData.length + ' bookings');
    console.log('  review_db:       reviews for paid bookings');
    console.log('  blog_db:         3 blog posts');
    console.log('  notification_db: (empty — populated at runtime)');
    console.log('  payment_db:      (empty — populated at runtime via VNPay)');
    console.log('');
    console.log('📝 Login credentials:');
    console.log('  Admin:    admin@travel.com / admin123');
    console.log('  Manager:  manager@travel.com / manager123');
    console.log('  Customer: customer@example.com / customer123');

  } catch (err) {
    console.error('❌ Error during seeding:', err);
    process.exit(1);
  } finally {
    for (var key of Object.keys(clients)) {
      if (clients[key]) clients[key].release();
    }
    for (var key of Object.keys(pools)) {
      await pools[key].end();
    }
  }
}

main();
