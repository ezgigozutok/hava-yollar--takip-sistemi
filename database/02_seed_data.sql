/* =========================================================
   SEED DATA (Demo/Test Records)
   Works with: schema + procedures + triggers + transactions
   ========================================================= */

SET NOCOUNT ON;

-- =========================
-- 1) AIRLINES
-- =========================
INSERT INTO Airlines(name, country)
VALUES ('Turkish Airlines', 'Türkiye');

-- =========================
-- 2) AIRPORTS
-- =========================
INSERT INTO Airports(name, city, country)
VALUES
('İstanbul Airport (IST)', 'İstanbul', 'Türkiye'),
('Elazığ Airport (EZS)', 'Elazığ', 'Türkiye'),
('Ankara Esenboğa (ESB)', 'Ankara', 'Türkiye');

-- =========================
-- 3) AIRPLANES
-- =========================
INSERT INTO Airplanes(model, capacity, airline_id)
VALUES
('Airbus A320', 180, 1);

-- =========================
-- 4) FLIGHTS
-- =========================
-- Not: departure_time gelecekte olmalı ki iptal testi çalışsın
INSERT INTO Flights(flight_number, departure_time, arrival_time, airplane_id, departure_airport_id, arrival_airport_id)
VALUES
('TK1001', DATEADD(DAY, 2, GETDATE()), DATEADD(DAY, 2, DATEADD(HOUR, 2, GETDATE())), 1, 1, 2), -- IST -> EZS
('TK2002', DATEADD(DAY, 5, GETDATE()), DATEADD(DAY, 5, DATEADD(HOUR, 1, GETDATE())), 1, 1, 3); -- IST -> ESB

-- =========================
-- 5) SEATS (for the airplane)
-- =========================
-- Basit bir koltuk seti (1A,1B,1C,1D,2A,2B,2C,2D)
INSERT INTO Seats(airplane_id, seat_number, seat_class, is_window)
VALUES
(1, '1A', 'Business', 1),
(1, '1B', 'Business', 0),
(1, '1C', 'Business', 0),
(1, '1D', 'Business', 1),
(1, '2A', 'Economy', 1),
(1, '2B', 'Economy', 0),
(1, '2C', 'Economy', 0),
(1, '2D', 'Economy', 1);

-- =========================
-- 6) PASSENGERS
-- =========================
INSERT INTO Passengers(name, surname, passport_number)
VALUES
('Ezgi', 'Gozutok', 'P12345678'),
('Gul', 'Example', 'P87654321');

-- =========================
-- 7) MEMBERS
-- =========================
INSERT INTO Members(first_name, last_name, phone_no, email, points)
VALUES
('Ezgi', 'Gozutok', '05550000001', 'ezgi@example.com', 1200);

-- =========================
-- 8) PACKAGES (15/20/25 KG)
-- =========================
INSERT INTO FarePackages(package_name, baggage_allowance_kg, seat_selection_policy)
VALUES
('PKG_15KG', 15, 'NONE'),
('PKG_20KG', 20, 'PAID_STANDARD'),
('PKG_25KG', 25, 'FREE_EXCEPT_BUSINESS');

-- =========================
-- 9) REFUND RULES
-- =========================
/*
Kural mantığı:
- PKG_15KG: iade yok -> rule yok (procedure refund_percent = 0 alacak)
- PKG_20KG: uçuşa 24 saatten fazla varsa %50 iade, 0 saatten büyükse yine %50 gibi basit tutalım
- PKG_25KG: her zaman %100 iade

Not: Procedure "hours_before_departure <= X olan kurallardan en büyük eşiği seçiyor".
*/
-- PKG_20KG (package_id = 2 varsayımı: insert sırası)
INSERT INTO FareRefundRules(package_id, hours_before_departure, refund_percent)
VALUES
(2, 0, 50),
(2, 24, 50);

