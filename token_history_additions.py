# Ajouts pour l'historique des tokens - À intégrer dans main.py

# ----------------------------
# Création de la table pour l'historique des tokens
# ----------------------------
async def create_token_history_table():
    conn = None
    try:
        conn = await asyncpg.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        # Vérifier si la table existe déjà
        table_exists = await conn.fetchval(
            "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'token_history')"
        )
        
        if not table_exists:
            print("🏗️ Création de la table token_history...")
            # Créer la table token_history
            await conn.execute('''
            CREATE TABLE IF NOT EXISTS token_history (
                id SERIAL PRIMARY KEY,
                token_uuid VARCHAR(255) NOT NULL,
                date DATE NOT NULL,
                canal VARCHAR(50),
                token_price DECIMAL(20,8),
                underlying_asset_price DECIMAL(20,2),
                initial_maintenance_reserve DECIMAL(20,2),
                total_investment DECIMAL(20,2),
                gross_rent_year DECIMAL(20,2),
                net_rent_year DECIMAL(20,4),
                rented_units INTEGER,
                renovation_reserve DECIMAL(20,2),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(token_uuid, date)
            )
            ''')
            
            # Créer des index pour améliorer les performances
            print("🔧 Création des index d'optimisation...")
            await conn.execute('CREATE INDEX IF NOT EXISTS idx_token_history_uuid ON token_history(token_uuid)')
            await conn.execute('CREATE INDEX IF NOT EXISTS idx_token_history_date ON token_history(date)')
            await conn.execute('CREATE INDEX IF NOT EXISTS idx_token_history_uuid_date ON token_history(token_uuid, date)')
            
            print("✅ Table token_history créée avec succès avec tous les index")
        else:
            print("✅ Table token_history existe déjà")
        
    except Exception as e:
        print(f"❌ Erreur lors de la création de la table token_history: {str(e)}")
        print(f"❌ Détails de l'erreur: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de la création de la table: {str(e)}")
    finally:
        if conn is not None:
            await conn.close()

# ----------------------------
# Fonctions de gestion des timestamps (autonomes)
# ----------------------------
async def create_last_executions_table_if_needed():
    """
    Crée la table last_executions si elle n'existe pas
    """
    conn = None
    try:
        conn = await asyncpg.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        await conn.execute('''
        CREATE TABLE IF NOT EXISTS last_executions (
            request VARCHAR(255) PRIMARY KEY,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        )
        ''')
        
    except Exception as e:
        print(f"⚠️ Erreur lors de la création de la table last_executions: {str(e)}")
    finally:
        if conn is not None:
            await conn.close()

async def update_execution_time_local(request_id: str):
    """
    Met à jour ou insère un timestamp dans la table last_executions (version locale)
    """
    conn = None
    try:
        # Créer la table si nécessaire
        await create_last_executions_table_if_needed()
        
        conn = await asyncpg.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        now = datetime.datetime.utcnow()
        
        # Utiliser UPSERT pour insérer ou mettre à jour
        await conn.execute('''
            INSERT INTO last_executions (request, created_at, updated_at) 
            VALUES ($1, $2, $3)
            ON CONFLICT (request) 
            DO UPDATE SET updated_at = $3
        ''', request_id, now, now)
        
    except Exception as e:
        print(f"⚠️ Erreur lors de la mise à jour du timestamp local: {str(e)}")
    finally:
        if conn is not None:
            await conn.close()

async def get_last_execution_time_local(request_id: str):
    """
    Récupère le dernier timestamp d'exécution (version locale)
    """
    conn = None
    try:
        # Créer la table si nécessaire
        await create_last_executions_table_if_needed()
        
        conn = await asyncpg.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        record = await conn.fetchrow(
            'SELECT updated_at FROM last_executions WHERE request = $1',
            request_id
        )
        
        if record:
            last_exec_time = record['updated_at']
            if last_exec_time.tzinfo is None:
                last_exec_time = last_exec_time.replace(tzinfo=datetime.timezone.utc)
            return last_exec_time
        
        return None
        
    except Exception as e:
        print(f"⚠️ Erreur lors de la récupération du timestamp local: {str(e)}")
        return None
    finally:
        if conn is not None:
            await conn.close()

