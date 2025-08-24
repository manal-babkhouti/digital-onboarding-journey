USE cih_reporting;
GO

/* =========
   vw_FunnelSnapshot
   - Counts by step (cumulative “ever reached” logic)
   ========= */
IF OBJECT_ID('dbo.vw_FunnelSnapshot','V') IS NOT NULL DROP VIEW dbo.vw_FunnelSnapshot;
GO
CREATE VIEW dbo.vw_FunnelSnapshot
AS
WITH base AS (
    SELECT
        'Créés'                 AS etape, COUNT(*) AS nb, 1 AS ordre_etape
    FROM dbo.prospects_cih
    UNION ALL
    SELECT 'Email validé',     COUNT(*) , 2 FROM dbo.prospects_cih WHERE email_valide = 1
    UNION ALL
    SELECT 'SMS validé',       COUNT(*) , 3 FROM dbo.prospects_cih WHERE sms_valide = 1
    UNION ALL
    SELECT 'CIN uploadée',     COUNT(*) , 4 FROM dbo.prospects_cih WHERE cin_uploadee = 1
    UNION ALL
    SELECT 'Biométrie réussie',COUNT(*) , 5 FROM dbo.prospects_cih WHERE biometrie_reussie = 1
    UNION ALL
    SELECT 'Infos complètes',  COUNT(*) , 6 FROM dbo.prospects_cih WHERE infos_complementaires = 1
    UNION ALL
    SELECT 'RDV pris',         COUNT(*) , 7 FROM dbo.prospects_cih WHERE rdv_pris = 1
    UNION ALL
    SELECT 'Signature électronique', COUNT(*) , 8 FROM dbo.prospects_cih WHERE signature_electronique = 1
)
SELECT
    etape,
    nb,
    ordre_etape
FROM base;
GO

/* =========
   vw_DropOffParEtape
   - Loss between step k and k+1 (volume & %)
   ========= */
IF OBJECT_ID('dbo.vw_DropOffParEtape','V') IS NOT NULL DROP VIEW dbo.vw_DropOffParEtape;
GO
CREATE VIEW dbo.vw_DropOffParEtape
AS
WITH snap AS (
    SELECT * FROM dbo.vw_FunnelSnapshot
),
ranked AS (
    SELECT
        s1.ordre_etape,
        s1.etape,
        s1.nb AS cur_nb,
        LAG(s1.nb) OVER(ORDER BY s1.ordre_etape) AS prev_nb
    FROM snap s1
)
SELECT
    etape,
    ordre_etape,
    cur_nb,
    prev_nb,
    CASE WHEN prev_nb > 0 THEN prev_nb - cur_nb ELSE NULL END AS perte_volume,
    CASE WHEN prev_nb > 0 THEN 1.0 * (prev_nb - cur_nb) / prev_nb ELSE NULL END AS perte_pct
FROM ranked
WHERE ordre_etape > 1;
GO

/* =========
   vw_ChannelPerformance
   - Conversion by channel
   ========= */
IF OBJECT_ID('dbo.vw_ChannelPerformance','V') IS NOT NULL DROP VIEW dbo.vw_ChannelPerformance;
GO
CREATE VIEW dbo.vw_ChannelPerformance
AS
SELECT
    canal,
    COUNT(*)                               AS prospects_crees,
    SUM(CASE WHEN signature_electronique=1 THEN 1 ELSE 0 END) AS prospects_signes,
    CASE WHEN COUNT(*)>0
         THEN 1.0*SUM(CASE WHEN signature_electronique=1 THEN 1 ELSE 0 END)/COUNT(*)
         ELSE NULL END                      AS taux_conversion
FROM dbo.prospects_cih
GROUP BY canal;
GO

/* =========
   vw_FunnelParJour
   - Daily created + signed + conversion
   ========= */
IF OBJECT_ID('dbo.vw_FunnelParJour','V') IS NOT NULL DROP VIEW dbo.vw_FunnelParJour;
GO
CREATE VIEW dbo.vw_FunnelParJour
AS
WITH daily AS (
    SELECT
        date_creation AS jour,
        COUNT(*) AS crees,
        SUM(CASE WHEN signature_electronique=1 THEN 1 ELSE 0 END) AS signes
    FROM dbo.prospects_cih
    GROUP BY date_creation
)
SELECT
    jour,
    crees,
    signes,
    CASE WHEN crees>0 THEN 1.0*signes/crees ELSE NULL END AS taux_conversion
FROM daily;
GO
