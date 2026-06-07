import sqlite3

def inspect():
    try:
        conn = sqlite3.connect("score_caddie.sqlite")
        cursor = conn.cursor()
        
        # List all tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [t[0] for t in tables.fetchall()] if (tables := cursor) else []
        # Wait, the assignment expression syntax is fine, but let's do it cleanly:
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [t[0] for t in cursor.fetchall()]
        print("SQLite Tables:", tables)
        
        # Let's inspect rows for each table
        for table in tables:
            cursor.execute(f"SELECT COUNT(*) FROM {table};")
            count = cursor.fetchone()[0]
            print(f"Table {table}: {count} rows")
            
            # Print columns
            cursor.pragma = cursor.execute(f"PRAGMA table_info({table});")
            cols = [col[1] for col in cursor.fetchall()]
            print(f"  Columns: {cols}")
            
            if count > 0:
                cursor.execute(f"SELECT * FROM {table} LIMIT 5;")
                print(f"  Sample rows:")
                for r in cursor.fetchall():
                    print("   ", r)
        
        conn.close()
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    inspect()
