CREATE DATABASE QuickKartDB
go
Use QuickKartDB
go
IF OBJECT_ID('CardDetails')  IS NOT NULL
DROP TABLE CardDetails
GO
IF OBJECT_ID('PurchaseDetails')  IS NOT NULL
DROP TABLE PurchaseDetails
GO
IF OBJECT_ID('Products')  IS NOT NULL
DROP TABLE Products
GO
IF OBJECT_ID('Categories')  IS NOT NULL
DROP TABLE Categories
GO
IF OBJECT_ID('Users')  IS NOT NULL
DROP TABLE Users
GO
IF OBJECT_ID('Roles')  IS NOT NULL
DROP TABLE Roles
GO
IF OBJECT_ID('usp_RegisterUser')  IS NOT NULL
DROP PROC usp_RegisterUser
GO
IF OBJECT_ID('usp_AddProduct')  IS NOT NULL
DROP PROC usp_AddProduct
GO
IF OBJECT_ID('usp_UpdateBalance')  IS NOT NULL
DROP PROC usp_UpdateBalance
GO
IF OBJECT_ID('usp_InsertPurchaseDetails')  IS NOT NULL
DROP PROC usp_InsertPurchaseDetails
GO
IF OBJECT_ID('ufn_GetCardDetails')  IS NOT NULL
DROP FUNCTION ufn_GetCardDetails
GO
IF OBJECT_ID('ufn_GenerateNewProductId')  IS NOT NULL
DROP FUNCTION ufn_GenerateNewProductId
GO
IF OBJECT_ID('ufn_GetProductDetails')  IS NOT NULL
DROP FUNCTION ufn_GetProductDetails
GO
IF OBJECT_ID('ufn_ValidateUserCredentials')  IS NOT NULL
DROP FUNCTION ufn_ValidateUserCredentials
GO
IF OBJECT_ID('ufn_CheckEmailId')  IS NOT NULL
DROP FUNCTION ufn_CheckEmailId
GO
IF OBJECT_ID('ufn_GetCategories')  IS NOT NULL
DROP FUNCTION ufn_GetCategories
GO
IF OBJECT_ID('ufn_GenerateNewCategoryId')  IS NOT NULL
DROP FUNCTION ufn_GenerateNewCategoryId
GO


CREATE TABLE Roles
(
	[RoleId] TINYINT CONSTRAINT pk_RoleId PRIMARY KEY IDENTITY,
	[RoleName] VARCHAR(20) CONSTRAINT uq_RoleName UNIQUE
)
GO 

CREATE TABLE Users
(
	[EmailId] VARCHAR(50) CONSTRAINT pk_EmailId PRIMARY KEY,
	[UserPassword] VARCHAR(15) NOT NULL,
	[RoleId] TINYINT CONSTRAINT fk_RoleId REFERENCES Roles(RoleId),
	[Gender] CHAR CONSTRAINT chk_Gender CHECK(Gender='F' OR Gender='M') NOT NULL,
	[DateOfBirth] DATE CONSTRAINT chk_DateOfBirth CHECK(DateOfBirth<GETDATE()) NOT NULL,
	[Address] VARCHAR(200) NOT NULL
)
GO

CREATE TABLE Categories
(
	[CategoryId] TINYINT CONSTRAINT pk_CategoryId PRIMARY KEY IDENTITY,
	[CategoryName] VARCHAR(20) CONSTRAINT uq_CategoryName UNIQUE NOT NULL 
)
GO

CREATE TABLE Products
(
	[ProductId] CHAR(4) CONSTRAINT pk_ProductId PRIMARY KEY CONSTRAINT chk_ProductId CHECK(ProductId LIKE 'P%'),
	[ProductName] VARCHAR(50) CONSTRAINT uq_ProductName UNIQUE NOT NULL,
	[CategoryId] TINYINT CONSTRAINT fk_CategoryId REFERENCES Categories(CategoryId),
	[Price] NUMERIC(8) CONSTRAINT chk_Price CHECK(Price>0) NOT NULL,
	[QuantityAvailable] INT CONSTRAINT chk_QuantityAvailable CHECK (QuantityAvailable>=0) NOT NULL
)
GO
select * from Products
CREATE TABLE PurchaseDetails
(
	[PurchaseId] BIGINT CONSTRAINT pk_PurchaseId PRIMARY KEY IDENTITY(1000,1),
	[EmailId] VARCHAR(50) CONSTRAINT fk_EmailId REFERENCES Users(EmailId),
	[Product] CHAR(4) CONSTRAINT fk_ProductId REFERENCES Products(ProductId),
	[QuantityPurchased] SMALLINT CONSTRAINT chk_QuantityPurchased CHECK(QuantityPurchased>0) NOT NULL,
	[DateOfPurchase] DATETIME CONSTRAINT chk_DateOfPurchase CHECK(DateOfPurchase<=GETDATE()) DEFAULT GETDATE() NOT NULL,
)
GO
select * from PurchaseDetails

CREATE TABLE CardDetails
(
	[CardNumber] NUMERIC(16) CONSTRAINT pk_CardNumber PRIMARY KEY,
	[NameOnCard] VARCHAR(40) NOT NULL,
	[CardType] CHAR(6) NOT NULL CONSTRAINT chk_CardType CHECK (CardType IN ('A','M','V')),
	[CVVNumber] NUMERIC(3) NOT NULL,
	[ExpiryDate] DATE NOT NULL CONSTRAINT chk_ExpiryDate CHECK(ExpiryDate>=GETDATE()),
	[Balance] DECIMAL(10,2) CONSTRAINT chk_Balance CHECK([Balance]>=0)
)
GO


