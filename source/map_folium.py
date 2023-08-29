import requests, urllib
import pyodbc
import pandas as pd
# from tqdm import tqdm
import folium

con = pyodbc.connect(
    'Driver={IBM i Access ODBC Driver}; '
    'System=localhost; UID=osswxx; PWD=osswxx;'
    )

df = pd.read_sql("SELECT TKBANG,TKNAKN,TKNAKJ,TKADR1,TKADR2,TKPOST,TKTELE,TKSIME "\
                 "FROM qeol.tokmsp", con)

url = "https://msearch.gsi.go.jp/address-search/AddressSearch?q="
def addr2coordinates(addr):
   resp = requests.get(url + urllib.parse.quote(addr), timeout=2)
   coor = resp.json()[0]["geometry"]["coordinates"]
   return coor[1], coor[0] # 緯度,経度

df = df.applymap(lambda x: x.rstrip(" ""　") if isinstance(x, str) else x)
# tqdm.pandas(desc="住所を座標(十進度の緯度/経度)に変換中")
df[["緯度", "経度"]] = df.apply(lambda x: addr2coordinates(x["TKADR1"] + x["TKADR2"]),
# df[["緯度", "経度"]] = df.progress_apply(lambda x: addr2coordinates(x["TKADR1"] + x["TKADR2"]), 
                     axis=1, result_type="expand")

m = folium.Map(location=addr2coordinates("東京都港区"), zoom_start=10.5, min_zoom=9)

folium.GeoJson(
   f"https://raw.githubusercontent.com/niiyz/JapanCityGeoJson/"\
    "master/geojson/custom/tokyo23.json", 
   name="geojson",
   style_function=lambda feature: {
      "fillColor": "royalblue", "color": "blue", "weight": 1
      }
   ).add_to(m)

marker_colors = ['red','blue','gray','orange','green','purple']
for i in range(0,len(df)):
   html=f"""
      <h3>{df.iloc[i]['TKNAKJ']}</h3>
      <ul>      
         <li>郵便番号：{df.iloc[i]['TKPOST']}</li>
         <li>住所：{df.iloc[i]['TKADR1'] + df.iloc[i]['TKADR2']}
            &nbsp;<a href="https://maps.google.com/maps?q={df.iloc[i]['緯度']},{df.iloc[i]['経度']}"
               target="_blank">Google Map</a></li>
         <li>電話番号：{df.iloc[i]['TKTELE']}</li>
         <li>締日コード：{df.iloc[i]['TKSIME']}</li>         
      </ul>
      """
   folium.Marker(
      location=[df.iloc[i]["緯度"], df.iloc[i]["経度"]],
      popup=folium.Popup(folium.IFrame(html=html, width=300, height=180)),
      icon=folium.Icon(color=marker_colors[int(df.iloc[i]["TKSIME"]) - 1], icon="info-sign")
   ).add_to(m)

tiles = ['cartodbdark_matter', 'cartodbpositron', 'openstreetmap', 'stamenterrain', 
         'stamentoner', 'stamenwatercolor']
for tile in tiles:
    folium.TileLayer(tile).add_to(m)
folium.LayerControl().add_to(m)

m.get_root().html.add_child(folium.Element('''
   <h2 align="center" style="font-size:20px"><b>東京２３区 得意先分布</b></h2>
	'''))

m.save(outfile="./map_folium.html")