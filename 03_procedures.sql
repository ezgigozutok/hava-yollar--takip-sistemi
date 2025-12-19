/* =========================================================
   04_procedures.sql
   Stored Procedures for Mini Airline DB (SQL Server)
   ========================================================= */

SET NOCOUNT ON;
GO

/* =========================================================
   1) sp_CancelTicketAndRefund
   Amaç:
   - Bileti iptal eder
   - Pakete göre iade yüzdesini bulur (FareRefundRules)
   - İade tutarını hesaplar
   - Cancelled_Tickets'e yazar
   - Payments durumunu Refunded yapar
   - Tüm işlemi TRANSACTION ile atomik yapar
   ========================================================= */
GO
CREATE OR ALTER PROCEDURE sp_CancelTicketAndRefund
    @ticket_id INT,
    @cancel_time DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- cancel_time verilmemişse şu an kabul edilir
    IF @cancel_time IS NULL
        SET @cancel_time = GETDATE();

    BEGIN TRY
        BEGIN TRANSACTION;

        /* 1) Ticket verilerini oku */
        DECLARE 
            @flight_id INT,
            @package_id INT,
            @price_paid DECIMAL(10,2),
            @ticket_status VARCHAR(20);

        SELECT
            @flight_id = flight_id,
            @package_id = package_id,
            @price_paid = price_paid,
            @ticket_status = ticket_status
        FROM Tickets
        WHERE ticket_id = @ticket_id;

        IF @flight_id IS NULL
            THROW 50001, 'Ticket not found.', 1;

        IF @ticket_status = 'Cancelled'
            THROW 50002, 'Ticket is already cancelled.', 1;

        /* 2) Uçuş kalkış zamanını al */
        DECLARE @departure_time DATETIME;
        SELECT @departure_time = departure_time
        FROM Flights
        WHERE flight_id = @flight_id;

        IF @departure_time IS NULL
            THROW 50003, 'Flight not found for this ticket.', 1;

        -- Kalkıştan sonra iptal yok (iş kuralı)
        IF @cancel_time >= @departure_time
            THROW 50004, 'Cannot cancel after departure time.', 1;

        /* 3) Uçuştan kaç saat önce iptal edildi? */
        DECLARE @hours_before_departure INT;
        SET @hours_before_departure = DATEDIFF(HOUR, @cancel_time, @departure_time);

        /* 4) En uygun iade kuralını seç */
        DECLARE @refund_percent INT;

        SELECT TOP 1
            @refund_percent = refund_percent
        FROM FareRefundRules
        WHERE package_id = @package_id
          AND hours_before_departure <= @hours_before_departure
        ORDER BY hours_before_departure DESC;

        -- Kural yoksa iade 0
        IF @refund_percent IS NULL
            SET @refund_percent = 0;

        /* 5) İade tutarı */
        DECLARE @refund_amount DECIMAL(10,2);
        SET @refund_amount = ROUND(@price_paid * (@refund_percent / 100.0), 2);

        /* 6) İptal kaydı */
        INSERT INTO Cancelled_Tickets(ticket_id, refund_amount, cancelled_at)
        VALUES(@ticket_id, @refund_amount, @cancel_time);

        /* 7) Ticket iptal */
        UPDATE Tickets
        SET ticket_status = 'Cancelled'
        WHERE ticket_id = @ticket_id;

        /* 8) Payment iade */
        UPDATE Payments
        SET status = 'Refunded'
        WHERE ticket_id = @ticket_id
          AND status IN ('Paid','Pending');

        COMMIT TRANSACTION;

        -- çıktıyı raporda göstermek için seçiyoruz
        SELECT
            @ticket_id AS ticket_id,
            @refund_percent AS refund_percent,
            @refund_amount AS refund_amount,
            @hours_before_departure AS hours_before_departure;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- hatayı geri fırlat
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @num INT = ERROR_NUMBER();
        DECLARE @state INT = ERROR_STATE();
        THROW @num, @msg, @state;
    END CATCH
END;
GO


/* =========================================================
   2) sp_BookTicket
   Amaç:
   - Bilet satın alma işlemini tek prosedürde toplar
   - Ticket insert + Payment insert aynı transaction içinde
   - Aynı uçuşta aynı koltuğun satılmasını UNIQUE constraint engeller
     (UQ_Tickets_FlightSeat) => hata olursa rollback
   Not:
   - Dinamik fiyatlandırmayı istersen burada hesaplatırız.
   ========================================================= */
GO
CREATE OR ALTER PROCEDURE sp_BookTicket
    @pnr VARCHAR(12),
    @flight_id INT,
    @passenger_id INT,
    @seat_id INT,
    @package_id INT,
    @member_id INT = NULL,
    @price_paid DECIMAL(10,2),
    @payment_method VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1) Ticket oluştur
        INSERT INTO Tickets(pnr, flight_id, passenger_id, seat_id, package_id, member_id, price_paid, ticket_status)
        VALUES(@pnr, @flight_id, @passenger_id, @seat_id, @package_id, @member_id, @price_paid, 'Active');

        DECLARE @new_ticket_id INT = SCOPE_IDENTITY();

        -- 2) Payment oluştur (Paid kabul ederek başlıyoruz)
        INSERT INTO Payments(ticket_id, amount, payment_method, status)
        VALUES(@new_ticket_id, @price_paid, @payment_method, 'Paid');

        COMMIT TRANSACTION;

        SELECT 'BOOKING_SUCCESS' AS result, @new_ticket_id AS ticket_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SELECT 'BOOKING_FAILED' AS result, ERROR_MESSAGE() AS error_message;
    END CATCH
END;
GO


/* =========================================================
   3) sp_AddMemberPoints
   Amaç:
   - Üyeye puan ekler
   - MemberPointsTransactions'a hareket kaydı atar (audit log)
   - Transaction ile garantiler
   ========================================================= */
GO
CREATE OR ALTER PROCEDURE sp_AddMemberPoints
    @member_id INT,
    @points INT,
    @description VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @points IS NULL OR @points <= 0
        THROW 50010, 'Points must be greater than 0.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1) Üye var mı?
        IF NOT EXISTS (SELECT 1 FROM Members WHERE member_id = @member_id)
            THROW 50011, 'Member not found.', 1;

        -- 2) Puan ekle
        UPDATE Members
        SET points = points + @points
        WHERE member_id = @member_id;

        -- 3) Hareket kaydı
        INSERT INTO MemberPointsTransactions(member_id, txn_type, points, description)
        VALUES(@member_id, 'EARN', @points, @description);

        COMMIT TRANSACTION;

        SELECT 'POINTS_ADDED' AS result, @member_id AS member_id, @points AS points_added;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @num INT = ERROR_NUMBER();
        DECLARE @state INT = ERROR_STATE();
        THROW @num, @msg, @state;
    END CATCH
END;
GO
