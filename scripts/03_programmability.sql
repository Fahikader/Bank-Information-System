USE [Bank_Information_System]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. SCALAR-VALUED FUNCTIONS

CREATE FUNCTION [dbo].[To_Generate_IBAN](@AccountID INT)
RETURNS VARCHAR(25)
AS
BEGIN
    DECLARE @Country_Code VARCHAR(2) = 'LT'; 
    DECLARE @Branch_Code VARCHAR(5) = '70440';
    DECLARE @Padded_Account_NO VARCHAR(11);
    DECLARE @IBAN VARCHAR(25);
    DECLARE @Rearranged VARCHAR(50);
    DECLARE @Checksum INT;

    -- Pad the account number with '0' to make it 11 digits
    SET @Padded_Account_NO = RIGHT(REPLICATE('0', 11) + CAST(@AccountID AS VARCHAR), 11);

    -- Convert 'LT' to numeric values (L=21, T=29 -> 2129)
    DECLARE @L INT = ASCII('L') - ASCII('A') + 10;
    DECLARE @T INT = ASCII('T') - ASCII('A') + 10;
    DECLARE @LT VARCHAR(4) = CAST(@L AS VARCHAR) + CAST(@T AS VARCHAR);

    -- Rearrange for checksum calculation
    SET @Rearranged = @Branch_Code + @Padded_Account_NO + @LT + '00';

    -- Calculate MOD-97 checksum
    SET @Checksum = 98 - CAST(CAST(@Rearranged AS NUMERIC(38, 0)) % 97 AS INT);

    -- Assemble final IBAN
    SET @IBAN = @Country_Code + RIGHT('00' + CAST(@Checksum AS VARCHAR), 2) + @Branch_Code + @Padded_Account_NO;

    RETURN @IBAN;
END;
GO


-- 2. TABLE-VALUED FUNCTIONS


CREATE FUNCTION [dbo].[Customer_by_City](@CityID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        c.name AS Name, 
        c.surname AS Surname, 
        SUM(ac.balance) AS EUR_Total_Balance
    FROM dbo.client AS c
    INNER JOIN dbo.account AS a ON c.client_ID = a.client_ID
    INNER JOIN dbo.account_cache AS ac ON a.account_ID = ac.account_ID
    WHERE c.city_id = @CityID
    GROUP BY c.name, c.surname
);
GO


-- 3. STORED PROCEDURES


CREATE PROCEDURE [dbo].[Customer_Update]
    @name VARCHAR(255),
    @surname VARCHAR(255),
    @phone VARCHAR(20),
    @address VARCHAR(255),
    @city_name VARCHAR(255),
    @account_name VARCHAR(100)
AS
BEGIN
    DECLARE @client_id INT;
    DECLARE @city_id INT;
    DECLARE @account_ID INT;
    DECLARE @IBAN VARCHAR(25);

    -- Get city ID based on city name
    SELECT @city_id = city_id FROM dbo.cities WHERE city_name = @city_name;

    -- Check if the customer already exists
    SELECT @client_id = client_ID FROM dbo.client WHERE name = @name AND surname = @surname;

    -- Insert new client if they do not exist
    IF @client_id IS NULL
    BEGIN
        INSERT INTO dbo.client (name, surname, phone, city_id, address)
        VALUES (@name, @surname, @phone, @city_id, @address);

        SET @client_id = SCOPE_IDENTITY();
    END

    -- Insert a new account for the client
    INSERT INTO dbo.account (client_ID, account_name, creating_date)
    VALUES (@client_id, @account_name, GETDATE());

    SET @account_ID = SCOPE_IDENTITY();

    -- Generate and assign IBAN
    SET @IBAN = dbo.To_Generate_IBAN(@account_ID);

    UPDATE dbo.account
    SET IBAN = @IBAN
    WHERE account_ID = @account_ID;

    -- Initialize account cache and account detail
    INSERT INTO dbo.account_cache (account_ID, balance)
    VALUES (@account_ID, 0);

    INSERT INTO dbo.account_detail (account_ID, creating_date, value)
    VALUES (@account_ID, GETDATE(), 0);

    SELECT @account_ID AS AccountID, @IBAN AS IBAN;
END;
GO

CREATE PROCEDURE [dbo].[Amount_Transaction]
    @Credited_Acc_IBAN VARCHAR(25),
    @Debited_Acc_IBAN VARCHAR(25),
    @Value MONEY
AS 
BEGIN
    DECLARE @Balance MONEY;
    DECLARE @Credited_Acc_ID INT;
    DECLARE @Debited_Acc_ID INT;

    BEGIN TRANSACTION;

    SELECT @Credited_Acc_ID = a.account_ID 
    FROM dbo.account a
    WHERE a.IBAN = @Credited_Acc_IBAN;

    SELECT @Debited_Acc_ID = a.account_ID 
    FROM dbo.account a
    WHERE a.IBAN = @Debited_Acc_IBAN;

    SELECT @Balance = ac.balance 
    FROM dbo.account_cache ac 
    WHERE ac.account_ID = @Debited_Acc_ID;

    -- Verify sufficient balance before transferring
    IF @Balance < @Value
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51000, 'Insufficient Amount to transfer.', 1;
        RETURN;
    END

    -- Update balances in cache
    UPDATE dbo.account_cache
    SET balance = balance + @Value
    WHERE account_ID = @Credited_Acc_ID;

    UPDATE dbo.account_cache
    SET balance = balance - @Value
    WHERE account_ID = @Debited_Acc_ID;

    -- Record transaction entries in account_detail
    INSERT INTO dbo.account_detail (account_ID, creating_date, value)
    VALUES (@Credited_Acc_ID, GETDATE(), +@Value);

    INSERT INTO dbo.account_detail (account_ID, creating_date, value)
    VALUES (@Debited_Acc_ID, GETDATE(), -@Value);

    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE [dbo].[Ins_Update]
    @account_ID INT,
    @value MONEY
