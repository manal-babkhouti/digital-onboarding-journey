USE cih_reporting;
GO

IF OBJECT_ID('dbo.sp_merge_prospects_cih','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_merge_prospects_cih;
GO

CREATE PROCEDURE dbo.sp_merge_prospects_cih
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @rows_inserted INT = 0,
            @rows_updated  INT = 0;

    MERGE dbo.prospects_cih AS T
    USING dbo.stg_prospects_cih AS S
        ON T.id_prospect = S.id_prospect
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (id_prospect, date_creation, canal,
                email_valide, sms_valide, cin_uploadee, biometrie_reussie,
                infos_complementaires, rdv_pris, signature_electronique)
        VALUES (S.id_prospect, S.date_creation, S.canal,
                S.email_valide, S.sms_valide, S.cin_uploadee, S.biometrie_reussie,
                S.infos_complementaires, S.rdv_pris, S.signature_electronique)
    WHEN MATCHED THEN
        UPDATE SET
            T.date_creation = S.date_creation,
            T.canal         = S.canal,

            -- Non-régression 1→0 : on force la progression par OR
            T.email_valide           = IIF(T.email_valide           = 1 OR S.email_valide           = 1, 1, 0),
            T.sms_valide             = IIF(T.sms_valide             = 1 OR S.sms_valide             = 1, 1, 0),
            T.cin_uploadee           = IIF(T.cin_uploadee           = 1 OR S.cin_uploadee           = 1, 1, 0),
            T.biometrie_reussie      = IIF(T.biometrie_reussie      = 1 OR S.biometrie_reussie      = 1, 1, 0),
            T.infos_complementaires  = IIF(T.infos_complementaires  = 1 OR S.infos_complementaires  = 1, 1, 0),
            T.rdv_pris               = IIF(T.rdv_pris               = 1 OR S.rdv_pris               = 1, 1, 0),
            T.signature_electronique = IIF(T.signature_electronique = 1 OR S.signature_electronique = 1, 1, 0)
    OUTPUT
        $action AS merge_action
    INTO #tmp_merge_result;

    SELECT
        @rows_inserted = SUM(CASE WHEN merge_action = 'INSERT' THEN 1 ELSE 0 END),
        @rows_updated  = SUM(CASE WHEN merge_action = 'UPDATE' THEN 1 ELSE 0 END)
    FROM #tmp_merge_result;

    INSERT INTO dbo.etl_run_log(rows_staged, rows_inserted, rows_updated, status, message)
    SELECT
        (SELECT COUNT(*) FROM dbo.stg_prospects_cih),
        ISNULL(@rows_inserted,0),
        ISNULL(@rows_updated,0),
        'SUCCESS',
        NULL;
END
GO
