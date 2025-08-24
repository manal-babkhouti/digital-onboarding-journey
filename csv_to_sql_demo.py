import pandas as pd
import pyodbc

# 1. Charger les données synthétiques
df = pd.read_csv("data/donnees_prospects_CIH.csv")  # adapte le chemin si besoin

# 2. Connexion à SQL Server
conn_str = (
    "DRIVER={SQL Server};"
    "SERVER=localhost\\SQLEXPRESS01;"
    "DATABASE=cih_reporting;"
    "Trusted_Connection=yes;"
)
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# 3. Insérer chaque ligne dans la table
for _, row in df.iterrows():
    cursor.execute("""
        INSERT INTO prospects_cih (
            id_prospect, date_creation, canal, email_valide, sms_valide,
            cin_uploadee, biometrie_reussie, infos_complementaires, offre_bancaire,
            agence, rdv_pris, signature_electronique, age
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """,
    int(row['id_prospect']),
    row['date_creation'],
    row['canal'],
    int(row['email_valide']),
    int(row['sms_valide']),
    int(row['cin_uploadee']),
    int(row['biometrie_reussie']),
    int(row['infos_complementaires']),
    None if pd.isna(row['offre_bancaire']) else row['offre_bancaire'],
    None if pd.isna(row['agence']) else row['agence'],
    int(row['rdv_pris']),
    int(row['signature_electronique']),
    int(row['age'])
    )

conn.commit()
cursor.close()
conn.close()

print(" Données importées dans SQL Server avec succès!")