AS
BEGIN
    INSERT INTO dbo.account_detail (account_ID, creating_date, value)
    VALUES (@account_ID, GETDATE(), @value);

    UPDATE dbo.account_detail
    SET value = @value, creating_date = GETDATE()
    WHERE account_ID = @account_ID;
END;
GO


-- 4. TRIGGERS


CREATE TRIGGER [dbo].[Trigger_Account_Cache]
ON [dbo].[account_detail]
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE ac
    SET ac.balance = ac.balance + ins.value
    FROM dbo.account_cache ac
    INNER JOIN inserted ins ON ac.account_ID = ins.account_ID;
END;
GO

CREATE TRIGGER [dbo].[Trigger_LOG_Cities]
ON [dbo].[cities]
AFTER INSERT, UPDATE
AS
BEGIN
    -- Log INSERT operations
    INSERT INTO dbo.log (Effected_table, Effected_field, old_value, timestamp, record_id)
    SELECT 'cities', 'city_name', 'NEW', CURRENT_TIMESTAMP, city_id
    FROM inserted;

    -- Log UPDATE operations
    INSERT INTO dbo.log (Effected_table, Effected_field, old_value, timestamp, record_id)
    SELECT 'cities', 'city_name', CAST(del.city_name AS VARCHAR(50)), CURRENT_TIMESTAMP, del.city_id
    FROM deleted del
    INNER JOIN inserted ins ON del.city_id = ins.city_id;
END;
GO

CREATE TRIGGER [dbo].[Trigger_LOG_AccountCache]
ON [dbo].[account_cache]
AFTER INSERT, UPDATE
AS
BEGIN
    -- Log INSERT operations
    INSERT INTO dbo.log (Effected_table, Effected_field, old_value, timestamp, record_id)
    SELECT 'account_cache', 'balance', 'NEW', CURRENT_TIMESTAMP, ID
    FROM inserted;

    -- Log UPDATE operations
    INSERT INTO dbo.log (Effected_table, Effected_field, old_value, timestamp, record_id)
    SELECT 'account_cache', 'balance', CAST(del.balance AS VARCHAR(50)), CURRENT_TIMESTAMP, del.ID
    FROM deleted del
    INNER JOIN inserted ins ON del.ID = ins.ID;
END;
GO

CREATE TRIGGER [dbo].[Trigger_LOG_AccountDetail]
ON [dbo].[account_detail]
AFTER INSERT, UPDATE
AS
BEGIN
    -- Log INSERT operations
    INSERT INTO dbo.log (Effected_table, Effected_field, old_value, timestamp, record_id)
    SELECT 'account_detail', 'value', 'NEW', CURRENT_TIMESTAMP, account_ID
    FROM inserted;

    -- Log UPDATE operations
    INSERT INTO dbo.log (Effected_table, Effected_field, old_value, timestamp, record_id)
    SELECT 'account_detail', 'value', CAST(del.value AS VARCHAR(50)), CURRENT_TIMESTAMP, del.account_ID
    FROM deleted del
    INNER JOIN inserted ins ON del.account_ID = ins.account_ID;
END;
GO

CREATE TRIGGER [dbo].[Trigger_LOG_Client]
ON [dbo].[client]
AFTER INSERT, UPDATE
AS
BEGIN
    -- Log INSERT operations
    INSERT INTO dbo.log (Effected_table, Effected_field, old_value, timestamp, record_id)
    SELECT 'client', 'client_ID', 'NEW', CURRENT_TIMESTAMP, client_ID
    FROM inserted
    WHERE NOT EXISTS (SELECT 1 FROM deleted);

    -- Log UPDATE operations (tracking changes to client fields)
    IF UPDATE(phone)
    BEGIN
        INSERT INTO dbo.log (Effected_table, Effected_field, old_value, timestamp, record_id)
        SELECT 'client', 'phone', CAST(del.phone AS VARCHAR(50)), CURRENT_TIMESTAMP, del.client_ID
        FROM deleted del
        INNER JOIN inserted ins ON del.client_ID = ins.client_ID;
    END

    IF UPDATE(address)
    BEGIN
        INSERT INTO dbo.log (Effected_table, Effected_field, old_value, timestamp, record_id)
        SELECT 'client', 'address', CAST(del.address AS VARCHAR(50)), CURRENT_TIMESTAMP, del.client_ID
        FROM deleted del
        INNER JOIN inserted ins ON del.client_ID = ins.client_ID;
    END
END;
GO