# ----------------------------
# Fonction pour récupérer les données de l'API tokenHistory
# ----------------------------
async def fetch_token_history_from_api():
    """
    Récupère les données d'historique des tokens depuis l'API externe
    """
    try:
        api_url = "https://api.realtoken.community/v1/tokenHistory"
        
        print(f"🔍 Connexion à l'API: {api_url}")
        async with httpx.AsyncClient(timeout=60.0) as client:  # Augmenter le timeout
            print(f"📡 Envoi de la requête GET...")
            response = await client.get(api_url)
            
            print(f"📊 Réponse reçue - Status: {response.status_code}")
            
            if response.status_code != 200:
                error_text = ""
                try:
                    error_text = response.text
                    print(f"❌ Contenu de l'erreur: {error_text}")
                except:
                    pass
                print(f"❌ Erreur API: {response.status_code}")
                raise HTTPException(status_code=500, detail=f"API retourne {response.status_code}: {error_text}")
            
            print(f"📥 Parsing des données JSON...")
            try:
                data = response.json()
            except Exception as json_error:
                print(f"❌ Erreur lors du parsing JSON: {str(json_error)}")
                print(f"❌ Début de la réponse: {response.text[:200]}...")
                raise HTTPException(status_code=500, detail=f"Erreur parsing JSON: {str(json_error)}")
                
            print(f"✅ {len(data)} tokens récupérés avec leur historique")
            
            # Validation rapide des données
            valid_tokens = 0
            total_history_entries = 0
            for token_data in data:
                if token_data.get('uuid') and token_data.get('history'):
                    valid_tokens += 1
                    total_history_entries += len(token_data.get('history', []))
            
            print(f"📋 Validation: {valid_tokens} tokens valides, {total_history_entries} entrées d'historique au total")
            
            return data
            
    except httpx.TimeoutException:
        print("❌ Timeout lors de la récupération des données (60s dépassées)")
        raise HTTPException(status_code=504, detail="Timeout lors de la récupération des données")
    except httpx.RequestError as req_error:
        print(f"❌ Erreur de connexion: {str(req_error)}")
        raise HTTPException(status_code=500, detail=f"Erreur de connexion: {str(req_error)}")
    except Exception as e:
        print(f"❌ Erreur inattendue lors de la récupération des données: {str(e)}")
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération: {str(e)}")