-- PKG_25KG (package_id = 3)
INSERT INTO FareRefundRules(package_id, hours_before_departure, refund_percent)
VALUES
(3, 0, 100);

-- =========================
-- 10) RESERVATIONS (optional demo)
-- =========================
INSERT INTO Reservations(passenger_id, flight_id, reservation_date, status)
VALUES
(1, 1, GETDATE(), 'Pending');

-- =========================
-- 11) TICKETS + PAYMENTS (for demos)
-- =========================
/*
Ticket-1: Üye yolcu (Ezgi), PKG_25KG, Flight-1, Seat-2A (Economy)
Ticket-2: Misafir yolcu (Gul), PKG_15KG, Flight-1, Seat-2B (Economy)
Bu iki bilet sayesinde:
- iptal prosedürü (refund 100% vs 0%)
- trigger check-in
- transaction demo
yapabiliriz.
*/

-- Ticket-1
INSERT INTO Tickets(pnr, flight_id, passenger_id, seat_id, package_id, member_id, price_paid, ticket_status)
VALUES ('PNR000000001', 1, 1, 5, 3, 1, 1500.00, 'Active'); -- seat_id=5 -> 2A

DECLARE @t1 INT = SCOPE_IDENTITY();

INSERT INTO Payments(ticket_id, amount, payment_method, status)
VALUES (@t1, 1500.00, 'Credit Card', 'Paid');

-- Ticket-2
INSERT INTO Tickets(pnr, flight_id, passenger_id, seat_id, package_id, member_id, price_paid, ticket_status)
VALUES ('PNR000000002', 1, 2, 6, 1, NULL, 900.00, 'Active'); -- seat_id=6 -> 2B

DECLARE @t2 INT = SCOPE_IDENTITY();

INSERT INTO Payments(ticket_id, amount, payment_method, status)
VALUES (@t2, 900.00, 'Online', 'Paid');

-- =========================
-- 12) BAGGAGE + EXTRA BAGGAGE (demo)
-- =========================
INSERT INTO Baggage(ticket_id, weight, baggage_type)
VALUES
(@t1, 8.50, 'Cabin'),
(@t1, 18.00, 'Checked'),
(@t2, 7.00, 'Cabin');

INSERT INTO ExtraBaggagePurchases(ticket_id, extra_kg, price)
VALUES
(@t1, 5, 250.00);

-- =========================
-- 13) FLIGHT STATUS (history demo)
-- =========================
INSERT INTO Flight_Status(flight_id, status, delay_minutes, reason)
VALUES
(1, 'Scheduled', NULL, NULL),
(1, 'Delayed', 30, 'Operational delay');

-- =========================
-- 14) CREW + FLIGHT_CREW
-- =========================
INSERT INTO Crew(name, surname, role, experience_years, airline_id)
VALUES
('Ahmet', 'Yilmaz', 'Pilot', 12, 1),
('Ayse', 'Kaya', 'Co-Pilot', 6, 1),
('Deniz', 'Demir', 'Cabin Crew', 4, 1);

-- Uçuş-1’e crew ata
INSERT INTO Flight_Crew(flight_id, crew_id)
VALUES
(1, 1),
(1, 2),
(1, 3);

-- =========================
-- 15) MAINTENANCE
-- =========================
INSERT INTO Maintenance(airplane_id, maintenance_date, description, technician_name)
VALUES
(1, CAST(GETDATE() AS DATE), 'Routine inspection', 'Mehmet Usta');

-- =========================
-- 16) CHECK-IN (Trigger demo)
-- =========================
/*
Trigger AFTER INSERT:
CheckIns'e CheckedIn eklenince BoardingPasses otomatik oluşmalı.
*/
INSERT INTO CheckIns(ticket_id, status)
VALUES
(@t1, 'CheckedIn');

-- Kontrol: boarding pass oluştu mu?
SELECT * FROM BoardingPasses WHERE ticket_id = @t1;

PRINT 'Seed data loaded successfully.';

