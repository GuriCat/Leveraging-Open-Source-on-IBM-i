import pyodbc
import pandas as pd
import altair as alt
from altair_saver import save

con = pyodbc.connect(
    'Driver={IBM i Access ODBC Driver}; '
    'System=localhost; '
    'UID=osswxx; '
    'PWD=osswxx;'
)

cursor = con.cursor()
sql = "SELECT tknakj,tknuri,tkzuri \
    FROM qeol.tokmsp  \
    ORDER BY tknuri DESC \
    FETCH FIRST 5 ROWS ONLY"
df = pd.read_sql(sql, con).melt(id_vars=["TKNAKJ"], var_name="年度", value_name="売上")
df['年度'] = df['年度'].str.replace('TKNURI', '本年度')
df['年度'] = df['年度'].str.replace('TKZURI', '前年度')

chart = alt.Chart(df).mark_bar().encode( 
    alt.X('年度:N', axis=None),
    alt.Y('売上:Q', title='売上高'),
    alt.Facet('TKNAKJ:N', title=None, header=alt.Header(labelFontSize=16)),
    color='年度:N',
    tooltip=[alt.Tooltip('TKNAKJ', title='会社名'), alt.Tooltip('売上', format=',')],    
).properties(height=250, width=80, title="売上トップ５"
).configure_title(fontSize=24, anchor='middle'
).configure_view(stroke='transparent'
).configure_header(labelOrient='bottom', labelPadding=3
).configure_legend(titleFontSize=20, labelFontSize=20
).configure_facet(spacing=5
).configure_axis(labelFontSize=18, titleFontSize=22,
)

save(chart, "/tmp/sales_comp.html")