# ----------------------------
# Fonction pour insérer les données d'historique en base
# ----------------------------
async def save_token_history_data(history_data):
    """
    Sauvegarde les données d'historique des tokens en base avec gestion optimisée des doublons
    """
    conn = None
    try:
        conn = await asyncpg.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        insert_count = 0
        update_count = 0
        skip_count = 0
        error_count = 0
        
        print(f"📊 Traitement de {len(history_data)} tokens avec leur historique...")
        
        # Récupérer tous les enregistrements existants en une seule fois pour éviter les appels répétés
        existing_records = await conn.fetch(
            'SELECT token_uuid, date FROM token_history'
        )
        existing_set = {(record['token_uuid'], record['date']) for record in existing_records}
        print(f"📋 {len(existing_set)} enregistrements existants trouvés en base")
        
        for token_index, token_data in enumerate(history_data):
            token_uuid = token_data.get('uuid')
            if not token_uuid:
                print(f"⚠️ Token {token_index}: UUID manquant, ignoré")
                error_count += 1
                continue
                
            history = token_data.get('history', [])
            print(f"🔄 Traitement du token {token_uuid} ({token_index + 1}/{len(history_data)}) - {len(history)} entrées d'historique")
            
            for history_entry in history:
                try:
                    date_str = history_entry.get('date')
                    if not date_str:
                        print(f"⚠️ Token {token_uuid}: Date manquante dans l'historique, ignoré")
                        error_count += 1
                        continue
                        
                    values = history_entry.get('values', {})
                    
                    # Convertir la date du format YYYYMMDD vers une date
                    try:
                        date_obj = datetime.strptime(date_str, '%Y%m%d').date()
                    except ValueError:
                        print(f"⚠️ Token {token_uuid}: Format de date invalide: {date_str}")
                        error_count += 1
                        continue
                    
                    # Vérifier si l'enregistrement existe déjà
                    if (token_uuid, date_obj) in existing_set:
                        print(f"⏭️ Token {token_uuid} - {date_str}: Déjà existant, ignoré")
                        skip_count += 1
                        continue
                    
                    # Extraire les valeurs avec gestion des types
                    canal = values.get('canal')
                    token_price = values.get('tokenPrice')
                    underlying_asset_price = values.get('underlyingAssetPrice')
                    initial_maintenance_reserve = values.get('initialMaintenanceReserve')
                    total_investment = values.get('totalInvestment')
                    gross_rent_year = values.get('grossRentYear')
                    net_rent_year = values.get('netRentYear')
                    rented_units = values.get('rentedUnits')
                    renovation_reserve = values.get('renovationReserve')
                    
                    # Insérer la nouvelle entrée avec ON CONFLICT pour éviter les erreurs de doublons
                    await conn.execute('''
                        INSERT INTO token_history (
                            token_uuid, date, canal, token_price, underlying_asset_price,
                            initial_maintenance_reserve, total_investment, gross_rent_year,
                            net_rent_year, rented_units, renovation_reserve
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
                        ON CONFLICT (token_uuid, date) DO NOTHING
                    ''',
                    token_uuid, date_obj, canal, token_price, underlying_asset_price,
                    initial_maintenance_reserve, total_investment, gross_rent_year,
                    net_rent_year, rented_units, renovation_reserve
                    )
                    insert_count += 1
                    
                    # Ajouter à notre set local pour éviter les doublons dans le même batch
                    existing_set.add((token_uuid, date_obj))
                    
                except Exception as entry_error:
                    print(f"❌ Erreur lors du traitement d'une entrée pour le token {token_uuid}: {str(entry_error)}")
                    error_count += 1
                    continue
        
        print(f"✅ Traitement terminé:")
        print(f"   📈 {insert_count} nouvelles insertions")
        print(f"   ⏭️ {skip_count} enregistrements déjà existants (ignorés)")
        print(f"   ❌ {error_count} erreurs rencontrées")
        
        return {
            "insertions": insert_count, 
            "updates": 0,  # Plus de updates, seulement des insertions
            "skipped": skip_count,
            "errors": error_count
        }
        
    except Exception as e:
        print(f"❌ Erreur critique lors de la sauvegarde des données d'historique: {str(e)}")
        print(f"❌ Traceback complet: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de la sauvegarde: {str(e)}")
    finally:
        if conn is not None:
            await conn.close()

# ------------------------------------------------------------------------------
# Routes pour l'API Token History
# ------------------------------------------------------------------------------

