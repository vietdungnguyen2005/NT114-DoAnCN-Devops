// Comprehensive seed script for Travel Web - full data for all pages
// Uses pg directly with raw SQL (no TypeScript/Prisma ORM deps needed)
// Table names: snake_case (@@map in Prisma), Column names: camelCase
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function main() {
  const client = await pool.connect();
  
  try {
    console.log('🌱 Starting FULL seed...');
    
    // Enable pgcrypto for bcrypt password hashing
    await client.query('CREATE EXTENSION IF NOT EXISTS pgcrypto');
    console.log('✅ pgcrypto extension enabled');

    // ============================================================
    // 1. USERS (Admin + Multiple Customers)
    // ============================================================
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
    console.log('✅ Created ' + users.length + ' users');

    // ============================================================
    // 2. ROOM TYPES (8 diverse room types)
    // ============================================================
    var roomTypes = [
      {
        name: 'Standard Room', slug: 'standard-room',
        desc: 'Phong Standard tien nghi va am cung, phu hop cho khach du lich tiet kiem. Dien tich 25m2 voi day du tien nghi co ban, wifi toc do cao va dich vu don phong hang ngay.',
        price: 800000, capacity: 2, beds: 1, size: 25, featured: false,
        amenities: "ARRAY['Wifi mien phi', 'Dieu hoa', 'TV LED 42 inch', 'Minibar', 'Tu quan ao', 'May say toc', 'Ban lam viec']",
        images: "ARRAY['https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800', 'https://images.unsplash.com/photo-1631049552057-403cdb8f0658?w=800', 'https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?w=800']"
      },
      {
        name: 'Superior Room', slug: 'superior-room',
        desc: 'Phong Superior voi thiet ke sang trong hon phong Standard. Dien tich 30m2, ban cong rieng voi view thanh pho dep, noi that hien dai va tien nghi nang cap.',
        price: 1200000, capacity: 2, beds: 1, size: 30, featured: false,
        amenities: "ARRAY['Wifi mien phi', 'Dieu hoa', 'TV 4K 50 inch', 'Mini Bar', 'Ket sat', 'Ban cong rieng', 'Ao choang tam', 'Do dung ve sinh cao cap']",
        images: "ARRAY['https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800', 'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=800', 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800']"
      },
      {
        name: 'Deluxe Room', slug: 'deluxe-room',
        desc: 'Phong Deluxe sang trong voi view bien tuyet dep, dien tich rong rai 35m2, thiet ke hien dai va day du tien nghi cao cap. Ly tuong cho cac cap doi va ky nghi lang man.',
        price: 1500000, capacity: 2, beds: 1, size: 35, featured: true,
        amenities: "ARRAY['Wifi mien phi', 'Dieu hoa', 'TV 4K 55 inch', 'Mini Bar', 'Ket sat', 'Bon tam', 'View bien', 'Dich vu phong VIP', 'Ca phe mien phi']",
        images: "ARRAY['https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800', 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800', 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800']"
      },
      {
        name: 'Deluxe Ocean View', slug: 'deluxe-ocean-view',
        desc: 'Phong Deluxe huong bien voi tam nhin panorama 180 do ra Vinh Ha Long. Dien tich 40m2 voi ban cong rong, noi that go tu nhien va tien nghi dang cap 5 sao.',
        price: 2000000, capacity: 2, beds: 1, size: 40, featured: true,
        amenities: "ARRAY['Wifi mien phi', 'Dieu hoa', 'TV 4K 55 inch', 'Mini Bar cao cap', 'Ket sat', 'Bon tam dung', 'View bien panorama', 'Ban cong rong', 'Dich vu butler', 'Tra va ca phe mien phi']",
        images: "ARRAY['https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800', 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800', 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800']"
      },
      {
        name: 'Suite Room', slug: 'suite-room',
        desc: 'Phong Suite cao cap voi khong gian rieng biet, phong khach rong rai, phong ngu sang trong. Dien tich 50m2 voi day du tien nghi 5 sao. Hoan hao cho gia dinh va nhom ban.',
        price: 2500000, capacity: 4, beds: 2, size: 50, featured: true,
        amenities: "ARRAY['Wifi mien phi', 'Dieu hoa', 'TV 4K 65 inch', 'Mini Bar', 'Ket sat', 'Bon tam Jacuzzi', 'View bien', 'Phong khach rieng', 'Ban an 4 nguoi', 'Bep nho']",
        images: "ARRAY['https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800', 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800', 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800']"
      },
      {
        name: 'Executive Suite', slug: 'executive-suite',
        desc: 'Executive Suite danh cho khach doanh nhan va VIP. Dien tich 65m2 voi phong lam viec rieng, phong khach lon, phong ngu master va phong tam spa rieng.',
        price: 3500000, capacity: 2, beds: 1, size: 65, featured: true,
        amenities: "ARRAY['Wifi mien phi', 'Dieu hoa', 'TV 4K 75 inch', 'Mini Bar cao cap', 'Ket sat lon', 'Phong tam spa', 'View bien', 'Phong lam viec rieng', 'May pha ca phe Nespresso', 'Dich vu di don san bay']",
        images: "ARRAY['https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800', 'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=800', 'https://images.unsplash.com/photo-1621293954908-907159247fc8?w=800']"
      },
      {
        name: 'Family Room', slug: 'family-room',
        desc: 'Phong Family rong rai thiet ke danh rieng cho gia dinh co tre nho. Dien tich 55m2 voi 2 giuong, khu vui choi tre em, va cac tien nghi than thien voi tre.',
        price: 2800000, capacity: 5, beds: 2, size: 55, featured: false,
        amenities: "ARRAY['Wifi mien phi', 'Dieu hoa', 'TV 4K 55 inch', 'Mini Bar', 'Ket sat', 'Bon tam', 'Khu vui choi tre em', 'Giuong phu', 'Noi em be', 'Ban ghe tre em']",
        images: "ARRAY['https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800', 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800', 'https://images.unsplash.com/photo-1584132915807-fd1f5fbc078f?w=800']"
      },
      {
        name: 'Presidential Suite', slug: 'presidential-suite',
        desc: 'Presidential Suite - dinh cao cua su sang trong. Dien tich 120m2 voi 2 phong ngu, phong khach lon, phong an rieng, ban cong bao quanh va dich vu butler 24/7.',
        price: 8000000, capacity: 4, beds: 2, size: 120, featured: true,
        amenities: "ARRAY['Wifi mien phi', 'Dieu hoa', 'TV 4K 85 inch', 'Bar rieng', 'Ket sat lon', 'Bon tam Jacuzzi doi', 'View bien 360 do', 'Phong khach lon', 'Phong an rieng', 'Butler 24/7', 'Xe dua don rieng', 'Spa tai phong']",
        images: "ARRAY['https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800', 'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=800', 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800', 'https://images.unsplash.com/photo-1621293954908-907159247fc8?w=800']"
      },
    ];

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
    console.log('✅ Created ' + roomTypes.length + ' room types');

    // ============================================================
    // 3. PHYSICAL ROOMS (42 rooms across all types)
    // ============================================================
    var roomCount = 0;
    var allRoomIds = [];
    
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
    console.log('✅ Created ' + roomCount + ' physical rooms');

    // ============================================================
    // 4. HERO IMAGES (Homepage carousel)
    // ============================================================
    await client.query('DELETE FROM hero_images');
    
    var heroImages = [
      {
        title: 'Kham Pha Thien Duong Nghi Duong',
        subtitle: 'Trai nghiem ky nghi hoan hao tai resort 5 sao voi view bien tuyet dep',
        imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1920&h=600&fit=crop',
        buttonText: 'Dat Phong Ngay', buttonLink: '/rooms', order: 0
      },
      {
        title: 'Khong Gian Sang Trong & Hien Dai',
        subtitle: 'Phong khach san dang cap voi day du tien nghi cao cap',
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1920&h=600&fit=crop',
        buttonText: 'Xem Cac Phong', buttonLink: '/rooms', order: 1
      },
      {
        title: 'Uu Dai Dac Biet Mua He 2026',
        subtitle: 'Giam gia len den 30% cho dat phong tu 3 dem tro len',
        imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=1920&h=600&fit=crop',
        buttonText: 'Kham Pha Ngay', buttonLink: '/rooms', order: 2
      },
      {
        title: 'Am Thuc Dang Cap 5 Sao',
        subtitle: 'Thuong thuc nhung mon an tinh hoa tu dau bep hang dau',
        imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1920&h=600&fit=crop',
        buttonText: 'Tim Hieu Them', buttonLink: '/rooms', order: 3
      },
      {
        title: 'Spa & Wellness',
        subtitle: 'Thu gian toan dien voi lieu trinh spa doc quyen',
        imageUrl: 'https://images.unsplash.com/photo-1540541338287-41700207dee6?w=1920&h=600&fit=crop',
        buttonText: 'Dat Lich Ngay', buttonLink: '/rooms', order: 4
      },
    ];

    for (var hi of heroImages) {
      await client.query(
        'INSERT INTO hero_images (id, title, subtitle, "imageUrl", "buttonText", "buttonLink", "order", active, "createdAt", "updatedAt") ' +
        'VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, true, NOW(), NOW())',
        [hi.title, hi.subtitle, hi.imageUrl, hi.buttonText, hi.buttonLink, hi.order]
      );
    }
    console.log('✅ Created ' + heroImages.length + ' hero images');

    // ============================================================
    // 5. SEASONAL PRICES (comprehensive pricing)
    // ============================================================
    await client.query('DELETE FROM seasonal_prices');

    var seasonalPrices = [
      // Tet
      { type: 'deluxe-room', name: 'Tet Nguyen Dan 2026', start: '2026-01-28', end: '2026-02-03', price: 2500000 },
      { type: 'suite-room', name: 'Tet Nguyen Dan 2026', start: '2026-01-28', end: '2026-02-03', price: 4000000 },
      { type: 'presidential-suite', name: 'Tet Nguyen Dan 2026', start: '2026-01-28', end: '2026-02-03', price: 12000000 },
      // Summer peak season
      { type: 'standard-room', name: 'Mua He 2026', start: '2026-06-01', end: '2026-08-31', price: 1000000 },
      { type: 'deluxe-room', name: 'Mua He 2026', start: '2026-06-01', end: '2026-08-31', price: 2000000 },
      { type: 'deluxe-ocean-view', name: 'Mua He 2026', start: '2026-06-01', end: '2026-08-31', price: 3000000 },
      { type: 'suite-room', name: 'Mua He 2026', start: '2026-06-01', end: '2026-08-31', price: 3500000 },
      { type: 'family-room', name: 'Mua He 2026', start: '2026-06-01', end: '2026-08-31', price: 3800000 },
      // Christmas
      { type: 'deluxe-room', name: 'Giang Sinh 2025', start: '2025-12-23', end: '2025-12-26', price: 2200000 },
      { type: 'executive-suite', name: 'Giang Sinh 2025', start: '2025-12-23', end: '2025-12-26', price: 5000000 },
      // New Year
      { type: 'suite-room', name: 'Nam Moi 2026', start: '2025-12-31', end: '2026-01-02', price: 5000000 },
      { type: 'presidential-suite', name: 'Nam Moi 2026', start: '2025-12-31', end: '2026-01-02', price: 15000000 },
      // 30/4 - 1/5
      { type: 'deluxe-room', name: 'Le 30/4 - 1/5', start: '2026-04-29', end: '2026-05-02', price: 2200000 },
      { type: 'suite-room', name: 'Le 30/4 - 1/5', start: '2026-04-29', end: '2026-05-02', price: 3800000 },
      { type: 'family-room', name: 'Le 30/4 - 1/5', start: '2026-04-29', end: '2026-05-02', price: 3500000 },
    ];

    for (var sp of seasonalPrices) {
      await client.query(
        'INSERT INTO seasonal_prices (id, "roomTypeId", name, "startDate", "endDate", "pricePerNight", "createdAt") ' +
        'VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, NOW())',
        [roomTypeIds[sp.type], sp.name, sp.start, sp.end, sp.price]
      );
    }
    console.log('✅ Created ' + seasonalPrices.length + ' seasonal pricing rules');

    // ============================================================
    // 6. BOOKINGS (sample bookings with various statuses)
    // ============================================================
    // Clear existing reviews and bookings first (reviews depend on bookings)
    await client.query('DELETE FROM reviews');
    await client.query('DELETE FROM bookings');
    
    var customerEmails = ['customer@example.com', 'nguyenvana@gmail.com', 'tranthib@gmail.com', 
                          'levanc@gmail.com', 'phamthid@gmail.com', 'hoangvane@gmail.com', 
                          'dangthif@gmail.com', 'vuvang@gmail.com'];
    
    var bookingData = [
      // Completed past bookings (for reviews + revenue analytics)
      { ci: '2026-01-05', co: '2026-01-08', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'STRIPE', typeIdx: 2 },
      { ci: '2026-01-10', co: '2026-01-13', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 0 },
      { ci: '2026-01-15', co: '2026-01-18', guests: 4, status: 'CONFIRMED', payment: 'PAID', method: 'STRIPE', typeIdx: 4 },
      { ci: '2026-02-01', co: '2026-02-04', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'MOMO', typeIdx: 3 },
      { ci: '2026-02-05', co: '2026-02-08', guests: 1, status: 'CONFIRMED', payment: 'PAID', method: 'STRIPE', typeIdx: 1 },
      { ci: '2026-02-10', co: '2026-02-14', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 5 },
      { ci: '2026-02-15', co: '2026-02-17', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'STRIPE', typeIdx: 2 },
      { ci: '2026-02-20', co: '2026-02-23', guests: 5, status: 'CONFIRMED', payment: 'PAID', method: 'MOMO', typeIdx: 6 },
      { ci: '2026-03-01', co: '2026-03-04', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'STRIPE', typeIdx: 7 },
      { ci: '2026-03-05', co: '2026-03-08', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 2 },
      { ci: '2026-03-10', co: '2026-03-13', guests: 1, status: 'CONFIRMED', payment: 'PAID', method: 'STRIPE', typeIdx: 0 },
      { ci: '2026-03-12', co: '2026-03-15', guests: 4, status: 'CONFIRMED', payment: 'PAID', method: 'STRIPE', typeIdx: 4 },
      { ci: '2026-03-14', co: '2026-03-17', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 1 },
      { ci: '2026-03-16', co: '2026-03-19', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'MOMO', typeIdx: 3 },
      { ci: '2026-03-18', co: '2026-03-21', guests: 5, status: 'CONFIRMED', payment: 'PAID', method: 'STRIPE', typeIdx: 6 },
      // Upcoming bookings
      { ci: '2026-03-25', co: '2026-03-28', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'STRIPE', typeIdx: 2 },
      { ci: '2026-03-26', co: '2026-03-30', guests: 4, status: 'CONFIRMED', payment: 'PAID', method: 'VNPAY', typeIdx: 4 },
      { ci: '2026-04-01', co: '2026-04-05', guests: 2, status: 'CONFIRMED', payment: 'PAID', method: 'STRIPE', typeIdx: 5 },
      { ci: '2026-04-05', co: '2026-04-08', guests: 2, status: 'PENDING', payment: 'UNPAID', method: null, typeIdx: 3 },
      { ci: '2026-04-10', co: '2026-04-13', guests: 3, status: 'PENDING', payment: 'UNPAID', method: null, typeIdx: 5 },
      { ci: '2026-04-15', co: '2026-04-18', guests: 2, status: 'PENDING', payment: 'UNPAID', method: null, typeIdx: 7 },
      // Cancelled bookings
      { ci: '2026-01-20', co: '2026-01-22', guests: 2, status: 'CANCELLED', payment: 'REFUNDED', method: 'STRIPE', typeIdx: 1 },
      { ci: '2026-02-25', co: '2026-02-28', guests: 2, status: 'CANCELLED', payment: 'REFUNDED', method: 'VNPAY', typeIdx: 0 },
      { ci: '2026-03-20', co: '2026-03-23', guests: 4, status: 'CANCELLED', payment: 'REFUNDED', method: 'MOMO', typeIdx: 4 },
    ];

    var bookingIds = [];
    var rtSlugs = ['standard-room', 'superior-room', 'deluxe-room', 'deluxe-ocean-view', 
                   'suite-room', 'executive-suite', 'family-room', 'presidential-suite'];
    
    for (var bi = 0; bi < bookingData.length; bi++) {
      var b = bookingData[bi];
      var custEmail = customerEmails[bi % customerEmails.length];
      var custId = userIds[custEmail];
      var rtSlug = rtSlugs[b.typeIdx];
      // Find a room of this type
      var roomOfType = allRoomIds.filter(function(r) { return r.typeSlug === rtSlug; });
      var roomId = roomOfType[bi % roomOfType.length].id;
      
      var nights = Math.round((new Date(b.co) - new Date(b.ci)) / 86400000);
      var rtData = roomTypes[b.typeIdx];
      var totalPrice = rtData.price * nights;
      
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
    console.log('✅ Created ' + bookingData.length + ' bookings');

    // ============================================================
    // 7. REVIEWS (for completed paid bookings)
    // ============================================================
    var reviewComments = [
      { rating: 5, comment: 'Phong dep, sach se, nhan vien than thien. Dich vu tuyet voi, se quay lai lan sau!' },
      { rating: 4, comment: 'Phong rong rai va tien nghi. View dep. Chi co dieu an sang co the da dang hon.' },
      { rating: 5, comment: 'Trai nghiem tuyet voi! Phong view bien rat dep, gia ca hop ly. Rat hai long!' },
      { rating: 4, comment: 'Phong sach se, nhan vien nhiet tinh. Vi tri thuan tien. Se gioi thieu ban be.' },
      { rating: 5, comment: 'Ky nghi hoan hao! Moi thu deu tuyet voi tu phong den dich vu. 10/10!' },
      { rating: 3, comment: 'Phong ok, nhung cach am chua tot lam. Wifi hoi cham. Tuy nhien nhan vien rat tot.' },
      { rating: 5, comment: 'Resort tuyet dep! Phong sang trong, an sang ngon, be boi dep. Se tro lai!' },
      { rating: 4, comment: 'Phong dep va sach se. Diem tru duy nhat la doi nhan phong hoi lau.' },
      { rating: 5, comment: '5 sao xung dang! Moi chi tiet deu hoan hao. Cam on doi ngu khach san!' },
      { rating: 4, comment: 'Phong dep, gia hop ly. Nhan vien nhiet tinh ho tro. Rat dang de o.' },
      { rating: 5, comment: 'Lan dau den day va rat an tuong. Phong rong, dep, day du tien nghi.' },
      { rating: 4, comment: 'Tong the rat tot. Phong dep, view cuc dep. An sang ngon. Se quay lai!' },
      { rating: 5, comment: 'Dich vu cham soc khach hang tuyet voi. Phong sach se, view bien dep me ly.' },
      { rating: 3, comment: 'Phong dep nhung gia hoi cao so voi khu vuc. Tuy nhien chat luong dich vu tot.' },
      { rating: 5, comment: 'Trai nghiem nghi duong tuyet voi nhat tung co! Se chac chan quay tro lai.' },
    ];

    var reviewCount = 0;
    var confirmedPaidBookings = bookingIds.filter(function(b) { return b.status === 'CONFIRMED' && b.payment === 'PAID'; });
    
    for (var ri = 0; ri < Math.min(confirmedPaidBookings.length, reviewComments.length); ri++) {
      var bk = confirmedPaidBookings[ri];
      var rv = reviewComments[ri];
      await client.query(
        'INSERT INTO reviews (id, rating, comment, "userId", "bookingId", "roomTypeId", "createdAt", "updatedAt") ' +
        'VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, NOW(), NOW())',
        [rv.rating, rv.comment, bk.custId, bk.id, roomTypeIds[bk.typeSlug]]
      );
      reviewCount++;
    }
    console.log('✅ Created ' + reviewCount + ' reviews');

    // ============================================================
    // 8. SETTINGS (comprehensive hotel settings)
    // ============================================================
    var settings = [
      { key: 'site_name', value: 'TravelBook - He Thong Dat Phong Khach San' },
      { key: 'site_description', value: 'He thong dat phong khach san truc tuyen hang dau Viet Nam' },
      { key: 'booking_hold_minutes', value: '15' },
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
        'VALUES (gen_random_uuid(), $1, $2, NOW()) ' +
        'ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value',
        [s.key, s.value]
      );
    }
    console.log('✅ Created ' + settings.length + ' settings');

    // ============================================================
    // SUMMARY
    // ============================================================
    console.log('');
    console.log('==============================================');
    console.log('🎉 FULL SEED COMPLETED SUCCESSFULLY!');
    console.log('==============================================');
    console.log('📊 Data summary:');
    console.log('  - Users:           ' + users.length + ' (2 admin, ' + (users.length - 2) + ' customers)');
    console.log('  - Room Types:      ' + roomTypes.length);
    console.log('  - Physical Rooms:  ' + roomCount);
    console.log('  - Hero Images:     ' + heroImages.length);
    console.log('  - Seasonal Prices: ' + seasonalPrices.length);
    console.log('  - Bookings:        ' + bookingData.length);
    console.log('  - Reviews:         ' + reviewCount);
    console.log('  - Settings:        ' + settings.length);
    console.log('');
    console.log('📝 Login credentials:');
    console.log('  Admin:    admin@travel.com / admin123');
    console.log('  Manager:  manager@travel.com / manager123');
    console.log('  Customer: customer@example.com / customer123');
    console.log('  (All other customers: password123)');

  } catch (err) {
    console.error('❌ Error during seeding:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

main();