CREATE INDEX ix_RoleId ON Users(RoleId)
CREATE INDEX ix_CategoryId ON Products(CategoryId)
CREATE INDEX ix_EmailId ON PurchaseDetails(EmailId)
CREATE INDEX ix_ProductId ON PurchaseDetails(Product)
GO


CREATE FUNCTION ufn_CheckEmailId
(
	@EmailId VARCHAR(50)
)
RETURNS BIT
AS
BEGIN
	
	DECLARE @ReturnValue BIT
	
	IF NOT EXISTS (SELECT EmailId FROM Users WHERE EmailId=@EmailId)
		SET @ReturnValue=1
	
	ELSE SET @ReturnValue=0
	
	RETURN @ReturnValue

END
GO

CREATE FUNCTION ufn_ValidateUserCredentials
(
                @EmailId VARCHAR(50),
                @UserPassword VARCHAR(15)
)
RETURNS INT
AS
BEGIN
DECLARE @RoleId INT

                                SELECT @RoleId=RoleId FROM Users WHERE EmailId=@EmailId AND UserPassword=@UserPassword
                                
                                RETURN @RoleId
END
GO

CREATE FUNCTION ufn_GetCategories()
RETURNS TABLE 
AS
	RETURN (SELECT * FROM Categories)
GO

CREATE FUNCTION ufn_GetCardDetails(@CardNumber NUMERIC(16))
RETURNS TABLE 
AS
	RETURN (SELECT NameOnCard,CardType,CVVNumber,ExpiryDate,Balance FROM CardDetails WHERE CardNumber=@CardNumber)
GO

CREATE FUNCTION ufn_GetProductDetails(@CategoryId INT)
RETURNS TABLE 
AS
RETURN (SELECT ProductId,ProductName,Price,QuantityAvailable FROM Products WHERE CategoryId=@CategoryId)
GO

CREATE FUNCTION ufn_GenerateNewProductId()
RETURNS CHAR(4)
AS
BEGIN

	DECLARE @ProductId CHAR(4)
	
	IF NOT EXISTS(SELECT ProductId FROM Products)
		SET @ProductId='P100'
		
	ELSE
		SELECT @ProductId='P'+CAST(CAST(SUBSTRING(MAX(ProductId),2,3) AS INT)+1 AS CHAR) FROM Products

	RETURN @ProductId
	
END
GO

CREATE FUNCTION ufn_GenerateNewCategoryId()
RETURNS INT
AS
BEGIN

	DECLARE @CategoryId INT
	
	IF NOT EXISTS(SELECT ProductId FROM Products)
		SET @CategoryId ='1'
		
	ELSE
		SELECT @CategoryId =MAX(CategoryId)+1 FROM Categories

	RETURN @CategoryId 
	
END
GO


CREATE PROCEDURE usp_RegisterUser
(
	@UserPassword VARCHAR(15),
	@Gender CHAR,
	@EmailId VARCHAR(50),
	@DateOfBirth DATE,
	@Address VARCHAR(200)
)
AS
BEGIN
	DECLARE @RoleId TINYINT,
		@retval int
	BEGIN TRY
		IF (LEN(@EmailId)<4 OR LEN(@EmailId)>50 OR (@EmailId IS NULL))
			SET @retval = -1
		ELSE IF (LEN(@UserPassword)<8 OR LEN(@UserPassword)>15 OR (@UserPassword IS NULL))
			SET @retval = -2
		ELSE IF (@Gender<>'F' AND @Gender<>'M' OR (@Gender Is NULL))
			SET @retval = -3		
		ELSE IF (@DateOfBirth>=CAST(GETDATE() AS DATE) OR (@DateOfBirth IS NULL))
			SET @retval = -4
		ELSE IF DATEDIFF(d,@DateOfBirth,GETDATE())<6570
			SET @retval = -5
		ELSE IF (@Address IS NULL)
			SET @retval = -6
		ELSE
			BEGIN
				SELECT @RoleId=RoleId FROM Roles WHERE RoleName='Customer'
				INSERT INTO Users VALUES 
				(@EmailId,@UserPassword, @RoleId, @Gender, @DateOfBirth, @Address)
				SET @retval = 1			
			END
		SELECT @retval 
		END TRY
		BEGIN CATCH
			SET @retval = -99
			SELECT @retval 
		END CATCH
		
END
GO

CREATE PROCEDURE usp_AddProduct
(
	@ProductId CHAR(4),
	@ProductName VARCHAR(50),
	@CategoryId TINYINT,
	@Price NUMERIC(8),
	@QuantityAvailable INT
)
AS
BEGIN
	DECLARE @retval int
	BEGIN TRY
		IF (@ProductId IS NULL)
			SET @retval = -1
		ELSE IF (@ProductId NOT LIKE 'P%' or LEN(@ProductId)<>4)
			SET @retval = -2
		ELSE IF (@ProductName IS NULL)
			SET @retval = -3
		ELSE IF (@CategoryId IS NULL)
			SET @retval = -4
		ELSE IF NOT EXISTS(SELECT CategoryId FROM Categories WHERE CategoryId=@CategoryId)
			SET @retval = -5
		ELSE IF (@Price<=0 OR @Price IS NULL)
			SET @retval = -6
		ELSE IF (@QuantityAvailable<0 OR @QuantityAvailable IS NULL)
			SET @retval = -7
		ELSE
			BEGIN
				INSERT INTO Products VALUES 
				(@ProductId,@ProductName, @CategoryId, @Price, @QuantityAvailable)
				SET @retval = 1
			END
		SELECT @retval 
	END TRY
	BEGIN CATCH
		SET @retval = -99
		SELECT @retval 
	END CATCH
