import sqlite3
import datetime

def inspect():
    try:
        conn = sqlite3.connect("score_caddie.sqlite")
        cursor = conn.cursor()
        
        # Check tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        print("Tables:", [t[0] for t in tables])
        
        if ('tee_time_reminders',) in tables:
            cursor.execute("SELECT * FROM tee_time_reminders;")
            rows = cursor.fetchall()
            print("\n--- tee_time_reminders ---")
            cursor.execute("PRAGMA table_info(tee_time_reminders);")
            columns = [col[1] for col in cursor.fetchall()]
            print("Columns:", columns)
            for row in rows:
                row_dict = dict(zip(columns, row))
                # Convert timestamp if possible
                try:
                    ts = row_dict.get('reminder_date')
                    if ts:
                        dt = datetime.datetime.fromtimestamp(ts / 1000)
                        row_dict['reminder_date_parsed'] = dt.strftime('%Y-%m-%d %H:%M:%S')
                except Exception as e:
                    row_dict['reminder_date_parsed_error'] = str(e)
                print(row_dict)
        else:
            print("tee_time_reminders table not found!")
            
        conn.close()
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    inspect()
