CREATE DATABASE [Bank_Information_System]
GO

USE [Bank_Information_System]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Cities (Parent Table)
CREATE TABLE [dbo].[cities](
	[city_id] [int] IDENTITY(1,1) NOT NULL,
	[city_name] [varchar](50) NULL,
 CONSTRAINT [PK_cities] PRIMARY KEY CLUSTERED 
(
	[city_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- 2. Client (Depends on Cities)
CREATE TABLE [dbo].[client](
	[client_ID] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](255) NOT NULL,
	[surname] [varchar](255) NULL,
	[phone] [varchar](255) NULL,
	[city_id] [int] NOT NULL,
	[address] [varchar](255) NULL,
 CONSTRAINT [PK_client] PRIMARY KEY CLUSTERED 
(
	[client_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[client] WITH CHECK ADD CONSTRAINT [FK_client_cities] FOREIGN KEY([city_id])
REFERENCES [dbo].[cities] ([city_id])
GO

ALTER TABLE [dbo].[client] CHECK CONSTRAINT [FK_client_cities]
GO

-- 3. Account (Depends on Client)
CREATE TABLE [dbo].[account](
	[account_ID] [int] IDENTITY(1,1) NOT NULL,
	[client_ID] [int] NOT NULL,
	[account_name] [varchar](50) NOT NULL,
	[creating_date] [date] NOT NULL,
	[IBAN] [varchar](50) NULL,
 CONSTRAINT [PK_account] PRIMARY KEY CLUSTERED 
(
	[account_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[account] WITH CHECK ADD CONSTRAINT [FK_account_client] FOREIGN KEY([client_ID])
REFERENCES [dbo].[client] ([client_ID])
GO

ALTER TABLE [dbo].[account] CHECK CONSTRAINT [FK_account_client]
GO

-- 4. Account Cache (Depends on Account)
CREATE TABLE [dbo].[account_cache](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[account_ID] [int] NOT NULL,
	[balance] [money] NOT NULL,
 CONSTRAINT [PK_account_cache] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[account_cache] WITH CHECK ADD CONSTRAINT [FK_account_cache_account] FOREIGN KEY([account_ID])
REFERENCES [dbo].[account] ([account_ID])
GO

ALTER TABLE [dbo].[account_cache] CHECK CONSTRAINT [FK_account_cache_account]
GO

-- 5. Account Detail (Depends on Account)
CREATE TABLE [dbo].[account_detail](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[account_ID] [int] NOT NULL,
	[creating_date] [date] NOT NULL,
	[value] [money] NOT NULL,
 CONSTRAINT [PK_account_detail] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[account_detail] WITH CHECK ADD CONSTRAINT [FK_account_detail_account] FOREIGN KEY([account_ID])
REFERENCES [dbo].[account] ([account_ID])
GO

ALTER TABLE [dbo].[account_detail] CHECK CONSTRAINT [FK_account_detail_account]
GO

-- 6. Audit Log
CREATE TABLE [dbo].[log](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Effected_table] [varchar](50) NOT NULL,
	[Effected_field] [varchar](50) NOT NULL,
	[old_value] [varchar](50) NOT NULL,
	[timestamp] [datetime] NOT NULL,
	[record_id] [int] NOT NULL,
 CONSTRAINT [PK_log] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