END
GO

CREATE PROCEDURE usp_UpdateBalance
(
	@CardNumber NUMERIC(16),
	@NameOnCard VARCHAR(40),
	@CardType CHAR(6),
	@CVVNumber NUMERIC(3),
	@ExpiryDate DATE,
	@Price DECIMAL(8)
)
AS
BEGIN
	DECLARE @TempUserName VARCHAR(40), @TempCardType CHAR(6), @TempCVVNumber NUMERIC(3), @TempExpiryDate DATE, @Balance DECIMAL(8), @retval int
	BEGIN TRY
		IF (@CardNumber IS NULL)
			SET @retval = -1
		ELSE IF NOT EXISTS(SELECT * FROM CardDetails WHERE CardNumber=@CardNumber)
			SET @retval = -2
		ELSE
			BEGIN
				SELECT @TempUserName=NameOnCard, @TempCardType=CardType, @TempCVVNumber=CVVNumber, @TempExpiryDate=ExpiryDate, @Balance=Balance 
				FROM CardDetails 
				WHERE CardNumber=@CardNumber
				IF ((@TempUserName<>@NameOnCard) OR (@NameOnCard IS NULL))
					SET @retval = -3
				ELSE IF ((@TempCardType<>@CardType) OR (@CardType IS NULL))
					SET @retval = -4
				ELSE IF ((@TempCVVNumber<>@CVVNumber) OR (@CVVNumber IS NULL))
					SET @retval = -5			
				ELSE IF ((@TempExpiryDate<>@ExpiryDate) OR (@ExpiryDate IS NULL))
					SET @retval = -6
				ELSE IF ((@Balance<@Price) OR (@Price IS NULL))
					SET @retval = -7
				ELSE
					BEGIN
						UPDATE Carddetails SET Balance=Balance-@Price WHERE CardNumber=@CardNumber
						SET @retval = 1
					END
			END
		SELECT @retval 
	END TRY
	BEGIN CATCH
		SET @retval = -99
		SELECT @retval 
	END CATCH
END
GO

CREATE PROCEDURE usp_InsertPurchaseDetails
(
	@EmailId VARCHAR(50),
	@ProductId CHAR(4),
	@QuantityPurchased INT,
	@PurchaseId BIGINT OUTPUT
)
AS
BEGIN
	DECLARE @retval int
	SET @PurchaseId=0	
		BEGIN TRY
			IF (@EmailId IS NULL)
				SET @retval = -1
			ELSE IF NOT EXISTS (SELECT @EmailId FROM Users WHERE EmailId=@EmailId)
				SET @retval = -2
			ELSE IF (@ProductId IS NULL)
				SET @retval = -3
			ELSE IF NOT EXISTS (SELECT ProductId FROM Products WHERE ProductId=@ProductId)
				SET @retval = -4
			ELSE IF ((@QuantityPurchased<=0) OR (@QuantityPurchased IS NULL))
				SET @retval = -5
			ELSE
				BEGIN
					INSERT INTO PurchaseDetails VALUES (@EmailId, @ProductId, @QuantityPurchased, DEFAULT)
					SELECT @PurchaseId=IDENT_CURRENT('PurchaseDetails')
					UPDATE Products SET QuantityAvailable=QuantityAvailable-@QuantityPurchased WHERE ProductId=@ProductId			
					SET @retval = 1
				END
			SELECT @retval 
		END TRY
		BEGIN CATCH
			SET @PurchaseId=0			
			SET @retval = -99
			SELECT @retval 
		END CATCH
	END
GO

--insertion scripts for roles
SET IDENTITY_INSERT Roles ON
INSERT INTO Roles (RoleId, RoleName) VALUES (1, 'Admin')
INSERT INTO Roles (RoleId, RoleName) VALUES (2, 'Customer')
SET IDENTITY_INSERT Roles OFF

