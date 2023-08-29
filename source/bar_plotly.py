import pyodbc
import pandas as pd
import plotly
import plotly.express as px

con = pyodbc.connect(
    'Driver={IBM i Access ODBC Driver}; '
    'System=localhost; UID=osswxx; PWD=osswxx;'
)

cursor = con.cursor()
sql = "SELECT * FROM qeol.tokmsp ORDER BY tknuri DESC \
       FETCH FIRST 10 ROWS ONLY"
df = pd.read_sql(sql, con)
df = df.rename(columns={'TKNAKJ':'得意先','TKNURI':'当年売上高'})

fig = px.bar(df, x="得意先", y="当年売上高", title="当年売上トップ１０")
fig.update_layout(font_size=18, hoverlabel_font_size=24, 
    xaxis_title=None, yaxis = dict(tickformat=',.3s'))
plotly.offline.plot(fig, filename="./barChart.html")

fig = px.pie(df, values="当年売上高", names='得意先', title="当年売上トップ１０")
fig.update_layout(font_size=18, hoverlabel_font_size=24)
fig.update_traces(textposition='inside', direction='clockwise')
plotly.offline.plot(fig, filename="./pieChart.html")