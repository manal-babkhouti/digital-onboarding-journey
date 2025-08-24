
USE cih_reporting;
GO

IF OBJECT_ID('dbo.stg_prospects_cih','U') IS NULL
BEGIN
    CREATE TABLE dbo.stg_prospects_cih (
        id_prospect            VARCHAR(64)  NOT NULL,
        date_creation          DATE         NOT NULL,
        canal                  VARCHAR(16)  NOT NULL,  -- 'web' | 'mobile'

        email_valide           BIT          NOT NULL DEFAULT 0,
        sms_valide             BIT          NOT NULL DEFAULT 0,
        cin_uploadee           BIT          NOT NULL DEFAULT 0,
        biometrie_reussie      BIT          NOT NULL DEFAULT 0,
        infos_complementaires  BIT          NOT NULL DEFAULT 0,
        rdv_pris               BIT          NOT NULL DEFAULT 0,
        signature_electronique BIT          NOT NULL DEFAULT 0
    );
END
GO

IF OBJECT_ID('dbo.prospects_cih','U') IS NULL
BEGIN
    CREATE TABLE dbo.prospects_cih (
        id_prospect            VARCHAR(64)  NOT NULL PRIMARY KEY,
        date_creation          DATE         NOT NULL,
        canal                  VARCHAR(16)  NOT NULL,

        email_valide           BIT          NOT NULL DEFAULT 0,
        sms_valide             BIT          NOT NULL DEFAULT 0,
        cin_uploadee           BIT          NOT NULL DEFAULT 0,
        biometrie_reussie      BIT          NOT NULL DEFAULT 0,
        infos_complementaires  BIT          NOT NULL DEFAULT 0,
        rdv_pris               BIT          NOT NULL DEFAULT 0,
        signature_electronique BIT          NOT NULL DEFAULT 0
    );
END
GO

IF OBJECT_ID('dbo.etl_run_log','U') IS NULL
BEGIN
    CREATE TABLE dbo.etl_run_log (
        run_id          INT IDENTITY(1,1) PRIMARY KEY,
        run_ts          DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        rows_staged     INT          NOT NULL,
        rows_inserted   INT          NOT NULL,
        rows_updated    INT          NOT NULL,
        status          VARCHAR(16)  NOT NULL,
        message         NVARCHAR(4000) NULL
    );
END
GO

/* Helpful indexes */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_prospects_cih_date' AND object_id=OBJECT_ID('dbo.prospects_cih'))
    CREATE INDEX IX_prospects_cih_date ON dbo.prospects_cih(date_creation);
GO