@app.get("/token_history/sync")
@limiter.limit("2/minute")
async def sync_token_history(request: Request):
    """
    Synchronise les données d'historique des tokens depuis l'API externe
    """
    try:
        print("🚀 Début de la synchronisation de l'historique des tokens")
        
        # Créer la table si elle n'existe pas
        print("🔧 Vérification/création de la table token_history...")
        await create_token_history_table()
        
        # Vérifier la dernière synchronisation pour éviter les appels trop fréquents
        # Utiliser directement notre fonction locale pour éviter les problèmes
        last_sync = await get_last_execution_time_local("token_history_sync")
        
        if last_sync is not None:
            utc_now = datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc)
            if last_sync.tzinfo is None:
                last_sync = last_sync.replace(tzinfo=datetime.timezone.utc)
            
            elapsed = (utc_now - last_sync).total_seconds()
            
            # Attendre au moins 10 minutes entre les synchronisations
            if elapsed < 600:  # 10 minutes
                remaining = int(600 - elapsed)
                return {
                    "status": "rate_limited",
                    "message": f"Synchronisation trop récente. Réessayez dans {remaining} secondes.",
                    "last_sync": last_sync.isoformat()
                }
        
        # Récupérer les données depuis l'API externe
        history_data = await fetch_token_history_from_api()
        
        # Sauvegarder les données en base
        save_result = await save_token_history_data(history_data)
        
        # Mettre à jour le timestamp de dernière exécution
        # Utiliser directement notre fonction locale robuste
        try:
            await update_execution_time_local("token_history_sync")
            print("✅ Timestamp de synchronisation mis à jour")
        except Exception as timestamp_error:
            print(f"⚠️ Erreur lors de la mise à jour du timestamp: {str(timestamp_error)}")
            print("⚠️ Synchronisation réussie mais timestamp non sauvegardé (non bloquant)")
        
        return {
            "status": "success",
            "message": "Synchronisation terminée avec succès",
            "total_tokens": len(history_data),
            "insertions": save_result["insertions"],
            "updates": save_result["updates"],
            "skipped": save_result["skipped"],
            "errors": save_result["errors"]
        }
        
    except Exception as e:
        print(f"❌ Erreur lors de la synchronisation: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail="Erreur lors de la synchronisation de l'historique des tokens")

@app.get("/token_history/")
@limiter.limit("10/minute")
async def get_token_history(request: Request, token_uuid: str = None, limit: int = 1000):
    """
    Récupère l'historique des tokens depuis la base de données
    """
    conn = None
    try:
        conn = await asyncpg.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        if token_uuid:
            # Récupérer l'historique pour un token spécifique
            records = await conn.fetch(
                '''
                SELECT * FROM token_history 
                WHERE token_uuid = $1 
                ORDER BY date DESC 
                LIMIT $2
                ''',
                token_uuid.lower(), limit
            )
        else:
            # Récupérer l'historique de tous les tokens
            records = await conn.fetch(
                '''
                SELECT * FROM token_history 
                ORDER BY date DESC, token_uuid 
                LIMIT $1
                ''',
                limit
            )
        
        if not records:
            return []
        
        return [dict(record) for record in records]
        
    except Exception as e:
        print(f"❌ Erreur lors de la récupération de l'historique: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération de l'historique des tokens")
    finally:
        if conn is not None:
            await conn.close()

@app.get("/token_history/{token_uuid}")
@limiter.limit("10/minute")
async def get_token_history_by_uuid(request: Request, token_uuid: str, limit: int = 100):
    """
    Récupère l'historique d'un token spécifique
    """
    conn = None
    try:
        conn = await asyncpg.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        records = await conn.fetch(
            '''
            SELECT * FROM token_history 
            WHERE token_uuid = $1 
            ORDER BY date DESC 
            LIMIT $2
            ''',
            token_uuid.lower(), limit
        )
        
        if not records:
            return {"status": "not_found", "message": "Aucun historique trouvé pour ce token"}
        
        return {
            "status": "success",
            "token_uuid": token_uuid,
            "total_entries": len(records),
            "history": [dict(record) for record in records]
        }
        
    except Exception as e:
        print(f"❌ Erreur lors de la récupération de l'historique pour {token_uuid}: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération de l'historique du token")
    finally:
        if conn is not None:
            await conn.close()

@app.get("/token_history/stats/summary")
@limiter.limit("5/minute")
async def get_token_history_stats(request: Request):
    """
    Récupère des statistiques sur l'historique des tokens
    """
    conn = None
    try:
        conn = await asyncpg.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        # Statistiques générales
        total_entries = await conn.fetchval('SELECT COUNT(*) FROM token_history')
        unique_tokens = await conn.fetchval('SELECT COUNT(DISTINCT token_uuid) FROM token_history')
        
        # Plage de dates
        date_range = await conn.fetchrow(
            'SELECT MIN(date) as first_date, MAX(date) as last_date FROM token_history'
        )
        
        # Dernière synchronisation
        last_sync = await get_last_execution_time("token_history_sync")
        
        # Tokens avec le plus d'entrées
        top_tokens = await conn.fetch(
            '''
            SELECT token_uuid, COUNT(*) as entry_count 
            FROM token_history 
            GROUP BY token_uuid 
            ORDER BY entry_count DESC 
            LIMIT 10
            '''
        )
        
        return {
            "status": "success",
            "stats": {
                "total_entries": total_entries,
                "unique_tokens": unique_tokens,
                "date_range": {
                    "first_date": date_range['first_date'].isoformat() if date_range['first_date'] else None,
                    "last_date": date_range['last_date'].isoformat() if date_range['last_date'] else None
                },
                "last_sync": last_sync.isoformat() if last_sync else None,
                "top_tokens_by_entries": [dict(record) for record in top_tokens]
            }
        }
        
    except Exception as e:
        print(f"❌ Erreur lors de la récupération des statistiques: {str(e)}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération des statistiques")
    finally:
        if conn is not None:
            await conn.close()

# À ajouter dans la fonction startup() :
# await create_token_history_table()
# print("✅ Table token_history vérifiée avec succès") 