/* =========================================================
   07_test_queries.sql
   Test Queries - Requirement Based Queries
   ========================================================= */

SET NOCOUNT ON;

-- =========================================================
-- 1) Kalkış ve varışa göre uçuş listeleme (Guest User)
-- =========================================================
SELECT
    f.flight_number,
    a1.city AS departure_city,
    a2.city AS arrival_city,
    f.departure_time,
    f.arrival_time
FROM Flights f
JOIN Airports a1 ON f.departure_airport_id = a1.airport_id
JOIN Airports a2 ON f.arrival_airport_id = a2.airport_id
WHERE a1.city = 'İstanbul'
  AND a2.city = 'Elazığ';


-- =========================================================
-- 2) Bir uçuşta satılan koltuklar (Seat occupancy)
-- =========================================================
SELECT
    s.seat_number,
    s.seat_class,
    t.ticket_status
FROM Tickets t
JOIN Seats s ON t.seat_id = s.seat_id
WHERE t.flight_id = 1;


-- =========================================================
-- 3) Üye yolcunun bilet ve paket bilgileri
-- =========================================================
SELECT
    m.first_name,
    m.last_name,
    t.pnr,
    fp.package_name,
    t.price_paid,
    t.ticket_status
FROM Members m
JOIN Tickets t ON m.member_id = t.member_id
JOIN FarePackages fp ON t.package_id = fp.package_id
WHERE m.member_id = 1;


-- =========================================================
-- 4) Paketlere göre bagaj hakları
-- =========================================================
SELECT
    package_name,
    baggage_allowance_kg,
    seat_selection_policy
FROM FarePackages;


-- =========================================================
-- 5) Bir uçuşun durum geçmişi (Flight Status History)
-- =========================================================
SELECT
    f.flight_number,
    fs.status,
    fs.delay_minutes,
    fs.reason,
    fs.updated_at
FROM Flight_Status fs
JOIN Flights f ON fs.flight_id = f.flight_id
WHERE f.flight_id = 1
ORDER BY fs.updated_at;


-- =========================================================
-- 6) Üyenin puan hareketleri (Audit)
-- =========================================================
SELECT
    m.first_name,
    m.last_name,
    mpt.txn_time,
    mpt.txn_type,
    mpt.points,
    mpt.description
FROM MemberPointsTransactions mpt
JOIN Members m ON mpt.member_id = m.member_id
WHERE m.member_id = 1
ORDER BY mpt.txn_time DESC;


-- =========================================================
-- 7) Check-in yapılmış biletler ve boarding pass bilgileri
-- =========================================================
SELECT
    t.pnr,
    bp.token,
    bp.issued_at
FROM CheckIns c
JOIN Tickets t ON c.ticket_id = t.ticket_id
JOIN BoardingPasses bp ON bp.ticket_id = t.ticket_id;


-- =========================================================
-- 8) Ekstra bagaj satın alan yolcular
-- =========================================================
SELECT
    t.pnr,
    eb.extra_kg,
    eb.price,
    eb.purchased_at
FROM ExtraBaggagePurchases eb
JOIN Tickets t ON eb.ticket_id = t.ticket_id;


-- =========================================================
-- 9) İptal edilen biletler ve iade tutarları
-- =========================================================
SELECT
    t.pnr,
    ct.refund_amount,
    ct.cancelled_at
FROM Cancelled_Tickets ct
JOIN Tickets t ON ct.ticket_id = t.ticket_id;


-- =========================================================
-- 10) Uçuş bazında mürettebat listesi
-- =========================================================
SELECT
    f.flight_number,
    c.name,
    c.surname,
    c.role
FROM Flight_Crew fc
JOIN Crew c ON fc.crew_id = c.crew_id
JOIN Flights f ON fc.flight_id = f.flight_id
WHERE f.flight_id = 1;
