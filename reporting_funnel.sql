/***********************************************************************
CIH BANK — REPORTING FONCTIONNEL ET ANALYTIQUE DU PARCOURS DIGITAL — Pour usage SQL Server/SSMS.
Dernière MAJ : 22/07/2025
***********************************************************************/


/***********************************************************************
1️⃣  FUNNEL GLOBAL : EFFECTIF & % À CHAQUE ÉTAPE
***********************************************************************/
WITH funnel AS (
    SELECT
        COUNT(*) AS total_prospects,
        SUM(CAST(email_valide AS INT)) AS email_valides,
        SUM(CAST(sms_valide AS INT)) AS sms_valides,
        SUM(CAST(cin_uploadee AS INT)) AS cin_uploadees,
        SUM(CAST(biometrie_reussie AS INT)) AS biometries_reussies,
        SUM(CAST(infos_complementaires AS INT)) AS infos_complementaires_OK,
        SUM(CAST(rdv_pris AS INT)) AS rdvs_pris,
        SUM(CAST(signature_electronique AS INT)) AS signatures_finales
    FROM prospects_cih
)
SELECT
    total_prospects,
    email_valides,
    sms_valides,
    cin_uploadees,
    biometries_reussies,
    infos_complementaires_OK,
    rdvs_pris,
    signatures_finales,
    -- % passage depuis l’entrée du funnel
    ROUND(100.0 * email_valides / total_prospects, 1) AS pct_email,
    ROUND(100.0 * sms_valides / total_prospects, 1) AS pct_sms,
    ROUND(100.0 * cin_uploadees / total_prospects, 1) AS pct_cin,
    ROUND(100.0 * biometries_reussies / total_prospects, 1) AS pct_bio,
    ROUND(100.0 * infos_complementaires_OK / total_prospects, 1) AS pct_infos,
    ROUND(100.0 * rdvs_pris / total_prospects, 1) AS pct_rdv,
    ROUND(100.0 * signatures_finales / total_prospects, 1) AS pct_signature
FROM funnel;

/***********************************************************************
🆕  TAUX DE CONVERSION PROGRESSIF À CHAQUE ÉTAPE DU FUNNEL
***********************************************************************/
WITH funnel AS (
    SELECT
        COUNT(*) AS total_prospects,
        SUM(CAST(email_valide AS INT)) AS email_valides,
        SUM(CAST(sms_valide AS INT)) AS sms_valides,
        SUM(CAST(cin_uploadee AS INT)) AS cin_uploadees,
        SUM(CAST(biometrie_reussie AS INT)) AS biometries_reussies,
        SUM(CAST(infos_complementaires AS INT)) AS infos_complementaires_OK,
        SUM(CAST(rdv_pris AS INT)) AS rdvs_pris,
        SUM(CAST(signature_electronique AS INT)) AS signatures_finales
    FROM prospects_cih
)
SELECT
    ROUND(100.0 * email_valides / total_prospects, 1)                AS pct_email_depuis_total,
    ROUND(100.0 * sms_valides / email_valides, 1)                    AS pct_sms_depuis_email,
    ROUND(100.0 * cin_uploadees / sms_valides, 1)                    AS pct_cin_depuis_sms,
    ROUND(100.0 * biometries_reussies / cin_uploadees, 1)            AS pct_bio_depuis_cin,
    ROUND(100.0 * infos_complementaires_OK / biometries_reussies, 1) AS pct_infos_depuis_bio,
    ROUND(100.0 * rdvs_pris / infos_complementaires_OK, 1)           AS pct_rdv_depuis_infos,
    ROUND(100.0 * signatures_finales / rdvs_pris, 1)                 AS pct_signature_depuis_rdv
FROM funnel;