--insertion scripts for Users
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Franken@gmail.com','BSBEV@1234',2,'F','1976-08-26','Fauntleroy Circus')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Henriot@gmail.com','CACTU@1234',2,'F','1971-09-04','Cerrito 333')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Hernadez@gmail.com','CHOPS@1234',2,'M','1981-09-18','Hauptstr. 29')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Jablonski@gmail.com','COMMI@1234',2,'M','1989-07-21','Av. dos Lus�adas, 23')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Josephs@gmail.com','CONSH@1234',2,'F','1963-11-09','Berkeley Gardens 12  Brewery')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Anzio_Don@infosys.com','don@123',1,'M','1991-02-24','Surya Bakery, Mysore;Surya Bakery, Mysore-570001')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Karttunen@gmail.com','DRACD@1234',2,'M','1963-06-27','Walserweg 21')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Koskitalo@gmail.com','DUMON@1234',2,'F','1966-01-28','67, rue des Cinquante Otages')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Labrune@gmail.com','EASTC@1234',2,'F','1980-02-09','35 King George')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Mathew_Edmar@infosys.com','Divine@456',2,'M','1989-09-12','Saibaba colony, Coimbatore')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Larsson@gmail.com','ERNSH@1234',2,'M','1988-04-08','Kirchgasse 6')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Latimer@gmail.com','FAMIA@1234',2,'M','1964-10-08','Rua Or�s, 92')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Lebihan@gmail.com','FISSA@1234',2,'M','1968-03-22','C/ Moralzarzal, 86')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Lincoln@gmail.com','FOLIG@1234',2,'M','1971-01-27','184, chauss�e de Tournai')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('McKenna@gmail.com','FOLKO@1234',2,'F','1979-08-30','�kergatan 24')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Mendel@gmail.com','FRANK@1234',2,'M','1964-07-08','Berliner Platz 43')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Muller@gmail.com','FRANR@1234',2,'F','1965-05-22','54, rue Royale')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Nagy@gmail.com','FRANS@1234',2,'F','1978-02-05','Via Monte Bianco 34')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Rourke@gmail.com','FURIB@1234',2,'F','1967-10-24','Jardim das rosas n. 32')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Ottlieb@gmail.com','GALED@1234',2,'F','1960-05-26','Rambla de Catalu�a, 23')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Paolino@gmail.com','GODOS@1234',2,'M','1961-08-29','C/ Romero, 33')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Parente@gmail.com','GOURL@1234',2,'F','1963-04-25','Av. Brasil, 442')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Pontes@gmail.com','GROSR@1234',2,'M','1962-09-29','5� Ave. Los Palos Grandes')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Rance@gmail.com','HANAR@1234',2,'M','1986-04-30','Rua do Pa�o, 67')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Roel@gmail.com','HILAA@1234',2,'M','1983-12-28','Carrera 22 con Ave. Carlos Soublette #8-35')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Roulet@gmail.com','HUNGC@1234',2,'M','1981-04-14','City Center Plaza 516 Main St.')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Saveley@gmail.com','HUNGO@1234',2,'F','1970-11-07','8 Johnstown Road')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Schmitt@gmail.com','ISLAT@1234',2,'F','1974-09-19','Garden House Crowther Way')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Rine_Jamwal@infosys.com','spacejet',2,'F','1991-07-20','R S Puram, Coimbatore')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Smith@gmail.com','KOENE@1234',2,'M','1985-05-08','Maubelstr. 90')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Snyder@gmail.com','LACOR@1234',2,'M','1985-11-03','67, avenue de l Europe')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Sommer@gmail.com','LAMAI@1234',2,'F','1968-09-08','1 rue Alsace-Lorraine')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Thomas@gmail.com','LAUGB@1234',2,'M','1986-11-15','1900 Oak St.')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Tonini@gmail.com','LAZYK@1234',2,'M','1988-11-11','12 Orchestra Terrace')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Mess@gmail.com','LEHMS@1234',2,'F','1964-07-30','Magazinweg 7')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Jai@gmail.com','LETSS@1234',2,'F','1971-01-21','87 Polk St. Suite 5')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Albert@gmail.com','LILAS@1234',2,'M','1963-12-23','Carrera 52 con Ave. Bol�var #65-98 Llano Largo')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Paolo@gmail.com','LINOD@1234',2,'M','1985-09-18','Ave. 5 de Mayo Porlamar')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Pedro@gmail.com','LONEP@1234',2,'F','1981-03-18','89 Chiaroscuro Rd.')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Victoria@gmail.com','MAGAA@1234',2,'M','1987-01-09','Via Ludovico il Moro 22')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Helen@gmail.com','MAISD@1234',2,'F','1968-06-28','Rue Joseph-Bens 532')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Lesley@gmail.com','MEREP@1234',2,'F','1982-12-23','43 rue St. Laurent')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Francisco@gmail.com','MORGK@1234',2,'M','1963-02-23','Heerstr. 22')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Sanio_Neeba@infosys.com','AllIsGood',2,'F','1990-06-13','Ramnagar, Coimbatore')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Philip@gmail.com','NORTS@1234',2,'M','1987-03-04','South House 300 Queensbridge')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Aria@gmail.com','OCEAN@1234',2,'M','1965-06-27','Ing. Gustavo Moncada 8585 Piso 20-A')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Ann@gmail.com','OLDWO@1234',2,'F','1981-03-21','2743 Bering St.')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Anabela@gmail.com','OTTIK@1234',2,'F','1985-11-23','Mehrheimerstr. 369')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Peter@gmail.com','PARIS@1234',2,'F','1981-11-13','265, boulevard Charonne')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Paul@gmail.com','PERIC@1234',2,'M','1987-05-17','Calle Dr. Jorge Cash 321')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Carlos@gmail.com','PICCO@1234',2,'M','1969-02-08','Geislweg 14')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Palle@gmail.com','PRINI@1234',2,'F','1961-03-29','Estrada da sa�de n. 58')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Karla@gmail.com','QUEDE@1234',2,'M','1968-04-28','Rua da Panificadora, 12')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Karin@gmail.com','QUEEN@1234',2,'F','1989-12-18','Alameda dos Can�rios, 891')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Matti@gmail.com','QUICK@1234',2,'M','1982-09-18','Taucherstra�e 10')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Pirkko@gmail.com','RANCH@1234',2,'M','1983-09-24','Av. del Libertador 900')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Janine@gmail.com','RATTC@1234',2,'F','1964-12-12','2817 Milton Dr.')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Maria@gmail.com','REGGC@1234',2,'M','1980-04-11','Strada Provinciale 124')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Yoshi@gmail.com','RICAR@1234',2,'F','1961-08-28','Av. Copacabana, 267')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Laurence@gmail.com','RICSU@1234',2,'M','1985-05-26','Grenzacherweg 237')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('MeetRoda@yahoo.co.in','ChristaRocks',1,'M','1990-04-20','Choultry Circle, Mysore')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Elizabeth@gmail.com','ROMEY@1234',2,'F','1975-04-26','Gran V�a, 1')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Patricia@gmail.com','SANTG@1234',2,'F','1968-10-16','Erling Skakkes gate 78')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Roland@gmail.com','SAVEA@1234',2,'F','1980-01-04','187 Suffolk Ln.')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Rita@gmail.com','SEVES@1234',2,'M','1972-06-15','90 Wadhurst Rd.')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Helvetius@gmail.com','SIMOB@1234',2,'F','1978-03-09','Vinb�ltet 34')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Timothy@gmail.com','SPECD@1234',2,'M','1964-09-28','25, rue Lauriston')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Sven@gmail.com','SPLIR@1234',2,'F','1967-12-12','P.O. Box 555')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('SamRocks@gmail.com','samsuji123!',2,'M','1991-06-15','Shankranti Circle, Mysore')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Miguel@gmail.com','SUPRD@1234',2,'F','1971-10-09','Boulevard Tirou, 255')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Paula@gmail.com','THEBI@1234',2,'M','1980-08-05','89 Jefferson Way Suite 2')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Manuel@gmail.com','THECR@1234',2,'M','1988-10-15','55 Grizzly Peak Rd.')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Mariaa@gmail.com','TOMSP@1234',2,'F','1987-11-29','Luisenstr. 48')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Martine@gmail.com','TORTU@1234',2,'M','1985-05-08','Avda. Azteca 123')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Diego@gmail.com','TRADH@1234',2,'F','1983-02-16','Av. In�s de Castro, 414')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Annette@gmail.com','TRAIH@1234',2,'M','1981-05-03','722 DaVinci Blvd.')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Mary@gmail.com','VAFFE@1234',2,'F','1977-10-09','Smagsloget 45')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Carine@gmail.com','VICTE@1234',2,'F','1982-12-27','2, rue du Commerce')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Margaret@gmail.com','VINET@1234',2,'M','1979-08-16','59 rue de l Abbaye')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Howard@gmail.com','WANDK@1234',2,'F','1982-06-02','Adenauerallee 900')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Martin@gmail.com','WARTH@1234',2,'M','1989-12-15','Torikatu 38')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Gary@gmail.com','WELLI@1234',2,'F','1968-12-27','Rua do Mercado, 12')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Daniel@gmail.com','WHITC@1234',2,'M','1978-05-22','305 - 14th Ave. S. Suite 3B')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('mat@gmail.com','WILMK@1234',2,'M','1977-01-13','Keskuskatu 45')
INSERT INTO Users( EmailId,UserPassword,RoleId,Gender, DateOfBirth,Address) VALUES('Davis@gmail.com','WOLZA@1234',2,'M','1982-01-09','ul. Filtrowa 68')

