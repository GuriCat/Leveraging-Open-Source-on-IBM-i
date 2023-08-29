import pyodbc
import pandas as pd
import altair as alt
from altair_saver import save

con = pyodbc.connect(
    'Driver={IBM i Access ODBC Driver}; '
    'System=localhost; UID=osswxx; PWD=osswxx;'
)

cursor = con.cursor()
sql = "SELECT tknakj,tknuri FROM qeol.tokmsp ORDER BY tknuri DESC \
       FETCH FIRST 5 ROWS ONLY"
df = pd.read_sql(sql, con)

graph = alt.Chart(df).mark_bar().encode(  # mark_barで棒グラフを指定
    alt.X('TKNAKJ:N', sort='-y', title=None, axis=alt.Axis(labelAngle=-45)),
    alt.Y('TKNURI:Q', title='売上高'),
).properties(
    height=250, width=80, title="売上トップ５"
).properties(
    width=alt.Step(100)  # 項目(棒)の間隔
)

text = graph.mark_text(
    align='center', baseline='bottom', dy=-5
).transform_calculate(
    uriage=alt.expr.format((alt.expr.round(alt.datum.TKNURI / 10000)), ',') + '万円'
).encode(
    text='uriage:N'
)

save((graph + text).configure_scale(bandPaddingInner=0.5), "/tmp/sales.html")