/***********************************************************************
2️⃣  DROP-OFF ANALYSIS — NOMBRE PERDUS À CHAQUE ÉTAPE (ORDRE DÉCROISSANT)
***********************************************************************/
WITH funnel AS (
    SELECT
        COUNT(*) AS total_prospects,
        SUM(CAST(email_valide AS INT)) AS email_valides,
        SUM(CAST(sms_valide AS INT)) AS sms_valides,
        SUM(CAST(cin_uploadee AS INT)) AS cin_uploadees,
        SUM(CAST(biometrie_reussie AS INT)) AS biometries_reussies,
        SUM(CAST(infos_complementaires AS INT)) AS infos_complementaires_OK,
        SUM(CAST(rdv_pris AS INT)) AS rdvs_pris,
        SUM(CAST(signature_electronique AS INT)) AS signatures_finales
    FROM prospects_cih
)
SELECT * FROM (
    SELECT 'email_valide' AS etape, total_prospects - email_valides AS perdus FROM funnel
    UNION ALL
    SELECT 'sms_valide', email_valides - sms_valides FROM funnel
    UNION ALL
    SELECT 'cin_uploadee', sms_valides - cin_uploadees FROM funnel
    UNION ALL
    SELECT 'biometrie_reussie', cin_uploadees - biometries_reussies FROM funnel
    UNION ALL
    SELECT 'infos_complementaires', biometries_reussies - infos_complementaires_OK FROM funnel
    UNION ALL
    SELECT 'rdv_pris', infos_complementaires_OK - rdvs_pris FROM funnel
    UNION ALL
    SELECT 'signature_electronique', rdvs_pris - signatures_finales FROM funnel
) AS drop_off
ORDER BY perdus DESC;


/***********************************************************************
3️⃣  FUNNEL PAR CANAL (WEB / MOBILE)
***********************************************************************/
SELECT
    canal,
    COUNT(*) AS total_prospects,
    SUM(CAST(email_valide AS INT)) AS email_valides,
    SUM(CAST(sms_valide AS INT)) AS sms_valides,
    SUM(CAST(cin_uploadee AS INT)) AS cin_uploadees,
    SUM(CAST(biometrie_reussie AS INT)) AS biometries_reussies,
    SUM(CAST(infos_complementaires AS INT)) AS infos_complementaires_OK,
    SUM(CAST(rdv_pris AS INT)) AS rdvs_pris,
    SUM(CAST(signature_electronique AS INT)) AS signatures_finales,
    ROUND(100.0 * SUM(CAST(signature_electronique AS INT))/COUNT(*), 1) AS pct_signature_finale
FROM prospects_cih
GROUP BY canal;


/***********************************************************************
4️⃣  FUNNEL PAR TRANCHE D’ÂGE
***********************************************************************/
SELECT
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
        ELSE '61+'
    END AS tranche_age,
    COUNT(*) AS total_prospects,
    SUM(CAST(email_valide AS INT)) AS email_valides,
    SUM(CAST(sms_valide AS INT)) AS sms_valides,
    SUM(CAST(cin_uploadee AS INT)) AS cin_uploadees,
    SUM(CAST(biometrie_reussie AS INT)) AS biometries_reussies,
    SUM(CAST(infos_complementaires AS INT)) AS infos_complementaires_OK,
    SUM(CAST(rdv_pris AS INT)) AS rdvs_pris,
    SUM(CAST(signature_electronique AS INT)) AS signatures_finales,
    ROUND(100.0 * SUM(CAST(signature_electronique AS INT))/COUNT(*), 1) AS pct_signature_finale
FROM prospects_cih
GROUP BY
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
        ELSE '61+'
    END;


/***********************************************************************
5️⃣  FUNNEL PAR AGENCE (TOP/BOTTOM AGENCES)
***********************************************************************/
SELECT TOP 10
    agence,
    COUNT(*) AS total_prospects,
    SUM(CAST(signature_electronique AS INT)) AS signatures_finales,
    ROUND(100.0 * SUM(CAST(signature_electronique AS INT))/COUNT(*), 1) AS pct_signature_finale
FROM prospects_cih
GROUP BY agence
ORDER BY pct_signature_finale ASC; -- Pour voir celles qui “perdent” le plus


/***********************************************************************
6️⃣  FUNNEL PAR OFFRE_BANCAIRE (Code18/30/60)
***********************************************************************/
SELECT
    offre_bancaire,
    COUNT(*) AS total_prospects,
    SUM(CAST(signature_electronique AS INT)) AS signatures_finales,
    ROUND(100.0 * SUM(CAST(signature_electronique AS INT))/COUNT(*), 1) AS pct_signature_finale
FROM prospects_cih
GROUP BY offre_bancaire;


/***********************************************************************
7️⃣  CROSS-SEGMENT ANALYSIS : CANAL × TRANCHE D’ÂGE
***********************************************************************/
SELECT
    canal,
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
        ELSE '61+'
    END AS tranche_age,
    COUNT(*) AS total,
    SUM(CAST(signature_electronique AS INT)) AS signatures_finales,
    ROUND(100.0 * SUM(CAST(signature_electronique AS INT))/COUNT(*), 1) AS pct_signature_finale