-- insertion script for Categories
SET IDENTITY_INSERT Categories ON
INSERT INTO Categories (CategoryId, CategoryName) VALUES (1, 'Motors')
INSERT INTO Categories (CategoryId, CategoryName) VALUES (2, 'Fashion')
INSERT INTO Categories (CategoryId, CategoryName) VALUES (3, 'Electronics')
INSERT INTO Categories (CategoryId, CategoryName) VALUES (4, 'Arts')
INSERT INTO Categories (CategoryId, CategoryName) VALUES (5, 'Home')
INSERT INTO Categories (CategoryId, CategoryName) VALUES (6, 'Sporting Goods')
INSERT INTO Categories (CategoryId, CategoryName) VALUES (7, 'Toys')
SET IDENTITY_INSERT Categories OFF

GO
-- insertion script for Productss
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P101','Lamborghini Gallardo Spyder',1,18000000.00,10)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P102','BMW X1',1,3390000.00,10)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P103','BMW Z4',1,6890000.00,10)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P104','Harley Davidson Iron 883 ',1,700000.00,10)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P105','Ducati Multistrada',1,2256000.00,10)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P106','Honda CBR 250R',1,193000.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P107','Kenneth Cole Black & White Leather Reversible Belt',2,2500.00,50)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P108','Classic Brooks Brothers 346 Wool Black Sport Coat',2,3078.63,10)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P109','Ben Sherman Mens Necktie Silk Tie',2,1847.18,20)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P110','BRIONI Shirt Cotton NWT Medium',2,2050.00,25)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P111','Patagonia NWT mens XL Nine Trails Vest',2,2299.99,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P112','Blue Aster Blue Ivory Rugby Pack Shoes',2,6772.37,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P113','Ann Taylor 100% Cashmere Turtleneck Sweater',2,3045.44,80)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P114','Fashion New Slim Ladies Womens Suit Coat',2,2159.59,65)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P115','Apple IPhone 5s 16GB',3,52750.00,70)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P116','Samsung Galaxy S4',3,38799.99,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P117','Nokia Lumia 1320',3,42199.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P118','LG Nexus 5',3,32649.54,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P119','Moto DroidX',3,32156.45,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P120','Apple MAcbook Pro',3,56800.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P121','Dell Inspiron',3,36789.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P122','IPad Air',3,28000.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P123','Xbox 360 with kinect',3,25000.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P124','Abstract Hand painted Oil Painting on Canvas',4,2056.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P125','Mysore Painting of Lord Shiva',4,5000.00,10)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P126','Tanjore Painting of Ganesha',4,8000.00,20)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P127','Marble Elephants statue',4,9056.00,50)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P128','Wooden photo frame',4,150.00,200)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P129','Gold plated dancing peacock',4,350.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P130','Kundan jewellery set',4,2000.00,30)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P131','Marble chess board','4','3000.00','20')
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P132','German Folk Art Wood Carvings Shy Boy and Girl',4,6122.20,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P133','Modern Abstract Metal Art Wall Sculpture',5,5494.55,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P134','Bean Bag Chair Love Seat',5,5754.55,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P135','Scented rose candles',5,200.00,50)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P136','Digital bell chime',5,800.00,10)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P137','Curtains',5,600.00,20)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P138','Wall stickers',5,200.00,30)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P139','Shades of Blue Line-by-Line Quilt',5,691.24,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P140','Tahoe Gear Prescott 10 Person Family Cabin Tent',6,9844.33,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P141','Turner Sultan 29er Large',6,147612.60,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P142','BAMBOO BACKED HICKORY LONGBOW ',6,5291.66,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P143','Adidas Shoes',6,700.00,150)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P144','Tennis racket',6,200.00,150)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P145','Baseball glove',6,150.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P146','Door gym',6,700.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P147','Cricket bowling machine',6,3000.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P148','ROLLER DERBY SKATES',6,3079.99,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P149','Metal 3.5-Channel RC Helicopter',7,2458.20,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P150','Ned Butterfly Style Yo Yo',7,553.23,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P151','Baby Einstein Hand Puppets',7,1229.41,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P152','fire godzilla toy',7,614.09,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P153','Remote car',7,1000.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P154','Barbie doll set',7,500.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P155','Teddy bear',7,300.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P156','Clever sticks',7,400.00,100)
INSERT INTO Products(ProductId,ProductName,CategoryId,Price,QuantityAvailable) VALUES('P157','See and Say',7,200.00,50)

