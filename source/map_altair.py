import pyodbc
import pandas as pd
import altair as alt
from altair_saver import save

con = pyodbc.connect(
    'Driver={IBM i Access ODBC Driver}; '
    'System=localhost; UID=osswxx; PWD=osswxx;'
    )

df = pd.read_sql("SELECT TKADR1, TKNURI FROM qeol.tokmsp", con)

mapDict = {13121:'足立区',13105:'文京区',13101:'千代田区',13106:'台東区',
    13109:'品川区',13123:'江戸川区',13104:'新宿区',13113:'渋谷区',
    13117:'北区',13116:'豊島区',13102:'中央区',13115:'杉並区',
    13119:'板橋区',13112:'世田谷区',13107:'墨田区',13114:'中野区',
    13120:'練馬区',13108:'江東区',13110:'目黒区',13122:'葛飾区',
    13103:'港区',13111:'大田区',13118:'荒川区'}

def addr2code(addr):
    mapCode = str([k for k, v in mapDict.items() if v in addr])[1:6]
    return mapCode if mapCode[:1] == '1' else '00000' 

df.loc[:, 'mapCode'] = df.TKADR1.map(addr2code)
df = df[['mapCode', 'TKNURI']].groupby('mapCode', as_index=False).sum()
df.rename(columns={'mapCode':'TKNURI'})

url = "https://raw.githubusercontent.com/niiyz/"\
      "JapanCityGeoJson/master/topojson/custom/tokyo23.topojson"
source = alt.topo_feature(url, "tokyo23")

map = alt.Chart(source).mark_geoshape(
        stroke='pink', strokeWidth=1
).encode(
       alt.Color('TKNURI:Q', scale=alt.Scale(scheme='yellowgreenblue'),
		         legend=alt.Legend(title="当年度売上高")
				),
    tooltip=[alt.Tooltip('properties.N03_004:N', title="区"),
 			 alt.Tooltip('properties.N03_007:N', title="団体コード"),
 			 alt.Tooltip('TKNURI:Q', title="当年度売上高", format=',')]
).transform_lookup(
    lookup='properties.N03_007',
    from_=alt.LookupData(df, 'mapCode', ['TKNURI'])
).configure(
	background='#DDEEFF'
).configure_title(
	fontSize=24
).properties(
    title='当年売上高（東京２３区）',
    width=800,
    height=600
)

save(map, "./map_altair.html")