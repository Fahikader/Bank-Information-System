USE [Bank_Information_System]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Client Accounts View
CREATE VIEW [dbo].[Client_accounts]
AS
SELECT 
    dbo.client.client_ID, 
    dbo.client.name, 
    dbo.client.surname, 
    dbo.account.account_name, 
    dbo.account.IBAN, 
    dbo.account_cache.balance
FROM dbo.client 
INNER JOIN dbo.account ON dbo.client.client_ID = dbo.account.client_ID 
INNER JOIN dbo.account_cache ON dbo.account.account_ID = dbo.account_cache.account_ID
GO

-- 2. Customer Data View
CREATE VIEW [dbo].[Customer_data]
AS
SELECT 
    dbo.client.name, 
    dbo.client.surname, 
    dbo.cities.city_name, 
    dbo.client.address, 
    dbo.client.phone
FROM dbo.client 
INNER JOIN dbo.cities ON dbo.client.city_id = dbo.cities.city_id
GO