GO

--insertion scripts for PurchaseDetails
SET IDENTITY_INSERT PurchaseDetails ON
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1001,'Franken@gmail.com','P101',2,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1002,'Franken@gmail.com','P143',1,'Jan 13 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1003,'Franken@gmail.com','P112',3,'Jan 14 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1004,'Franken@gmail.com','P148',2,'Jan 15 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1005,'Franken@gmail.com','P150',1,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1006,'Franken@gmail.com','P134',3,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1007,'SamRocks@gmail.com','P120',4,'Nov 17 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1008,'SamRocks@gmail.com','P110',4,'Nov 19 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1009,'SamRocks@gmail.com','P112',3,'Nov 20 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1010,'SamRocks@gmail.com','P148',1,'Nov 21 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1011,'SamRocks@gmail.com','P150',5,'Dec 22 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1012,'Davis@gmail.com','P134',1,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1013,'Davis@gmail.com','P101',3,'Jan 13 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1014,'Davis@gmail.com','P143',3,'Jan 14 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1015,'Davis@gmail.com','P112',3,'Jan 15 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1016,'Davis@gmail.com','P148',3,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1017,'Henriot@gmail.com','P150',5,'Jan 17 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1018,'Henriot@gmail.com','P134',1,'Nov 22 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1019,'Henriot@gmail.com','P111',2,'Dec 25 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1020,'Henriot@gmail.com','P121',1,'Nov 21 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1021,'Henriot@gmail.com','P122',5,'Nov 28 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1022,'Pirkko@gmail.com','P109',4,'Nov 29 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1023,'Pirkko@gmail.com','P123',5,'Dec 21 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1024,'Pirkko@gmail.com','P115',2,'Jan 21 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1025,'Pirkko@gmail.com','P113',5,'Dec 21 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1026,'Pirkko@gmail.com','P145',3,'Nov 28 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1027,'Pirkko@gmail.com','P132',5,'Nov 29 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1028,'Pirkko@gmail.com','P101',3,'Nov 30 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1029,'Elizabeth@gmail.com','P143',5,'Jan  1 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1030,'Elizabeth@gmail.com','P112',5,'Jan  2 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1031,'Elizabeth@gmail.com','P148',1,'Jan  3 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1032,'Elizabeth@gmail.com','P150',5,'Jan  4 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1033,'Elizabeth@gmail.com','P134',2,'Jan  5 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1034,'Elizabeth@gmail.com','P135',3,'Jan  6 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1035,'Paula@gmail.com','P136',3,'Jan  7 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1036,'Paula@gmail.com','P137',3,'Jan 18 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1037,'Paula@gmail.com','P148',5,'Jan 19 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1038,'Paula@gmail.com','P150',2,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1039,'Paula@gmail.com','P134',2,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1040,'Paula@gmail.com','P120',2,'Jan 11 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1041,'Paula@gmail.com','P110',5,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1042,'Howard@gmail.com','P112',2,'Jan 17 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1043,'Howard@gmail.com','P114',3,'Jan 19 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1044,'Howard@gmail.com','P101',1,'Jan 21 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1045,'Howard@gmail.com','P143',5,'Jan 22 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1046,'Howard@gmail.com','P112',2,'Jan 23 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1047,'Howard@gmail.com','P148',5,'Jan 14 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1048,'Howard@gmail.com','P150',4,'Jan 15 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1049,'Howard@gmail.com','P134',5,'Jan 17 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1066,'Franken@gmail.com','P101',2,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1067,'Franken@gmail.com','P143',1,'Jan 13 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1068,'Franken@gmail.com','P112',3,'Jan 14 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1069,'Franken@gmail.com','P148',2,'Jan 15 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1070,'Franken@gmail.com','P150',1,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1071,'Franken@gmail.com','P134',3,'Jan 17 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1072,'Pedro@gmail.com','P101',1,'Jan 18 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1073,'Pedro@gmail.com','P143',1,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1074,'Pedro@gmail.com','P112',5,'Jan 13 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1075,'Pedro@gmail.com','P148',1,'Jan 14 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1076,'Pedro@gmail.com','P150',2,'Jan 15 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1077,'Pedro@gmail.com','P134',4,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1078,'Pedro@gmail.com','P101',2,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1079,'Roland@gmail.com','P143',1,'Jan 13 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1080,'Roland@gmail.com','P112',3,'Jan 14 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1081,'Roland@gmail.com','P148',2,'Jan 15 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1082,'Roland@gmail.com','P150',1,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1083,'Roland@gmail.com','P134',3,'Jan 17 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1085,'Roland@gmail.com','P101',2,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1086,'Roland@gmail.com','P143',1,'Jan 13 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1087,'Roland@gmail.com','P112',3,'Jan 14 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1088,'Roland@gmail.com','P148',2,'Jan 15 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1089,'Roland@gmail.com','P150',1,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1090,'Roland@gmail.com','P134',3,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1108,'Timothy@gmail.com','P120',4,'Nov 17 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1110,'Timothy@gmail.com','P110',4,'Nov 19 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1111,'Timothy@gmail.com','P112',3,'Nov 20 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1112,'Timothy@gmail.com','P148',1,'Nov 21 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1114,'Timothy@gmail.com','P150',5,'Dec 22 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1115,'Timothy@gmail.com','P134',1,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1116,'Timothy@gmail.com','P101',3,'Jan 13 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1117,'Timothy@gmail.com','P143',3,'Jan 14 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1118,'Timothy@gmail.com','P112',3,'Jan 15 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1119,'Timothy@gmail.com','P148',3,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1120,'Timothy@gmail.com','P150',5,'Jan 17 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1121,'Timothy@gmail.com','P134',1,'Nov 22 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1122,'Matti@gmail.com','P111',2,'Dec 25 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1123,'Matti@gmail.com','P121',1,'Nov 21 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1124,'Matti@gmail.com','P122',5,'Nov 28 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1125,'Matti@gmail.com','P109',4,'Nov 29 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1126,'Matti@gmail.com','P123',5,'Dec 21 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1127,'Matti@gmail.com','P115',2,'Jan 21 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1128,'Matti@gmail.com','P113',5,'Dec 21 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1129,'Matti@gmail.com','P145',3,'Nov 28 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1130,'Matti@gmail.com','P132',5,'Nov 29 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1131,'Matti@gmail.com','P101',3,'Nov 30 2013 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1132,'Matti@gmail.com','P143',5,'Jan  1 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1133,'Matti@gmail.com','P112',5,'Jan  2 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1134,'Helvetius@gmail.com','P148',1,'Jan  3 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1135,'Helvetius@gmail.com','P150',5,'Jan  4 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1136,'Helvetius@gmail.com','P134',2,'Jan  5 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1137,'Helvetius@gmail.com','P135',3,'Jan  6 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1138,'Helvetius@gmail.com','P136',3,'Jan  7 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1139,'Helvetius@gmail.com','P137',3,'Jan 18 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1140,'Helvetius@gmail.com','P148',5,'Jan 19 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1141,'Helvetius@gmail.com','P150',2,'Jan 16 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1142,'Helvetius@gmail.com','P134',2,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1143,'Helvetius@gmail.com','P120',2,'Jan 11 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1144,'Helvetius@gmail.com','P110',5,'Jan 12 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1145,'Helvetius@gmail.com','P112',2,'Jan 17 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1146,'Mathew_Edmar@infosys.com','P114',3,'Jan 19 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1147,'Mathew_Edmar@infosys.com','P101',1,'Jan 21 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1148,'Mathew_Edmar@infosys.com','P143',5,'Jan 22 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1149,'Mathew_Edmar@infosys.com','P112',2,'Jan 23 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1150,'Mathew_Edmar@infosys.com','P148',5,'Jan 14 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1151,'Mathew_Edmar@infosys.com','P150',4,'Jan 15 2014 12:00AM')
INSERT INTO PurchaseDetails(PurchaseId,EmailId,Product,QuantityPurchased,DateOfPurchase) VALUES(1152,'Mathew_Edmar@infosys.com','P134',5,'Jan 17 2014 12:00AM')
SET IDENTITY_INSERT PurchaseDetails OFF

