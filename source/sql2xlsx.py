import pyodbc
import pandas as pd

conn = pyodbc.connect(
    'Driver={IBM i Access ODBC Driver}; System=localhost; '
    'UID=osswxx; PWD=osswxx;'
    )
cursor = conn.cursor()
df = pd.read_sql_query("select * from qeol.tokmsp", conn)
cursor.close()
conn.close()

df = df.applymap(lambda x: x.rstrip(" ""　") if isinstance(x, str) else x)
df.to_excel("./tokmsp.xlsx", sheet_name="得意先マスター", index=False,
    header=["得意先番号","得意先仮名","得意先漢字","住所１","住所２",
            "地区コード","郵便番号","電話番号","当月売上高","当年売上高",
            "前年売上高","売掛金残高","信用限度額","最終入金日","締め日コード"])