import pyodbc
import pandas as pd

conn = pyodbc.connect(
    'Driver={IBM i Access ODBC Driver}; System=localhost; UID=osswxx; PWD=osswxx;'
    )
cursor = conn.cursor()
sql = "select * from qeol.tokmsp fetch first 3 rows only"
df = pd.read_sql(sql, conn)
cursor.close()
conn.close()

df = df.applymap(lambda x: x.rstrip(" ""　") if isinstance(x, str) else x)
csv = df.to_csv("./tokmsp.csv", header=True, index=False, quoting=2, encoding="cp932")
# print(csv)