GO

--insertion scripts for CardDetails 
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1146665296881890,'Manuel','M',137,'2025-03-18',7282.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1164283045453550,'Renate Messner','V  ',133,'2028-01-08',14538.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1164916976389880,'Rita','M',588,'2025-07-28',18570.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1172583365804160,'McKenna','V  ',777,'2028-04-05',7972.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1190676541467400,'Brown','V  ',390,'2029-09-10',9049.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1201253053391160,'Patricia','M',501,'2029-06-24',19092.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1209611246778470,'Cruz','V  ',879,'2026-12-25',13645.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1224920265219560,'Pirkko','M',771,'2027-09-18',14620.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1229664582982800,'Helen','M',402,'2021-06-28',16932.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1245674190696670,'Mary','M',828,'2029-01-04',14078.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1258975792010020,'Annette','M',606,'2022-10-24',15889.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1299352607468300,'Saveley','V  ',161,'2023-08-05',14120.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1307313341777150,'Anne','M',684,'2019-08-28',16611.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1307984461363180,'Philip','M',663,'2021-08-19',9663.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1323958003776600,'Parente','V  ',517,'2021-07-22',7532.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1333123521082050,'Laurence','M',401,'2029-01-08',16257.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1344543094137310,'Chang','V  ',602,'2023-10-16',10822.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1353631465427820,'Paolino','V  ',435,'2022-08-14',5400.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1360271842709590,'Karin','M',878,'2024-03-07',12912.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1372132080189220,'Sommer','V  ',524,'2021-04-12',14556.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1375307422567340,'Yoshi','M',461,'2028-10-10',12344.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1386564526403300,'Carlos','M',468,'2025-01-25',6810.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1408191938746240,'Ibsen','V  ',246,'2022-09-09',7022.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1420510667654400,'Bennett','V  ',324,'2029-02-17',5724.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1422216593359170,'Aria','M',565,'2030-04-11',16016.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1429133847340950,'Martin','M',421,'2022-03-26',9567.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1431181049383360,'Matti Karttunen','M',851,'2026-05-14',6334.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1438819177663050,'Roel','V  ',641,'2024-09-15',13577.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1462257648213080,'Larsson','V  ',749,'2027-04-02',14693.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1482320853851460,'Peter','M',522,'2028-12-08',9433.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1492397474220820,'Maria','M',340,'2019-11-18',13098.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1514516790088230,'Pedro','V  ',820,'2028-09-04',6451.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1537796149367160,'Pontes','V  ',310,'2028-05-23',8675.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1555631662463540,'Henriot','V  ',779,'2020-08-20',9786.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1563901313189020,'Jaime Yorres','V  ',240,'2028-10-22',11605.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1572423633450130,'Matti','M',775,'2028-02-02',5972.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1574371302243230,'Hernadez','V  ',551,'2022-11-07',3998.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1580998908832260,'Muller','V  ',645,'2029-03-09',10031.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1589603911737880,'Lincoln','V  ',386,'2022-10-04',18947.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1598628594155670,'Karla','M',632,'2030-07-17',13292.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1608547117331400,'Rourke','V  ',494,'2026-11-10',8083.0)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1625578520990590,'Mendel','V  ',668,'2019-06-16',8736.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1644808785340540,'Lebihan','V  ',803,'2020-11-19',11121.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1656858554325890,'Paolo','V  ',480,'2027-11-26',11965.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1666406702985340,'Lesley','M',275,'2025-09-27',6934.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1670872362066270,'Ottlieb','V  ',664,'2027-10-30',3257.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1706709681608450,'Martine','M',461,'2020-12-16',6688.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1753456075904120,'Cramer','V  ',156,'2021-12-22',17721.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1762181841319160,'Victoria','V  ',846,'2027-08-20',5927.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1769660540375220,'Smith','V  ',603,'2027-10-05',3011.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1770791472481120,'Accorti','V  ',855,'2025-08-16',17423.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1770826010361760,'Koskitalo','V  ',874,'2029-09-11',15892.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1774070025907600,'Miguel','M',444,'2020-06-18',10058.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1780797319715350,'Helvetius','M',869,'2027-05-03',12015.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1787045046296090,'Domingues','V  ',335,'2028-11-03',6683.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1803781319458280,'Diego','M',744,'2026-01-14',15762.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1825594516343200,'Nagy','V  ',705,'2023-04-11',7712.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1869448663438790,'Snyder','V  ',310,'2023-04-06',15081.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1896069342213410,'Thomas','V  ',833,'2028-04-16',11755.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1905318731514900,'Sven','M',657,'2020-11-11',5759.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1930722559801600,'Pereira','V  ',556,'2026-04-12',5996.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1938972100708320,'Tonini','V  ',513,'2021-04-23',3565.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1974246182398960,'Anabela','M',204,'2023-12-03',13083.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1987863279307720,'Howard','M',331,'2026-02-10',2708.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(1996173177447140,'Davis','M',501,'2023-03-28',18212.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2017070736071510,'Franken','V  ',439,'2023-06-05',3590.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2020707634380970,'Karttunen','V  ',865,'2027-10-20',17928.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2038135301855300,'Janine','M',680,'2024-11-09',4077.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2040807464727850,'Paula','M',286,'2028-07-08',8052.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2054485375031050,'Elizabeth','M',183,'2024-09-12',6145.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2079696512053250,'Maria','M',465,'2025-07-18',6170.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2082327655038300,'Jablonski','V  ',622,'2020-02-29',14280.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2099162707660160,'Timothy','M',568,'2023-08-08',8408.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2099299687852320,'Carlos Gonz�lez','V  ',244,'2026-01-07',7330.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2102109985058560,'Ashworth','V  ',634,'2027-05-24',10204.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2102480159544330,'Roulet','V  ',764,'2026-08-20',2883.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2107089108224360,'Latimer','V  ',720,'2029-09-16',11387.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2112369521723620,'Carine','M',490,'2022-12-06',18773.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2119125701641590,'Schmitt','V  ',331,'2030-05-01',6182.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2121785955299770,'Palle','M',261,'2027-07-05',3655.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2122490035590690,'Margaret','M',875,'2022-01-16',18000.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2127803726103060,'Afonso','V  ',858,'2029-10-09',11726.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2136141552371090,'Rance','V  ',434,'2025-10-05',17813.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2139581656416670,'Francisco','M',727,'2029-01-30',15845.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2155938900697450,'Labrune','V  ',400,'2028-02-10',2455.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2157326961005880,'Daniel','M',827,'2029-03-07',2145.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2175932867933100,'Gary','M',635,'2028-05-31',14526.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2175974386401880,'Devon','V  ',270,'2021-11-20',3463.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2208687402112480,'Josephs','V  ',640,'2023-12-29',15794.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2210444662985580,'Paul','M',710,'2025-04-29',16523.00)
INSERT INTO CardDetails(CardNumber,NameOnCard,CardType,CVVNumber,ExpiryDate,Balance) VALUES(2219617013139190,'Roland','M',719,'2025-08-31',2537.00)
GO