FROM prospects_cih
GROUP BY canal,
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
        ELSE '61+'
    END
ORDER BY pct_signature_finale ASC;


/***********************************************************************
8️⃣  COHORT ANALYSIS : TAUX DE SIGNATURE PAR SEMAINE DE CRÉATION
***********************************************************************/
SELECT
    DATEPART(week, date_creation) AS semaine_creation,
    COUNT(*) AS nb_prospects,
    SUM(CAST(signature_electronique AS INT)) AS nb_signatures,
    ROUND(100.0 * SUM(CAST(signature_electronique AS INT))/COUNT(*), 1) AS pct_signature
FROM prospects_cih
GROUP BY DATEPART(week, date_creation)
ORDER BY semaine_creation;


/***********************************************************************
9️⃣  TENDANCE TEMPORELLE (EVOLUTION JOUR PAR JOUR)
***********************************************************************/
SELECT
    date_creation,
    COUNT(*) AS prospects_total,
    SUM(CAST(signature_electronique AS INT)) AS nb_signatures,
    ROUND(100.0 * SUM(CAST(signature_electronique AS INT)) / COUNT(*), 1) AS pct_signature
FROM prospects_cih
GROUP BY date_creation
ORDER BY date_creation;

/***********************************************************************
🆕  ANALYSE PAR JOUR DE LA SEMAINE (WEEKDAY ANALYSIS)
***********************************************************************/
SELECT
    DATEPART(weekday, date_creation) AS jour_semaine, -- 1=Dim, 2=Lun, etc.
    COUNT(*) AS nb_prospects,
    SUM(CAST(signature_electronique AS INT)) AS nb_signatures,
    ROUND(100.0 * SUM(CAST(signature_electronique AS INT))/COUNT(*), 1) AS pct_signature
FROM prospects_cih
GROUP BY DATEPART(weekday, date_creation)
ORDER BY jour_semaine;

/***********************************************************************
🔟  “LOST PROSPECTS” — PROFIL DES ABANDONS À CHAQUE ÉTAPE
Exemple : prospects qui abandonnent à la biométrie
***********************************************************************/
SELECT
    canal, agence, age, offre_bancaire
FROM prospects_cih
WHERE biometrie_reussie = 0 AND cin_uploadee = 1; -- peut être fait pour n’importe quelle étape


/***********************************************************************
1️⃣1️⃣  HEATMAP/ANALYSE AVANCÉE : SIGNATURE PAR AGENCE ET CANAL
***********************************************************************/
SELECT
    agence,
    canal,
    COUNT(*) AS total,
    SUM(CAST(signature_electronique AS INT)) AS nb_signatures,
    ROUND(100.0 * SUM(CAST(signature_electronique AS INT))/COUNT(*), 1) AS pct_signature
FROM prospects_cih
GROUP BY agence, canal
ORDER BY pct_signature ASC;


/***********************************************************************
1️⃣2️⃣  COHÉRENCE MÉTIER : SIGNATURE SANS RDV (VÉRIFICATION)
***********************************************************************/
SELECT COUNT(*) AS signatures_sans_rdv
FROM prospects_cih
WHERE signature_electronique = 1 AND rdv_pris = 0; -- doit toujours être zéro


/***********************************************************************
1️⃣3️⃣  TENDANCE MOYENNE GLISSANTE 7 JOURS (MOVING AVERAGE) (SQL Server 2012+)
***********************************************************************/
SELECT
    date_creation,
    SUM(CAST(signature_electronique AS INT)) AS nb_signatures,
    AVG(SUM(CAST(signature_electronique AS INT))) OVER (
        ORDER BY date_creation ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS avg_7days_signatures
FROM prospects_cih
GROUP BY date_creation
ORDER BY date_creation;


/***********************************************************************
1️⃣4️⃣  BONUS : ANALYSE “LOST PROSPECTS” MULTI-SEGMENT
***********************************************************************/
SELECT
    canal, agence, age, offre_bancaire
FROM prospects_cih
WHERE
    infos_complementaires = 0
    AND biometrie_reussie = 1
    AND cin_uploadee = 1
    AND sms_valide = 1
    AND email_valide = 1;
-- Change la condition pour chaque étape pour trouver qui “drop” où

/***********************************************************************
FIN DU SCRIPT — CIH ULTIMATE REPORTING SQL 
***********************************************************************/
