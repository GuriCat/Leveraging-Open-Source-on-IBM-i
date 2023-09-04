# 4 IBM iでのPython利用例

<P> </P>

Pythonには多種多彩なパッケージが提供されており、IBM iの機能を補完する事ができます。この節では次のサンプルをIBM iと連携した「利用例」として紹介します。

* オフィスとの連携(Db2⇒Excel変換)：外部パッケージopenpyxlを利用してDb2 for iのデータを整形されたExcelに変換。
* データの可視化(グラフ化)：外部パッケージplotlyでDb2 for iのデータをグラフ化。さらに別の可視化パッケージであるAltairをIBM iのHTTPサーバーと組み合わせて、コロプレス図(色分け地図)を表示するWebアプリケーションを作成。
* IBM iプログラムとの連携：XMLSERVICEのPythonインターフェースであるitoolkitを利用してPythonとRPG/CL間で相互にプログラムを呼出し

  ?> XMLSERVICEはプログラムやコマンドなどの IBM iリソースをプレーンなXMLプロトコルを使用して操作できるようにするILE-RPGで書かれたプロシージャーのセット。詳細は「XMLSERVICE」(https://xmlservice.readthedocs.io/en/latest/ )やGitHub(https://github.com/IBM/xmlservice )を参照。

<br>

Pythonの応用は上記の例にとどまらず、数値解析、統計分析、機械学習、ディープラーニングなど、多くの分野での活用が可能です。自組織の要件に沿った展開を検討する事をお勧めします。

<br>

## 4.1 オフィスとの連携(Db2⇒Excel変換)

Db2 for iのデータをExcelに変換するには下記のように多くの方法があり、TPOによって使分ける事ができます。

* IBM iのCPYTOIMPFコマンドでデータをCSVに変換し、Excelに読み込む
* ACS(Access Client Solutions)のデータ転送機能をクライアントまたはIBM iのJVM上で実行し、Excel形式(xlsx)に変換
* IBM i Access for Web(5770XH2)でExcel形式に変換(IBM i 7.4以前)
* Excel(もしくはCSV/TSV)生成プログラムを作成
* 各種サードパーティー製品を利用

Pythonのpandasパッケージを利用して、ワーク□W6-2と同様の手法でシンプルなExcelを生成できます。pandasの生成するExcelは飾り気がありませんが、単に変換するだけであれば十分なケースも多いでしょう。

<br>

以下では「openpyxl」パッケージを利用してDb2 for iのデータをExcel化します。Excelの体裁を整えたり、RPAライクに既存のExcelを操作したりする事が可能です。

?> openpyxlの詳細は「openpyxl」(https://openpyxl.readthedocs.io/en/stable/ )などを参照。MITライセンス(参照：https://ja.wikipedia.org/wiki/MIT_License )で配布。

![4.1_オフィスとの連携.jpg](/files/4.1_オフィスとの連携.jpg)
<br>

仮想環境を活動化し、pipコマンドでopenpyxlをインストールします。

```bash
bash-5.1$ source py39venvxx/bin/activate
(py39venvxx) bash-5.1$ pip install openpyxl
Collecting openpyxl
  Downloading openpyxl-3.0.10-py2.py3-none-any.whl (242 kB)
     ━━━━━━━━━━━━━━━━━ 242.1/242.1 KB 6.8 MB/s eta 0:00:00
Collecting et-xmlfile
  Downloading et_xmlfile-1.1.0-py3-none-any.whl (4.7 kB)
Installing collected packages: et-xmlfile, openpyxl
Successfully installed et-xmlfile-1.1.0 openpyxl-3.0.10
```

任意のエディターで下記スクリプト「sql2xlsx2.py」を作成・編集します。

```python
0001 import pyodbc
0002 import pandas as pd
0003 import openpyxl
0004 from openpyxl.utils.dataframe import dataframe_to_rows
0005 from openpyxl.utils import get_column_letter
0006 from openpyxl.worksheet.table import Table, TableStyleInfo
0007 from openpyxl.styles import Font
0008 
0009 conn = pyodbc.connect(
0010     'Driver={IBM i Access ODBC Driver}; System=localhost; '
0011     'UID=osswxx; PWD=osswxx;'
0012     )
0013 cursor = conn.cursor()
0014 df = pd.read_sql_query("select * from qeol.tokmsp", conn)
0015 df2 = pd.read_sql_query("""select length,numeric_scale,numeric_precision,
0016     column_heading from qsys2.syscolumns
0017     where table_name = 'TOKMSP' and table_schema = 'QEOL'""", conn)
0018 cursor.close()
0019 conn.close()
0020 
0021 df = df.applymap(lambda x: x.rstrip(" ""　") if isinstance(x, str) else x)
0022 header = tuple(df2["COLUMN_HEADING"]. \
0023     apply(lambda x: x.replace(" ","").replace("　","")))
0024 
0025 wb = openpyxl.Workbook()
0026 ws = wb.active
0027 ws.title = "得意先マスター"
0028 
0029 for i, value in enumerate(header, start=1):
0030     ws.cell(1, i).value = value
0031 
0032 rows = dataframe_to_rows(df, index=False, header=True)
0033 for row_no, row in enumerate(rows, start=2):
0034     for col_no, value in enumerate(row, start=1):
0035         ws.cell(row_no, col_no).value = value
0036 
0037 for i, column_cells in enumerate(ws.columns):
0038     if df2["NUMERIC_SCALE"][i] == None:
0039         width = df2["LENGTH"][i]
0040         if width > 60: width = 60 
0041     else:
0042          width = df2["LENGTH"][i] + 4
0043     if width < 12: width = 12 
0044     ws.column_dimensions[get_column_letter(i + 1)].width = width
0045 
0046 table = Table(displayName='テーブル1', ref="A2:" + \
0047     get_column_letter(ws.max_column) + str(ws.max_row))
0048 table.tableStyleInfo = TableStyleInfo(name='TableStyleMedium9', showRowStripes=True)
0049 ws.add_table(table)
0050 
0051 font = Font(name='メイリオ')
0052 for row in ws:
0053     for cell in row:
0054         ws[cell.coordinate].font = font
0055 ws.sheet_view.zoomScale = 75
0056 ws.sheet_properties.pageSetUpPr.fitToPage = True
0057 ws.page_setup.fitToHeight = False
0058 ws.sheet_view.view = "pageBreakPreview" 
0059 
0060 wb.save('./tokmsp2.xlsx')
0061 wb.close()
```

* 4～7行目：コード内の記述を簡略化(例えば「openpyxl.styles.fonts.Font」→「Font」)するため使用するモジュールをimport。コードの書きやすさ・見やすさやモジュールの出現頻度でバランスを考慮。「from openpyxl import *」とすればすべてのモジュールが使用できるが、ワイルドカードのimportはPEP8(https://peps.python.org/pep-0008/#imports )では非推奨。
* 15～17行目：ExcelにCOLHDGを見出しとして表示するため、システム・カタログのSYSCOLUMNSビューからQEOL/TOKMSPのフィールド情報をDataFrame「df2」に取得。
* 21～23行目：「df2」のCOLUMN_HEADING列の値から半角/全角ブランクを除去してタプル型に変換。
* 25～27行目：新規Excelワークブックを作成し、アクティブシートの名前を「得意先マスター」に設定。
* 29～30行目：COLHDGをExcelの1行目に書き込み。
* 32～35行目：DataFrame「df」をdataframe_to_rowsメソッドで変換し、1行ずつ書き込む。DataFrameのインデックスは出力せず、列名を最初の行(2行目)に出力。
* 37～44行目：SYSCOLUMNSビューから取得した情報に基づいて列幅を調整。
* 46～49行目：テーブルとオートフィルターを設定。
* 51～58行目：フォントを「メイリオ」、表示倍率を75%、、印刷設定を「全ての行を1ページに印刷」、表示モードを「印刷プレビュー」に設定。
* 60行目：生成したExcelをパス「./tokmsp2.xlsx」に保存。同名のファイルは上書きされる。

<br>

このスクリプトを実行するとエラーが無ければExcelファイル「./tokmsp2.xlsx」が生成され、そのままプロンプトに戻ります。

```bash
bash-5.1$ source py39venvxx/bin/activate
(py39venvxx) bash-5.1$ python sql2xlsx2.py
```
<br>

openpyxlでは新規Excel作成以外にも、既存のワークシートの編集、グラフの挿入、値の取り出し、文字の検索など、多くのExcel作業を軽減・自動化できます。作業効率化の一案として有効でしょう。

!> VBA(マクロ)の実行、印刷などWindowsに依存する機能は実行不可。また、既存のExcelを更新する場合は表示などが変わらないかを確認。

<br>

### <u>ワーク7 PandasでExcelファイルを生成</u>

**□ W7-1.** isqlを*localに対して実行し、「QEOL/TOKMSP」、または、「QIWS/QCUSTCDT」にSQLでアクセスできることを確認。

**□ W7-2.** PythonのpandasパッケージでExcelを生成。自身のホームディレクトリ(「~」)に下記スクリプト「sql2xlsx.py」を作成して実行し、QEOL/TOKMSPを./tokmsp.xlsxに変換。生成されたファイル「./tokmsp.xlsx」をExcelで開いてデータが正しく変換されているか確認。

```python
0001 import pyodbc
0002 import pandas as pd
0003 
0004 conn = pyodbc.connect(
0005     'Driver={IBM i Access ODBC Driver}; System=localhost; '
0006     'UID=osswxx; PWD=osswxx;'
0007     )
0008 cursor = conn.cursor()
0009 df = pd.read_sql_query("select * from qeol.tokmsp", conn)
0010 cursor.close()
0011 conn.close()
0012 
0013 df = df.applymap(lambda x: x.rstrip(" ""　") if isinstance(x, str) else x)
0014 df.to_excel("./tokmsp.xlsx", sheet_name="得意先マスター", index=False,
0015     header=["得意先番号","得意先仮名","得意先漢字","住所１","住所２",
0016             "地区コード","郵便番号","電話番号","当月売上高","当年売上高",
0017             "前年売上高","売掛金残高","信用限度額","最終入金日","締め日コード"])
```

* 14～17行目：DataFrameをto_excel()メソッドでExcel形式に変換。

![ワーク7_Excel.jpg](/files/ワーク7_Excel.jpg)

<br>

## 4.2 データの可視化(グラフ化)

Pythonの特長として、機械学習や数値解析の結果に対する「可視化ライブラリー」が非常に充実している事が挙げられます。

この章では「Plotly」(https://plotly.com/python/ )、「Vega-Altair」(https://altair-viz.github.io/ )、「folium」(https://python-visualization.github.io/folium/ )を利用し、Db2 for iのデータをPythonでグラフ化します。

![4.2_データの可視化_グラフ化.jpg](/files/4.2_データの可視化_グラフ化.jpg)

<font size="-3">
出典：https://plotly.com/python/plotly-fundamentals/
</font>

<br>

### (参考) Python用外部パッケージの利用とサポート

Google Trends (https://trends.google.co.jp/trends/?geo=JP )によると、Pythonの可視化パッケージで最も事例が多いのはMatplotlib(およびこれを拡張するseaborn)です。しかし、IBM i 7.4および7.5では当初pipコマンドでエラーが発生し、Matplotlibをインストールできませんでした。他にも、geopandas(地理空間データの処理)やOpenCV(画像処理・画像解析ライブラリー)などでpipコマンドがエラーで中断します。

?> 2023年1月時点。なお、pipによるインストールエラーはIBM i以外でも様々な理由で発生する。

この場合、下記のいずれかを検討する事になるでしょう。

1. 他の同等機能を持つパッケージで代替
2. IBM i上で動作する機能のみでアプリケーションを構築し、必要な処理を外部サーバーに委譲・連携
3. サポートを求める
4. その他、Python以外の言語で実装する、IBM i以外(Linuxベースのクラウドなど)のプラットフォームで実装する、など

3に関してはIBMのサイト「Open Source Support for IBM i」(https://www.ibm.com/support/pages/open-source-support-ibm-i )にまとめられています。例えば、下図はRyverの「OSS on IBM i」コミュニティです。IBM iのOSSにまつわる質問やエラー対応の相談をこちらに書き込むと誰かが対応してくれるかもしれません。

![参考_Ryver.jpg](/files/参考_Ryver.jpg)

他にも、「IBM Power Community」(http://ibm.biz/ibmicommunity )では各種の情報共有やQ&Aが、「Kevin Adler’s Blog」(https://kadler.io/ )には月ごとのOSS関連情報があります。必要に応じてこれらを利用し、IBM iのOSSを活用する事をお勧めします。

<br>

### 4.2.1 シンプルなグラフ(Plotly)

まずはPlotlyで簡単なグラフを作成します。

Plotlyは高機能な可視化パッケージですが、一般的なグラフをクイックに作成する「Plotly Express」が含まれています。これを利用してDb2 for iのデータを容易に下記のようなグラフにできます。

![4.2.1_シンプルなグラフ.jpg](/files/4.2.1_シンプルなグラフ.jpg)

<br>

### <u>ワーク8 Python+PlotlyでシンプルなHTMLグラフの作成</u>

**□ W8-1.** 自身のPython仮想環境に入り、pipコマンドでPlotlyをインストール。

```bash
bash-5.1$ source py39venvxx/bin/activate
(py39venvxx) bash-5.1$ pip install plotly
Collecting plotly
  Downloading plotly-5.12.0-py2.py3-none-any.whl (15.2 MB)
     ━━━━━━━━━━━━━━━━━━ 15.2/15.2 MB 23.6 MB/s eta 0:00:00
Collecting tenacity>=6.2.0
  Downloading tenacity-8.1.0-py3-none-any.whl (23 kB)
Installing collected packages: tenacity, plotly
Successfully installed plotly-5.12.0 tenacity-8.1.0
```

**□ W8-2.** QEOL/TOKMSPを元に棒グラフを作成。自身のホームディレクトリ(「~」)にスクリプト「bar_plotly.py」を作成してスクリプトを実行。生成された「./barChart.html」を任意のWebブラウザーで表示して確認。

```python
0001 import pyodbc
0002 import pandas as pd
0003 import plotly
0004 import plotly.express as px
0005 
0006 con = pyodbc.connect(
0007     'Driver={IBM i Access ODBC Driver}; '
0008     'System=localhost; UID=osswxx; PWD=osswxx;'
0009 )
0010 
0011 cursor = con.cursor()
0012 sql = "SELECT * FROM qeol.tokmsp ORDER BY tknuri DESC \
0013        FETCH FIRST 10 ROWS ONLY"
0014 df = pd.read_sql(sql, con)
0015 df = df.rename(columns={'TKNAKJ':'得意先','TKNURI':'当年売上高'})
0016 
0017 fig = px.bar(df, x="得意先", y="当年売上高", title="当年売上トップ１０")
0018 fig.update_layout(font_size=18, hoverlabel_font_size=24, 
0019     xaxis_title=None, yaxis = dict(tickformat=',.3s'))
0020 plotly.offline.plot(fig, filename="./barChart.html")
```

* 17行目：「.bar」で棒グラフの作成を指定し、横軸(x)に「得意先」、縦軸(y)に「当年売上高」を使用し、グラフのタイトルを設定。
* 18～19行目：グラフとホバーテキストの文字サイズを指定し、横軸ラベル無し、縦軸の表示形式を指定。

**□ W8-3.** (オプション) 17～20行目を下記のコードに変更して円グラフ「./pieChart.html」を作成し、Webブラウザで開いて確認。

```python
0017 fig = px.pie(df, values="当年売上高", names='得意先', title="当年売上トップ１０")
0018 fig.update_layout(font_size=18, hoverlabel_font_size=24)
0019 fig.update_traces(textposition='inside', direction='clockwise')
0020 plotly.offline.plot(fig, filename="./pieChart.html")
```

* 17行目：「.pie」で円グラフの作成を指定し、値に「当年売上高」、項目名に「得意先」を使用し、グラフのタイトルを設定。
* 19行目：円内に表示されるテキスト(デフォルトは各項目の割合%)の表示位置を内部、項目を表示する順番を時計回りに指定。

<br>

### 4.2.2 コロプレスマップ(Altair)


次に可視化パッケージAltairでコロプレスマップを作成します。

?> Choropleth map(階級区分図)。統計数値に合わせて複数の領域を色調を変えて塗り分けた図。

![4.2.2_コロプレスマップ.jpg](/files/4.2.2_コロプレスマップ.jpg)

コロプレスマップを利用すれば、地図を領域で塗り分けて、分布の状況を直感的に把握できるようになります。作例はIBM i上の得意先マスターのデータを利用し、区ごとに集計した売上高(金額)で23区を塗り分けています。

<br>

仮想環境からpipコマンドでパッケージaltairとaltair_saverをインストールします。

```bash
(py39venvxx) bash-5.1$ pip --version
pip 22.0.4 from /home/OSSWXX/py39venvxx/lib/python3.9/site-packages/pip (python 3.9)
(py39venvxx) bash-5.1$ pip install altair
Collecting altair
～～～～～～～～～～～～～～～ 中略 ～～～～～～～～～～～～～～～～～
Successfully installed MarkupSafe-2.1.1 altair-4.2.0 attrs-22.2.0 entrypoints-0.4 jinja2-3.1.2 jsonschema-4.17.3 pyrsistent-0.19.3 toolz-0.12.0
(py39venvxx) bash-5.1$ pip install altair_saver
Collecting altair_saver
～～～～～～～～～～～～～～～ 中略 ～～～～～～～～～～～～～～～～～
Successfully installed PySocks-1.7.1 altair-data-server-0.4.1 altair-viewer-0.4.0 altair_saver-0.5.0 async-generator-1.10 certifi-2022.12.7 exceptiongroup-1.1.0 h11-0.14.0 idna-3.4 outcome-1.2.0 portpicker-1.5.2 selenium-4.7.2 sniffio-1.3.0 sortedcontainers-2.4.0 tornado-6.2 trio-0.22.0 trio-websocket-0.9.2 urllib3-1.26.13 wsproto-1.2.0
(py39venvxx) bash-5.1$
```

pipコマンドがエラーなく終了したら、Altairがインストールされた事を確認します。

```bash
(py39venvxx) bash-5.1$ pip list | grep altair
altair             4.2.0
altair-data-server 0.4.1
altair-saver       0.5.0
altair-viewer      0.4.0
(py39venvxx) bash-5.1$
```

下記「map_altair.py」を実行するとコロプレスマップが生成されます。

```python
0001 import pyodbc
0002 import pandas as pd
0003 import altair as alt
0004 from altair_saver import save
0005 
0006 con = pyodbc.connect(
0007     'Driver={IBM i Access ODBC Driver}; '
0008     'System=localhost; UID=osswxx; PWD=osswxx;'
0009     )
0010 
0011 df = pd.read_sql("SELECT TKADR1, TKNURI FROM qeol.tokmsp", con)
0012 
0013 mapDict = {13121:'足立区',13105:'文京区',13101:'千代田区',13106:'台東区',
0014     13109:'品川区',13123:'江戸川区',13104:'新宿区',13113:'渋谷区',
0015     13117:'北区',13116:'豊島区',13102:'中央区',13115:'杉並区',
0016     13119:'板橋区',13112:'世田谷区',13107:'墨田区',13114:'中野区',
0017     13120:'練馬区',13108:'江東区',13110:'目黒区',13122:'葛飾区',
0018     13103:'港区',13111:'大田区',13118:'荒川区'}
0019 
0020 def addr2code(addr):
0021     mapCode = str([k for k, v in mapDict.items() if v in addr])[1:6]
0022     return mapCode if mapCode[:1] == '1' else '00000'
0023 
0024 df.loc[:, 'mapCode'] = df.TKADR1.map(addr2code)
0025 df = df[['mapCode', 'TKNURI']].groupby('mapCode', as_index=False).sum()
0026 df.rename(columns={'mapCode':'TKNURI'})
0027 
0028 url = "https://raw.githubusercontent.com/niiyz/"\
0029       "JapanCityGeoJson/master/topojson/custom/tokyo23.topojson"
0030 source = alt.topo_feature(url, "tokyo23")
0031 
0032 map = alt.Chart(source).mark_geoshape(
0033         stroke='pink', strokeWidth=1
0034 ).encode(
0035        alt.Color('TKNURI:Q', scale=alt.Scale(scheme='yellowgreenblue'),
0036                  legend=alt.Legend(title="当年度売上高")
0037                 ),
0038     tooltip=[alt.Tooltip('properties.N03_004:N', title="区"),
0039              alt.Tooltip('properties.N03_007:N', title="団体コード"),
0040              alt.Tooltip('TKNURI:Q', title="当年度売上高", format=',')]
0041 ).transform_lookup(
0042     lookup='properties.N03_007',
0043     from_=alt.LookupData(df, 'mapCode', ['TKNURI'])
0044 ).configure(
0045     background='#DDEEFF'
0046 ).configure_title(
0047     fontSize=24
0048 ).properties(
0049     title='当年売上高（東京２３区）',
0050     width=800,
0051     height=600
0052 )
0053 
0054 save(map, "./map_altair.html")
```

* 13～18行目：東京23区の全国地方公共団体コード(http://www.soumu.go.jp/denshijiti/code.html )をキー、区名を値とした辞書mapDictを定義。
* 24行目：DataFrameに右辺のmapメソッドで新しい列「mapCode」を追加し、これにTKADR1列の内容を関数addr2code()に渡した結果を格納。addr2code()はmapDict.items()(辞書の各要素のキーと値)をイテラブルオブジェクトとしたリスト内包表記(comprehension)で、辞書から仮変数vに取り出した値(区名)が渡された値(TKADR1)に含まれている場合にこれをstr型に変換する。戻り値は条件式(三項演算子)なので、辞書に見つかった場合はmapCodeを、以外は'00000'を返す。
* 25～26行目：DataFrameを列mapCodeでグループ化して計を求め、グループ化後の列名を再設定。

  ?> TopoJSON形式の詳細は https://github.com/topojson/topojson を参照。

* 28～30行目：TopoJSON形式 の東京23区の地形情報を読み込み。
* 32行目以降：Altaiで地図を描画し、htmlファイルとして保管。Altair全般の詳細は https://altair-viz.github.io/index.html を、35行目のschemeの設定値は https://vega.github.io/vega/docs/schemes/ を、40行目のformatは https://github.com/d3/d3-format を参照。

<br>

明確なドキュメントは見つけられませんでしたが、地形情報(TopoJSON)とAltairの指定の関連は下図のように推測されます。

![4.2.2_コロプレスマップ2.jpg](/files/4.2.2_コロプレスマップ2.jpg)

国別、県別、行政区別など各種の地形情報が利用可能であり、ニーズに合わせたコロプレスマップが作成できるでしょう。

?> この例では「JapanCityGeoJson 2020」(https://github.com/niiyz/JapanCityGeoJson )掲載の JapanCityGeoJson/topojson/custom/tokyo23.topojson を利用。

<br>

### 4.2.3 マーカー付き地図(folium)

可視化パッケージfoliumを利用して、外部サーバーのAPIで取得した座標情報に基づく「マーカー」を重ね合わせた地図を作成します。

?> ここでは国土地理院のAPIを利用。**公開サーバーには負荷をかけないように十分に留意**すること。

![4.2.3_マーカー付き地図.jpg](/files/4.2.3_マーカー付き地図.jpg)

外部サーバーのAPIを利用して住所から緯度/経度を取得し、地図の上にマーカーを描画します。マーカーをクリックするとポップアップが表示され、詳細情報を確認できます。

地図の移動や拡大/縮小、地図タイル(地図を正方形で分割したた平面状区画。地形、衛星画像、街路図などの種類あり)の変更などが可能です。

<br>

仮想環境からpipコマンドでパッケージfoliumをインストールします。

```bash
(py39venvxx) bash-5.1$ pip install folium
Collecting folium
  Downloading folium-0.14.0-py2.py3-none-any.whl (102 kB)
     ━━━━━━━━━━━━━━━━━ 102.3/102.3 KB 3.8 MB/s eta 0:00:00
Requirement already satisfied: jinja2>=2.9 in ./py39venvxx/lib/python3.9/site-packages (from folium) (3.1.2)
Requirement already satisfied: numpy in /QOpenSys/pkgs/lib/python3.9/site-packages (from folium) (1.21.4)
Collecting branca>=0.6.0
～～～～～～～～～～～～～～～ 中略 ～～～～～～～～～～～～～～～～～
Installing collected packages: branca, folium
Successfully installed branca-0.6.0 folium-0.14.0
 (py39venvxx) bash-5.1$
```

<br>


マーカー付き地図を生成するスクリプト「map_folium.py」のソースを示します。

```python
0001 import requests, urllib
0002 import pyodbc
0003 import pandas as pd
0004 # from tqdm import tqdm
0005 import folium
0006 
0007 con = pyodbc.connect(
0008     'Driver={IBM i Access ODBC Driver}; '
0009     'System=localhost; UID=osswxx; PWD=osswxx;'
0010     )
0011 
0012 df = pd.read_sql("SELECT TKBANG,TKNAKN,TKNAKJ,TKADR1,TKADR2,TKPOST,TKTELE,TKSIME "\
0013                  "FROM qeol.tokmsp", con)
0014 
0015 url = "https://msearch.gsi.go.jp/address-search/AddressSearch?q="
0016 def addr2coordinates(addr):
0017    resp = requests.get(url + urllib.parse.quote(addr), timeout=2)
0018    coor = resp.json()[0]["geometry"]["coordinates"]
0019    return coor[1], coor[0] # 緯度,経度
0020 
0021 df = df.applymap(lambda x: x.rstrip(" ""　") if isinstance(x, str) else x)
0022 # tqdm.pandas(desc="住所を座標(十進度の緯度/経度)に変換中")
0023 df[["緯度", "経度"]] = df.apply(lambda x: addr2coordinates(x["TKADR1"] + x["TKADR2"]),
0024 # df[["緯度", "経度"]] = df.progress_apply(lambda x: addr2coordinates(x["TKADR1"] + x["TKADR2"]), 
0025                      axis=1, result_type="expand")
0026 
0027 m = folium.Map(location=addr2coordinates("東京都港区"), zoom_start=10.5, min_zoom=9)
0028 
0029 folium.GeoJson(
0030    f"https://raw.githubusercontent.com/niiyz/JapanCityGeoJson/"\
0031     "master/geojson/custom/tokyo23.json", 
0032    name="geojson",
0033    style_function=lambda feature: {
0034       "fillColor": "royalblue", "color": "blue", "weight": 1
0035       }
0036    ).add_to(m)
0037 
0038 marker_colors = ['red','blue','gray','orange','green','purple']
0039 for i in range(0,len(df)):
0040    html=f"""
0041       <h3>{df.iloc[i]['TKNAKJ']}</h3>
0042       <ul>      
0043          <li>郵便番号：{df.iloc[i]['TKPOST']}</li>
0044          <li>住所：{df.iloc[i]['TKADR1'] + df.iloc[i]['TKADR2']}
0045             &nbsp;<a href="https://maps.google.com/maps?q={df.iloc[i]['緯度']},{df.iloc[i]['経度']}"
0046                target="_blank">Google Map</a></li>
0047          <li>電話番号：{df.iloc[i]['TKTELE']}</li>
0048          <li>締日コード：{df.iloc[i]['TKSIME']}</li>         
0049       </ul>
0050       """
0051    folium.Marker(
0052       location=[df.iloc[i]["緯度"], df.iloc[i]["経度"]],
0053       popup=folium.Popup(folium.IFrame(html=html, width=300, height=180)),
0054       icon=folium.Icon(color=marker_colors[int(df.iloc[i]["TKSIME"]) - 1], icon="info-sign")
0055    ).add_to(m)
0056 
0057 tiles = ['cartodbdark_matter', 'cartodbpositron', 'openstreetmap', 'stamenterrain', 
0058          'stamentoner', 'stamenwatercolor']
0059 for tile in tiles:
0060     folium.TileLayer(tile).add_to(m)
0061 folium.LayerControl().add_to(m)
0062 
0063 m.get_root().html.add_child(folium.Element('''
0064    <h2 align="center" style="font-size:20px"><b>東京２３区 得意先分布</b></h2>
0065 	'''))
0066 
0067 m.save(outfile="./map_folium.html")
```

* 4, 22, 24行目：コンソール(sshクライアントなど)から実行する際にプログレスバーを表示したい場合、4/22/24行目のコメント(「#」)を外し、23行目をコメントアウト。 
* 15～19行目：国土地理院のジオコーディングAPIで「住所」→「緯度/経度」変換を行う。一件ごとにサーバーにジオコーディングを要求しているのでサーバーの負荷状況によっては処理時間が長くなる。無償の公開サーバーを利用する場合は、顧客マスターに座標情報をあらかじめ追加しておく、1回あたりの処理件数を減らす。リクエスト間隔を設定して夜間にバッチで処理する、などを配慮。
* 27行目：「東京都港区」を中心として地図のベースを生成。
* 29～36行目：geojsonから東京23区の境界を地図ベースに追加。東京23区のgeojsonは「JapanCityGeoJson 2020」(https://github.com/niiyz/JapanCityGeoJson )のJapanCityGeoJson/geojson/custom/tokyo23.json掲載のデータを利用。
* 38～55行目：マーカーとポップアップを地図ベースに追加。DataFrameの「TKSIME」列の値に合わせてマーカーの色を変更。
* 57～60行目：地図タイルを追加し、選択可能とする。デフォルトは「openstreetmap」(街路図)。
* 63～65行目：地図のタイトルを設定。
* 67行目：地図をhtml形式で保管。

<br>

座標属性を付加した地図は、営業所や店舗の展開、地区別担当者の配置、配送・出荷割当てなどの計画立案に役立てる事ができます。

IBM iの7.4 TR7および7.5 TR1以降では地理空間情報がSQLで利用できます。この機能で追加の情報を付加し、PythonなどのOSSで解析・可視化すれば、既存データの新たな活用が可能になるでしょう。

?> 地理空間情報については「Geospatial Analytics」(https://www.ibm.com/support/pages/node/6828077 )を参照。

<br>

---

### (参考) 位置情報の取得の際の注意点

情報を地図にプロットするには、ジオコーディング(geocoding)と呼ばれる技術で施設名や住所などから、緯度(latitude)と経度(longitude)で表される地理座標(coordinates)を取得する必要があります。下記のような公開サービスが無償で利用できるので、商用サービスと合わせて比較・評価・選択する事をお勧めします。

?> IBMの「地理空間データ」(Geospatial data)は、座標情報に属性情報(関連するオブジェクト、イベントまたは現象の特性)と時間軸(位置と属性が存在する時間または寿命)を組み合わせたもの(参照：https://www.ibm.com/jp-ja/topics/geospatial-data )。

* 国土地理院の場所情報コードAPI (https://www.gsi.go.jp/sokuchikijun/sokuchikijun40025.html )：登録不要。利用条件を要確認。
* Google Geocoding API (https://developers.google.com/maps/documentation/javascript/geocoding?hl=ja )：APIキーが必要。無償枠を超えると有償。
* Yahoo!ジオコーダAPI (https://developer.yahoo.co.jp/webapi/map/openlocalplatform/v1/geocoder.html )：Yahoo! JAPAN IDと紐ついた「アプリケーションID」が必要

<br>

---

### (参考) データフレーム更新時の進捗表示

外部サーバーから位置情報を取得する際、サーバーの負荷低減や利用制限のために一定のインターバルが必要な場合があります。また、既存のデータに新たに位置情報を付加する場合、大量にリクエストを発行すると完了までに長時間を要します。

このような場合、進捗状況を表示すると作業計画が容易になります。パッケージtqdmを利用してDetaFrame更新の進捗状況を表示できます。仮想環境からpipコマンドでパッケージtqdmをインストールします。

```bash
(py39venvxx) bash-5.1$ pip install tqdm
Collecting tqdm
  Downloading tqdm-4.64.1-py2.py3-none-any.whl (78 kB)
   ━━━━━━━━━━━━━━━━━━━ 78.5/78.5 KB 3.0 MB/s eta 0:00:00
Installing collected packages: tqdm
Successfully installed tqdm-4.64.1
```

これをスクリプトに組み込むと下記のように表示されます。

```bash
(py39venvxx) bash-5.1$ python map_folium.py
住所を座標(十進度の緯度/経度)に変換中:  29%|██▊       | 60/210 [00:04<00:14, 10.43it/s]
```

開発・テスト・DB一括更新時などsshクライアントから長時間処理を実行する場合は便利に利用できるでしょう。

<br>

## 4.3 IBM iプログラムとの連携

OSS言語で開発されたプログラムを既存のアプリケーションに統合する際、多くの場合に次のような機能が必要になります。

?> 既存の開発プロセスとOSSの開発プロセスの調整が必要になるが、ここでは触れない。

**(A) Db2 for iの利用**

  Db2 for iのデータを介してプログラム間の連携を計る。Pythonからはpyodbcを利用してSQLでアクセス。

**(B) OSS(Python)⇔CL/RPGの相互呼出し**

  5250画面を利用する場合や、バッチジョブにOSSプログラムによる処理を組み込む場合など、PythonなどのOSS言語と、CLやRPGの既存アプリケーション間で相互呼出しを行う。

**(C) IBM i上の既存システム(Webやジョブネット)への組み込み**

  日次バッチなど、実行順序の制御や実行結果による分岐処理が要件となる場合は、(拡張)ジョブスケジューラーやOSSのスケジューラー(Rundeckなど)によるジョブネットの構築も選択肢となる。

  * 2022年6月1日付で「拡張ジョブスケジューラー」を含むいくつかのライセンス・プログラムが無償化された。詳細はIBMサポートページの「IBM i Portfolio Simplification」(https://www.ibm.com/support/pages/ibm-i-license-topics )を参照。
  * RundeckはOSSのジョブスケジューラー。詳細は https://www.rundeck.com/ 参照。

<br>

以下では(B)の相互呼出しの例を解説します。

<br>

### 4.3.1 PythonとCL/RPGの相互呼出し

<br>

<u>**PythonからCL/RPGを呼び出し**</u>

PythonからCL/RPGを呼び出すにはsubprocessによるシステムコール、IBM i独自機能のPASE systemコマンド、QCMDEXC IBM iサービス(SQL)、XMLSERVICEベースのitoolkitなどが利用できます。

<br>

Ⓐ PythonのsubprocessでCLコマンドを実行します。

```python
bash-5.1$ python
Python 3.6.15 (default, Dec 17 2021, 09:57:34)
[GCC 6.3.0] on aix7
Type "help", "copyright", "credits" or "license" for more information.
>>> import sys,subprocess
>>> res = subprocess.run(["system", "wrkactjob sbs(qinter)"], stdout=subprocess.PIPE)
>>> sys.stdout.buffer.write(res.stdout)
                                          活動ジョブの処理                                                          ページ    1
～～～～～～～～～～～～～～～ 後略 ～～～～～～～～～～～～～～～～～
```

<br>

Ⓑ pyodbcのSQLからQCMDEXCスカラー関数でCLコマンドを実行します。業務に組み込む場合は、IBM i側にストアドプロシージャーを作成して呼び出しても良いでしょう。

?> QCMDEXCスカラー関数の詳細はIBM Docsの「QCMDEXC スカラー関数」(https://www.ibm.com/docs/ja/i/7.5?topic=services-qcmdexc-scalar-function )を参照。

```python
bash-5.1$ python
Python 3.6.15 (default, Dec 17 2021, 09:57:34)
[GCC 6.3.0] on aix7
Type "help", "copyright", "credits" or "license" for more information.
>>> import pyodbc
>>> conn=pyodbc.connect('Driver={IBM i Access ODBC Driver};System=localhost;UID=osswxx;PWD=osswxx;')
>>> cursor=conn.cursor()
>>> cursor.execute("{select case when qsys2.qcmdexc('wrkactjob sbs(qinter)') = 1 then 'OK' else 'NG' end as result from sysibm.sysdummy1 fetch first 1 row only}")
<pyodbc.Cursor object at 0x7000000002dbc60>
>>> print(cursor.fetchone())
('OK', )
>>> cursor.close()
>>> conn.close()
>>> exit()
```

<br>

Ⓒ IBM i独自の「itoolkit for Python」でもプログラム呼出しを行うことができます。itoolkitはPython用のXMLSERVICE インターフェースで、PythonからIBM iのリソース(プログラムやデータベース)へのアクセスを可能にします。

?> 「itoolkit for Python」は、Read the Docs (https://python-itoolkit.readthedocs.io/en/latest/index.html )でドキュメント、GitHub (https://github.com/IBM/python-itoolkit )でコード、PyPI (https://pypi.org/project/itoolkit/ )でディストリビューションが、それぞれ利用可能。

?> XMLSERVICEは2015年頃よりIBM i 7.xで「IBM HTTP Server for i」(5770-DG1)の一部としてライブラリーQXMLSERVに導入される。PHPやNode.jsなど他のOSSからも利用可能。詳細はRead the Docs (https://xmlservice.readthedocs.io/en/latest/intro.html )、GitHub (https://github.com/IBM/xmlservice )、「Young i Professionals」(http://youngiprofessionals.com/wiki/index.php/XMLSERVICE/XMLSERVICE )などを参照。

sshから下記コマンドを実行すれば導入済みitoolkitのバージョンを確認できます。

```bash
bash-5.1$ python -c "import itoolkit; print(itoolkit.__version__)"
1.6.1
```

<font size="-2">
  ※ 5250画面から「call qp2term」でPASEシェルを起動し、「/QOpenSys/pkgs/bin/python3.6 -c "import itoolkit; print(itoolkit.__version__)”」を実行しても同様の結果が得られます。
</font>

<p>　</p>



Pythonからitoolkitを利用してRPGをパラメーター付きで呼び出す例を見てみましょう。第一パラメーターで「名前」を指定すると、前後に文字列を付加して第二パラメーターで「あいさつ」を返します。

OPM-RPG(RPG/400)プログラム「OSSWXX/OPMRPG」のソースです。CAT命令で文字列を連結しています。

```
0001.00      C           *ENTRY    PLIST                        
0002.00      C                     PARM           NAME   32     
0003.00      C                     PARM           RESP   32     
0004.00       *                                                 
0005.00      C                     MOVEL' さん '  TITLE  10     
0006.00      C                     MOVEL'HELLO'   GREET  10     
0007.00      C           GREET     CAT  NAME:1    RESP          
0008.00      C                     CAT  TITLE:0   RESP          
0009.00      C                     SETON                     LR
```

こちらは同じ動作をする完全フリー形式のILE-RPGプログラム「OSSWXX/ILERPG」です。

```
0001.00 **free                                                        
0002.00 CTL-OPT MAIN(ilerpg);                                         
0003.00 CTL-OPT ACTGRP(*NEW) OPTION(*SRCSTMT : *NODEBUGIO : *NOUNREF);
0004.00                                                               
0005.00 DCL-PROC ilerpg;                                              
0006.00   DCL-PI *N EXTPGM;                                           
0007.00     name CHAR(32);                                            
0008.00     resp CHAR(32);                                            
0009.00   END-PI;                                                     
0010.00   resp = ' こんにちは ' + %TRIM(name) + ' さん ';             
0011.00 END-PROC;                                                     
```

Pythonスクリプト「itk_callpgm.py」は、CHGCURLIBコマンドを発行し、パラメーター付きでOPMRPG、ILERPGを呼び出して結果を表示します。

```python
0001 from itoolkit import *
0002 from itoolkit.lib.ilibcall import *
0003 
0004 itransport = DirectTransport()
0005 itool = iToolKit()  # Toolkit Object
0006 
0007 itool.add(iCmd("cmd_chgcurlib", "chgcurlib osswxx"))
0008 itool.call(itransport)
0009 if 'success' in itool.dict_out("cmd_chgcurlib"):
0010     print("正常終了") 
0011 else:
0012     print("エラー発生")
0013     exit()
0014 print(itool.dict_out("cmd_chgcurlib"))
0015 
0016 itool.clear()
0017 itool.add(iPgm("call_opmpgm","OPMRPG")
0018     .addParm(iData("name","32A","鈴木"))
0019     .addParm(iData("resp","32A",""))
0020 )
0021 itool.call(itransport)
0022 print(itool.dict_out("call_opmpgm").get("resp"))
0023 print(itool.dict_out("call_opmpgm"))
0024 
0025 itool.clear()
0026 itool.add(iPgm("call_ilepgm","ILERPG")
0027     .addParm(iData("name","32A","山本"))
0028     .addParm(iData("resp","32A",""))
0029 )
0030 itool.call(itransport)
0031 print(itool.dict_out("call_ilepgm").get("resp"))
0032 print(itool.dict_out("call_ilepgm"))
```

* 4行目：itoolkit (XMLSERVICE)のTransportにはHTTP、Database、SSH、Directの4種があり、例では最も高速で追加の構成が不要なDirectを利用。RPGプログラムが異なるサーバーで動作する場合は他のTransportを選択。
* 5行目：itoolkitのオプジェクトを「itool」という名前で作成。以降はこのオブジェクトを操作。
* 7～14行目：itool.add()で実行する機能を登録し、itool.call()で機能を実行。結果は指定した機能の第一パラメーターで指定したキー(例では「"cmd_chgcurlib"」)で識別される。itool.dict_out("キー名")で結果を取得し、内容(パラメーターの戻り値や「success」などの実行結果)を参照して処理を行う。

<br>

このスクリプトを実行すると下記のように表示されます。

```bash
bash-5.1$ python itk_callpgm.py
正常終了
{'success': '+++ success chgcurlib osswxx'}
HELLO 鈴木さん
{'name': '鈴木', 'resp': 'HELLO 鈴木さん', 'success': '+++ success  OPMRPG'}
こんにちは山本さん
{'name': '山本', 'resp': 'こんにちは山本さん', 'success': '+++ success  ILERPG'}
```

<br>

<u>**CL/RPGからPythonを呼出し**</u>

CLあるいはRPGからPythonのスクリプトを呼び出すにはいくつかの手法があります。下表に例を挙げます。

|手法|対話/バッチ|備考|
|----|----------|----|
|① CLの<font color="blue">STRQSH(またはQSH)</font>コマンドからPythonスクリプトを呼び出すPASEコマンドを実行|対話またはバッチ|標準入出力をQSH CLコマンドまたはAPIプログラムQP2TERMが制御。|
|② 5250対話型セッションからCLでコマンド「<font color="blue">CALL QP2TERM</font>」を実行してPASEシェル画面を起動し、PASEコマンドを実行|対話|(同上)|
|③ <font color="blue">QP2SHELL</font>または<font color="blue">QP2SHELL2</font>プログラムの引き数にPASEコマンドを指定|バッチ|標準ストリームを使用する場合に考慮点あり|
|④ QshellまたはPASE環境から<font color="blue">ssh</font>コマンドの引き数にPASEコマンドを指定|バッチ|遠隔IBM iサーバー上のPASE機能を実行可能。|
|⑤ QshellからPASEの<font color="blue">expect</font>コマンドで「ssh接続～コマンド実行」を自動化|バッチ|(同上)|
|⑥ Qshellの<font color="blue">rexec</font>コマンドの引き数にPASEコマンドを指定|バッチ|(同上)|
|⑦ <font color="blue">HTTPサーバー</font>を構築し、PythonをCGIプログラムとして呼出し|対話|Webサービス的に実装すればバッチ化も容易。|

?> ③では考慮点として、IBM Docsの「QP2SHELL() を使用した IBM PASE for i プログラムの実行」(https://www.ibm.com/docs/ja/i/7.3?topic=procedures-running-pase-i-program-qp2shell )に、これらのプログラムで標準入出力の信頼性を確保するには追加のプログラム(新しいプロセスを生成してpipeを割り当てる)が必要との記載有り。

IBMは①を推奨していますが、コマンド文字列にDBCSが使用できない事に留意ください。以降では①から⑥のそれぞれの手法により、シンプルなPythonスクリプト(パラメーターで「名前」を渡すと前後に文字列を追加して出力)を呼び出す例を紹介します。

?> ①については「How to Call PASE Commands/Scripts from a Command Line, CL Program, or in a Submitted Job」(https://www.ibm.com/support/pages/how-call-pase-commandsscripts-command-line-cl-program-or-submitted-job )を参照。

<br>

**「Pythonスクリプト /home/OSSWXX/helloPase.py」**

```python
0001 import sys
0002 print('Hello ' + sys.argv[1] + ' san.')
```

* 2行目：引き数の前後に「Hello 」と「 san.」を追加して標準出力に書き出し。 

<br>

①	CLのSTRQSH(またはQSH)コマンドからPythonスクリプトを呼び出すPASEコマンドを実行。(この例では5250**対話型**セッションから実施)

```
> QSH⏎
```
```
                               QSH コマンド入力              
                                                             
   $                                                         
 > /QOpenSys/pkgs/bin/python /home/OSSWXX/helloPase.py John⏎
   Hello John san.                                           
   $                                                         
```

<br>

②	5250対話型セッションからCLでコマンド「CALL QP2TERM」を実行してPASEシェル画面を起動し、**対話型**でPASEコマンドを実行

```
> CALL PGM(QP2TERM)⏎
```
```
                             /QOpenSys/usr/bin/-sh           
                                                             
   $                                                         
 > /QOpenSys/pkgs/bin/python /home/OSSWXX/helloPase.py John⏎
   Hello John san.                                           
   $                                                         
```

<br>

③	QP2SHELLまたはQP2SHELL2プログラムの引き数にPASEコマンドを指定

```
> CALL PGM(QP2SHELL) PARM(('/QOpenSys/pkgs/bin/python') ('/home/OSSWXX/hell
  oPase.py') ('John'))⏎                                                  

  Hello John san.                                      
   実行キーを押して端末セッションを終了してください。  
```

<br>

④	QshellまたはPASE環境からsshコマンドの引き数にPASEコマンドを指定 

?> IBM iからHMCのsshサーバーに接続して資源移動を行うなどの用途で20年くらい前から利用例有り。sshで自動ログオンするため、事前に公開鍵を生成・登録する必要がある。詳細はIBMのサポート文書「Sending HMC Commands from a CL Program」(https://www.ibm.com/support/pages/sending-hmc-commands-cl-program )などを参照。

```
> CRTSRCPF FILE(OSSWXX/STDOUT) RCDLEN(132) MBR(STDOUT) IGCDTA(*YES) CCSID(5
  035)⏎                                                                 
   ライブラリー OSSWXX にファイル STDOUT が作成された。       
   メンバー STDOUT が OSSWXX のファイル STDOUT に追加された。
> OVRDBF FILE(STDOUT) TOFILE(OSSWXX/STDOUT)⏎                        
> QSH CMD('ssh osswxx@ibmi /QOpenSys/pkgs/bin/python /home/OSSWXX/helloPase
  .py John')⏎                                
   コマンドは終了状況 0 で正常に終了しました。                             
> STRSEU SRCFILE(OSSWXX/STDOUT) SRCMBR(STDOUT)⏎                         

        ****************** データの始め ******************
0001.00 Hello John san.                                   
        ***************** データの終わり ***************** 
```

<br>

⑤	QshellからPASEのexpectコマンドで「ssh接続～コマンド実行」を自動化

?> expectはtelnetやftpなどとの対話処理を自動化するコマンド。詳細はhttps://core.tcl-lang.org/expect/index参照。

(事前設定：expectスクリプトの作成)
```
> QSH CMD('touch -C 1208 /home/OSSWXX/login.txt')⏎
   コマンドは終了状況 0 で正常に終了しました。  
> EDTF STMF('/home/OSSWXX/login.txt')⏎

     ************* データの始め ****************                     
    set timeout 5                                                    
    spawn ssh osswxx@ibmi                                            
    expect "assword:"                                                
    send "osswxx\n"                                                  
    expect "\\\$"                                                    
    send "/QOpenSys/pkgs/bin/python /home/OSSWXX/helloPase.py John\n"
    expect "\\\$"                                                    
    send "exit\n"                                                    
    exit                                                             
     *********** データの終わり ******************                   
```
(EDT画面から「F15= 保守」を起動し、「5. ｽﾄﾘｰﾑ･ﾌｧｲﾙ の EOL ｵﾌﾟｼｮﾝ」に*LFを指定)
```
                                  EDTF のオプション画面                         
                                                                                
  選択項目 . . . . . . . . . . . .     5                                        
                                                                                
 1.  コピー元 ﾇnﾒｰw､ﾎｦbﾓ   . . . .     /home/OSSWXX/login.txt                
～～～～～～～～～～～～～～～ 中略 ～～～～～～～～～～～～～～～～～
 3.  ファイルの CCSID の変更 . . .     01208     ジョブ CCSID: 01399            
                                                                                
 4.  行の CCSID の変更 . . . . . .     *NONE                                    
                                                                                
 5.  ﾇnﾒｰw､ﾎｦbﾓ の EOL eﾎﾟﾆｭ]. . .  *LF      *CR, *LF, *CRLF, *LFCR, *USRDFN
      ユーザー定義 . . . . . . . .              16 進値                         
```
(実行)
```
> ADDENVVAR ENVVAR(QIBM_MULTI_THREADED) VALUE(Y) REPLACE(*YES)⏎   
   環境変数が追加された。                          
> CRTSRCPF FILE(OSSWXX/STDOUT) RCDLEN(132) MBR(STDOUT) IGCDTA(*YES) CCSID(5
  035)⏎                                                                 
   ライブラリー OSSWXX にファイル STDOUT が作成された。       
   メンバー STDOUT が OSSWXX のファイル STDOUT に追加された。
> OVRDBF FILE(STDOUT) TOFILE(OSSWXX/STDOUT)⏎
> QSH CMD('/QOpenSys/usr/bin/sh -c "export PATH=/QOpenSys/pkgs/bin:$PATH ;
  cd /home/OSSWXX/ ; expect login.txt"')⏎                               
   コマンドは終了状況 0 で正常に終了しました。                            
> STRSEU SRCFILE(OSSWXX/STDOUT) SRCMBR(STDOUT)⏎                          
```
```
        ****************** データの始め ************************************
0001.00 spawn ssh osswxx@ibmi                                               
0002.00  osswxx@ibmi's password:                                            
0003.00 bash-5.1$ /QOpenSys/pkgs/bin/python /home/OSSWXX/helloPase.py John  
0004.00 Hello John san.                                                     
0005.00 bash-5.1$                                                           
        ***************** データの終わり ***********************************
```

<br>

⑥	Qshellのrexecコマンドの引き数にPASEコマンドを指定

```
> CRTSRCPF FILE(OSSWXX/STDOUT) RCDLEN(132) MBR(STDOUT) IGCDTA(*YES) CCSID(5
  035)⏎                                                                 
   ライブラリー OSSWXX にファイル STDOUT が作成された。       
   メンバー STDOUT が OSSWXX のファイル STDOUT に追加された。
> OVRDBF FILE(STDOUT) TOFILE(OSSWXX/STDOUT)⏎
> QSH CMD('rexec -C 932 -p (パスワード) -u (ユーザー) localhost "qsh cmd(''
  /QOpenSys/pkgs/bin/python /home/OSSWXX/helloPase.py John'')"')⏎         
   コマンドは終了状況 0 で正常に終了しました。                             
> STRSEU SRCFILE(OSSWXX/STDOUT) SRCMBR(STDOUT)⏎ 
```
```
        ****************** データの始め ******************
0001.00  Hello John san.                                  
0002.00                                                   
        ***************** データの終わり ***************** 
```

<br>

これら以外にも、API Qp2RunPase (Run an IBM PASE for i Program)を利用したプログラムを開発する、Ansibleに登録して実行する、などの方法があります。

なお、CL/RPG(IBM i)はEBCDIC、Python(PASE)はASCII(UTF-8)と、文字コードが異なります。Qshell(およびqsh_inoutやsystemなどの一部PASEユーティリティー)とQP2TERMは、IBM iがEBCDIC⇔ASCII変換を行いますが、これら以外では変換が行われない 点に注意が必要です。

sshやrexecなどで遠隔サーバーに接続する場合、セキュリティ要件 に沿った実装を考慮すべきでしょう。例えばユーザーIDとパスワードの管理、通信経路の制限、アクセス制御と状況の監視などを検討します。また、サーバーとクライアントの双方でアプリケーションからログに出力しておけば、問題判別や性能評価が容易になります。

?> Ansibleの詳細は「Automate your IBM i tasks with Ansible」(https://ibm.github.io/cloud-i-blog/archivers/2020_0602_automate_your_ibm_i_tasks_with_ansible )などを参照。

?> 文字コード変換の詳細は「IBM PASE for i コマンド」(https://www.ibm.com/docs/ja/i/7.5?topic=utilities-pase-i-commands )を参照。変換の対象には、PASE環境に渡す文字列、標準入出力、ファイルとの入出力などがあり、必要に応じてDBCS(漢字など)を含めたテストの実施を推奨。

?> すべてのIBM iユーザーにおいて、システム値QSECURITYを40以上に設定し、資源機密保護と出口プログラムの設定、監査ログの取得などによるセキュリティの確保を推奨。例えば下記のような事項が「抜け穴」になりやすい。<br>・SQL(ODBC、JDBCを含む)のQCMDEXCプロシージャー、RMTCMD(遠隔コマンド)などはユーザー・プロフィールのLMTCPB(制限機能)パラメーター指定の適用対象外<br>・ftp、ssh、rexecなどCLコマンドが実行できるクライアント接続

<br>

### (参考) Qshell環境変数

CLからQshell経由でPASE環境を起動する際、動作を制御する環境変数がいくつか提供されています。その中で主要と思われる環境変数を下表に示します。

?> 全ての定義済み環境変数はIBM Docsの「変数」(https://www.ibm.com/docs/ja/i/7.5?topic=language-shell-variables )を参照。

|環境変数|説明|初期値|
|-------|----|------|
|QIBM_QSH_CMD_ESCAPE_MSG|値が「Y」の場合、QSH0006およびQSH0007 メッセージが常にエスケープ・メッセージとして送信され、終了状況がゼロより大きいときは、QSH0005メッセージもエスケープ・メッセージとして送信される|なし|
|QIBM_QSH_CMD_OUTPUT|設定値によりQSH CLコマンドからの出力を制御。<br>・「STDOUT」：出力をCランタイム端末セッションに表示<br>・	「NONE」出力を廃棄<br>・「FILE」：出力を指定したファイルに書き出し<br>・「FILEAPPEND」：出力を指定されたファイルに追加	|STDOUT|
|QIBM_MULTI_THREADED|qshが開始するプロセスが複数のスレッドを作成できるかどうかを決定。この変数の値が「Y」であれば、qshが開始するすべての子プロセスが スレッドを開始可能|N|
|QSH_REDIRECTION_TEXTDATA|リダイレクトに指定されたファイルから読み取るデータ、またはそのファイルに書き込むデータを、テキスト・データとして取り扱うか(値が「Y」)、2進データとして取り扱うか(値が「Y」以外)を決定|Y|

CLプログラム内でQSHコマンドのエラーをMONMSGコマンドで検出するには、環境変数QIBM_QSH_CMD_ESCAPE_MSGを「Y」に設定する必要があります。

ファイル「STDOUT」をOVRDBFコマンドで指定変更すれば、通常は画面に表示される標準出力をファイルに書き出すことができます。同様に、環境変数QIBM_QSH_CMD_OUTPUTに直接「FILE=(IFSパス名)」と指定すれば、そのファイルに標準出力が書き出されます。

?> 同様の手法はIBMサポート文書「CL Program that Calls QSHELL to Run a Java Class」(https://www.ibm.com/support/pages/cl-program-calls-qshell-run-java-class )などに利用例有り。

IBMはPASEをQshellの子プロセスとして起動する方法を推奨していまが、QSHコマンドからPASEプログラムを呼び出す場合、環境変数QIBM_MULTI_THREADEDを「Y」に変更しないと動作しない場合があります。

?> 詳細はIBMサポート文書「How to Call PASE Commands/Scripts from a Command Line, CL Program, or in a Submitted Job」(https://www.ibm.com/support/pages/how-call-pase-commandsscripts-command-line-cl-program-or-submitted-job )を参照。

<br>

### (参考) プログラム間連携の考慮点

IBM iのOPM/ILE言語とPythonなどPASE環境で稼働する言語間で連携を行う際にはいくつか考慮点があります。下表は「OSS(Python)⇔CL/RPGの相互呼出し」の手法と呼び出し先が情報を返す方法の例を示しています。

|呼び出し|手法|呼び出し先からの情報|
|--------|----|---------------------|
|PythonからCL/RPGを呼び出し|Ⓐ PythonのsubprocessでCLコマンドを実行|Pythonの標準出力|
||Ⓑ pyodbcのSQLからQCMDEXCスカラー関数 でCLコマンドを実行|コマンドの成否|
||Ⓒ「itoolkit for Python」でプログラム呼出し|パラメーター変数|
|CL/RPGからPythonを呼出し|① CLのSTRQSH(またはQSH)コマンドからPythonスクリプトを呼び出すPASEコマンドを実行|QSHコマンド実行結果(MONMSGで監視)|
||②～③|(省略)|
||④ QshellまたはPASE環境からsshコマンドの引き数にPASEコマンドを指定|QSHコマンド実行結果(MONMSGで監視)、および標準出力|
||⑤ QshellからPASEのexpectコマンドで「ssh接続～コマンド実行」を自動化|(同上)|
||⑥ Qshellのrexecコマンドの引き数にPASEコマンドを指定	|(同上)|
||⑦ HTTPサーバーを構築し、PythonをCGIプログラムとして呼出し|HTTPレスポンス|

<br>

IBM iでCL/RPG/COBOLなどの言語間呼び出しを行う際は、呼び出された側がパラメーターに値をセットすれば呼び出し元でこの値を参照できます。一方、Pythonを含むほとんどのスクリプト言語は、通常は、パラメーターの値を変更して呼び出し元に返すことはできません。

?> パラメーターの渡し方のデフォルトが「参照渡し」であるため。詳細はIBM Docsの「パラメーターの受け渡しスタイル」(https://www.ibm.com/docs/ja/i/7.5?topic=parameters-parameter-passing-styles )などを参照。

また、CL/RPGからPythonを呼出す場合、PASE環境は呼び出し元と異なるプロセスで起動するため、OPM/ILEへ値を返すために下記のような方法を検討する必要があるでしょう。

* ストリーム・ファイルやデータベースなどの永続オブジェクトで情報を共有
* プロセス間通信手法(ソケット、名前付きパイプなど)やメッセージ・キューイング

<br>

### (参考) パターン① QSH→Pythonスクリプト呼び出の実装例。

比較的実装が容易な①のパターンで、Pythonスクリプトを実行した結果をCLプログラムで取得・表示する例を見てみましょう。

5250画面セッションからCLプログラムを「名前」をパラメーターに指定してCALLすると、そのセッションにPythonスクリプトが前後に文字列を付加したメッセージを返します。CLPとPython間の連携概要を下図に示します。

?> 同じプログラムをSBMJOBでバッチに投入すると端末名(=ジョブ名)が存在しないためエラーになる。①のパターンをバッチで実行する場合、SBMJOBコマンドでパラメーター「LOG(4 0 \*SECLVL) LOGCLPGM(*YES)」を指定してジョブログを出力すれば実行状況が確認可能。

![パターン①.jpg](/files/パターン①.jpg)

(実行例)
```
> CALL PGM(CLP2PY) PARM(('John'))
                                 メッセージ表示                          
～～～～～～～～～～～～～～～ 中略 ～～～～～～～～～～～～～～～～～
  応答を入力して（必要な場合），実行キーを押してください。               
    送信元 . . :   OSSWXX         23/02/XX   XX:43:13                    
    こんにちは、 John さん。                                             

   スクリプト実行完了。

> CALL PGM(CLP2PY) PARM((' '))    

～～～～～～～～～～～～～～～ 中略 ～～～～～～～～～～～～～～～～～
    送信元 . . :   OSSWXX         23/02/XX   XX:43:56         
    パラメーターが必要です。                                  

   スクリプト実行エラー。  
```

**「CLプログラムCLP2PY」**

```
0001.00              PGM        PARM(&NAME)                                             
0002.00              DCL        VAR(&QSHCMD) TYPE(*CHAR) LEN(256)                       
0003.00              DCL        VAR(&JOBCCSID) TYPE(*DEC) LEN(5 0)                      
0004.00              DCL        VAR(&NAME) TYPE(*CHAR) LEN(32)                          
0005.00              DCL        VAR(&REQUESTER) TYPE(*CHAR) LEN(10)                     
0006.00                                                                                 
0007.00              ADDENVVAR  ENVVAR(QIBM_QSH_CMD_ESCAPE_MSG) VALUE(Y) REPLACE(*YES)  
0008.00              ADDENVVAR  ENVVAR(QIBM_USE_DESCRIPTOR_STDIO) VALUE(Y) REPLACE(*YES)
0009.00              RTVJOBA    JOB(&REQUESTER) CCSID(&JOBCCSID)                        
0010.00              CHGJOB     CCSID(5035)                                             
0011.00                                                                                 
0012.00              CHGVAR     VAR(&QSHCMD) VALUE( +                                   
0013.00                           '/QOpenSys/pkgs/bin/python /home/OSSWXX/clp2py.py' +  
0014.00                           |> &REQUESTER |> &NAME)                               
0015.00                                                                                 
0016.00              QSH        CMD(&QSHCMD)                                            
0017.00              MONMSG     MSGID(QSH0000) EXEC(DO)                                 
0018.00                SNDPGMMSG  MSG(' スクリプト実行エラー。 ')                       
0019.00                GOTO       CMDLBL(NEXT)                                          
0020.00              ENDDO                                    
0021.00              SNDPGMMSG  MSG(' スクリプト実行完了。 ') 
0022.00                                                       
0023.00  NEXT:       CHGJOB     CCSID(&JOBCCSID)              
0024.00              ENDPGM                                   
```

* 7行目：環境変数QIBM_QSH_CMD_ESCAPE_MSGを設定し、Qshellからのメッセージをエスケープ・メッセージとしてMONMSGで監視。
* 8行目：Pythonスクリプトの標準出力が5250側に表示されないようにILE環境変数QIBM_USE_DESCRIPTOR_STDIOを設定。
* 12～14行目：「ジョブ名」(対話型は表示装置名)と「名前」を引き数としてPythonスクリプトを呼出し。Pythonの標準出力をファイルにリダイレクトすればログとして記録可能。

<br>

**「Pythonスクリプト /home/OSSWXX/clp2py.py」**

```python
0001 import sys, subprocess
0002 
0003 if len(sys.argv) > 2 :
0004     cmdStr = "SNDBRKMSG MSG('こんにちは、" + sys.argv[2] + \
0005              "さん。') TOMSGQ(" + sys.argv[1]  + ")"
0006 else :
0007     cmdStr = "SNDBRKMSG MSG('パラメーターが必要です。') TOMSGQ(" + \
0008              sys.argv[1]  + ")"
0009 
0010 res = subprocess.run(["system", "-v", cmdStr], stdout=subprocess.PIPE)
0011 sys.stdout.buffer.write(res.stdout)
0012 print()
0013 cmdRc = res.returncode
0014 print("実行したCLのリターンコード:" + str(cmdRc))
0015 
0016 if len(sys.argv) < 3 or cmdRc > 0 :
0017     print("エラーで終了。")
0018     sys.exit(1)
0019 else :
0020     print("正常終了。")
```

* 3行目：Pythonスクリプトには第一引き数に「スクリプト名」が渡されるので、引き数の数は3となる。
* 10行目：3～8行で組み立てたCLコマンドをPASEのsystemユーティリティーで実行するため、Pythonのsubprocessを利用。11～14行で標準出力に結果を表示。

<br>

### <u>ワーク9 CL/RPGとPythonの相互呼出し</u>

**□ W9-1.** (PythonからCL/RPGを呼出し) PythonのsubprocessでCLコマンドを実行。sshでIBM iにログインし、Pythonの対話型セッションからCLコマンドを実行して結果が表示される事を確認。

```python
bash-5.1$ python
Python 3.6.15 (default, Dec 17 2021, 09:57:34)
[GCC 6.3.0] on aix7
Type "help", "copyright", "credits" or "license" for more information.
>>> import sys,subprocess
>>> res = subprocess.run(["system", "wrkactjob sbs(qinter)"], stdout=subprocess.PIPE)
>>> sys.stdout.buffer.write(res.stdout)
                                          活動ジョブの処理                                                          ページ    1
～～～～～～～～～～～～～～～ 後略 ～～～～～～～～～～～～～～～～～
```

**□ W9-2.** (CL/RPGからPythonを呼出し) 自身のホームディレクトリ(「~」)にスクリプト「./helloPase.py」を作成。

```python
0001 import sys
0002 print('Hello ' + sys.argv[1] + ' san.')
```

5250のコマンド入力画面からこのスクリプトを引き数付きで呼出し。

```
> QSH CMD('/QOpenSys/usr/bin/sh -c "/QOpenSys/pkgs/bin/python /home/OSSWXX/
  helloPase.py John"')                                                     

   Hello John san.                                         
    実行キーを押して端末セッションを終了してください。     
```

<br>

### 4.3.2 PythonのWebアプリケーション

前節の「⑦ HTTPサーバーを構築し、PythonをCGIプログラムとして呼出し」を実装すれば、文字列をPythonスクリプトから呼び出し元のCL/RPGプログラムに戻すことができます。以下では、ILE-RPGからCGI経由でPythonスクリプトを呼び出し、結果を表示する例を紹介します。

<u>**1) HTTPサーバーの作成**</u>

はじめに5250画面からCLコマンドを利用して新規HTTPサーバーを構築します。ホスト・コード・ページを5035または1399に設定した5250画面セッションを起動して以降の手順を実施します。

?> Webブラウザから「IBM Web Administrator for i」(http://(IBMiのホスト名またはIPアドレス):2001/HTTPAdmin )にアクセスすれば、「HTTP サーバーの作成」ウィザードが利用できる。いずれかの方法で新規HTTPサーバーを作成。

?> IBMのサポート文書「How to Manually Create a HTTP Server」(https://www.ibm.com/support/pages/how-manually-create-http-server )にHTTPサーバー構築手順の記載あり。権限エラーになる場合はコマンド「CHGAUT OBJ('/www/osswxx') USER(*PUBLIC) DTAAUT(*RX)」の要領で必要な権限を付与。

下図のディレクトリー構成を作成します。必要に応じてディレクトリー/ファイルのパーミッションを設定してください。

![HTTPサーバーのディレクトリー構成.jpg](/files/HTTPサーバーのディレクトリー構成.jpg)

```
> MKDIR DIR('/www/osswxx')        
   ディレクトリーが作成された。   
> MKDIR DIR('/www/osswxx/conf')   
   ディレクトリーが作成された。   
> MKDIR DIR('/www/osswxx/htdocs') 
   ディレクトリーが作成された。   
> MKDIR DIR('/www/osswxx/logs')   
   ディレクトリーが作成された。   
```

次にHTTPサーバーの構成ファイル「httpd.conf」を作成します。このファイルは文字コードUTF-8(CCSID 1208)、改行コードが*LFのテキストファイルです。

```
> QSH CMD('touch -C 1208 /www/osswxx/conf/httpd.conf') 
   コマンドは終了状況 0 で正常に終了しました。         
> EDTF STMF('/www/osswxx/conf/httpd.conf')                
```

Pythonスクリプトを実行するために下記のように設定します。

![HTTPサーバーのディレクトリー構成2.jpg](/files/HTTPサーバーのディレクトリー構成2.jpg)

**「http構成ファイル /www/osswxx/conf/httpd.conf」**

```
0001 Listen *:200xx
0002 DocumentRoot /www/osswxx/htdocs
0003 TraceEnable Off
0004 Options -FollowSymLinks
0005 LogFormat "%h %T %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
0006 LogFormat "%{Cookie}n \"%r\" %t" cookie
0007 LogFormat "%{User-agent}i" agent
0008 LogFormat "%{Referer}i -> %U" referer
0009 LogFormat "%h %l %u %t \"%r\" %>s %b" common
0010 CustomLog logs/access_log combined
0011 LogMaint logs/access_log 7 0
0012 LogMaint logs/error_log 7 0
0013 SetEnvIf "User-Agent" "Mozilla/2" nokeepalive
0014 SetEnvIf "User-Agent" "JDK/1\.0" force-response-1.0
0015 SetEnvIf "User-Agent" "Java/1\.0" force-response-1.0
0016 SetEnvIf "User-Agent" "RealPlayer 4\.0" force-response-1.0
0017 SetEnvIf "User-Agent" "MSIE 4\.0b2;" nokeepalive
0018 SetEnvIf "User-Agent" "MSIE 4\.0b2;" force-response-1.0
0019 CGIJobCCSID 5035
0020 DefaultNetCCSID 1208
0021 <Directory />
0022      Require all denied
0023 </Directory>
0024 <Directory /www/osswxx/htdocs>
0025      Require all granted
0026 </Directory>
0027 
0028 AddType application/x-httpd-python .py
0029 Action application/x-httpd-python /python-bin/pycgi
0030 ScriptAlias /python-bin/ /QOpenSys/usr/python-scripts/osswxx/
0031 <Directory /QOpenSys/usr/python-scripts>
0032      Require all granted
0033 </Directory>
0034 
0035 Alias /python-script /QOpenSys/usr/python-scripts/osswxx/
0036 <Location /python-script>
0037      Order deny,allow
0038      Allow from all
0039 </Location>
```

* 30行目：Directoryディレクティブで「/QOpenSys/usr/python-scripts」へのアクセスを許可
* 35行目：Locationディレクティブでパス「/python-script」へのアクセスを許可

<br>

次にPythonスクリプトを配置するディレクトリーと、CGIのラッパースクリプト「pycgi」を作成し、chmodコマンドでアクセス権を設定します。「pycgi」も文字コードUTF-8(CCSID 1208)、改行コードが*LFのテキストファイルです。

```
> MKDIR DIR('/QOpenSys/usr/python-scripts')  ← 既に存在する場合はそのまま続行
   ディレクトリーが作成された。                                            
> MKDIR DIR('/QOpenSys/usr/python-scripts/osswxx')                         
   ディレクトリーが作成された。                                            
> QSH CMD('touch -C 1208 /QOpenSys/usr/python-scripts/osswxx/pycgi')
   コマンドは終了状況 0 で正常に終了しました。                      
> QSH CMD('chmod 755 /QOpenSys/usr/python-scripts/osswxx/pycgi')
   コマンドは終了状況 0 で正常に終了しました。                  
> EDTF STMF('/QOpenSys/usr/python-scripts/osswxx/pycgi')            
```

?> 「755」は、所有者は読取り/書込み/実行可能、グループメンバーは読取り/実行可能、その他のユーザーは読取り/実行可能を示す。

**「Python CGIラッパー /QOpenSys/usr/python-scripts/osswxx/pycgi」**

```
0001 #!/QOpenSys/pkgs/bin/python                       
0002 import os                                         
0003 os.execlp(os.environ['PATH_TRANSLATED'], 'argv')  
```

* 3行目：HTTPサーバー(CGI)は環境変数「PATH_TRANSLATED」にローカル(IBM i)の絶対パス情報を記録する。execlp()関数は現在のプロセスを置き換える形で、渡されたパス(Pythonスクリプト)を実行。

最後にHTTPサーバーのインスタンス(物理ファイルQUSRSYS/QATMHINSTCのメンバー)を登録し、HTTPサーバーの作成は完了です。

```
> ADDPFM FILE(QUSRSYS/QATMHINSTC) MBR(OSSWXX)                     
   メンバー OSSWXX が QUSRSYS のファイル QATMHINSTC に追加された。
> UPDDTA FILE(QUSRSYS/QATMHINSTC) MBR(OSSWXX)                     

  ファイル中のデータ処理                         モード  . . :    入力      
  様式  . . . . :   QTMHINC                      ファイル  . :   QATMHINSTC 
                                                                            
                                                                            
 Instance Data: -apache -d /www/osswxx -f conf/httpd.conf -AutoStartN       
```

<br>

**<u>2) Pythonスクリプトの登録とWebブラウザからの呼出し</u>**

CLから直接呼び出す前に、WebブラウザからPythonスクリプトをCGIとして実行ができる事を確認します。

まず、NetSreverやQshellのtouchコマンドなど任意の方法でHTMLファイル「hello.html」を作成します。文字コードはUTF-8(CCSID 1208)、改行コードはCRLFのテキストファイルとします。

?> W3CのHTML5規定の「8.1.3.1 Newlines」(https://www.w3.org/TR/2011/WD-html5-20110405/syntax.html#newlines )によれば改行はCR、LF、CRLFのいずれか。

**「HTMLファイル /www/osswxx/htdocs/hello.html」**

```html
0001 <html>
0002 <head><meta charset="utf-8" /></head>
0003 <body>
0004 <h2>Pythonスクリプトの呼出し</h2>
0005     <form action="http://ibmi:200XX/python-script/helloPython.py" method="GET">
0006         名前を入力してください
0007         <input type="text" name="name">
0008         <input type="submit" value="送信">
0009     </form>
0010 </body>
0011 </html>
```

* 2行目：Webブラウザの誤認識による文字化けを防ぐため、このHTMLファイルでUTF-8を使用している事を宣言。
* 5～9行目：GETメソッドでCGIを呼び出すFORMを定義。

次に「pycgi」と同じ要領でPython CGIスクリプト「helloPython.py」を作成します。

**「Pythonスクリプト /QOpenSys/usr/python-scripts/osswxx/helloPython.py」**

```python
0001 #!/QOpenSys/pkgs/bin/python
0002 import cgi
0003 
0004 print("Content-Type: text/plain; charset=utf-8\r\n")
0005 
0006 form = cgi.FieldStorage()
0007 print("こんにちは、" + form["name"].value + "さん。")
```

* 2行目：Python標準のcgiモジュールを利用。cgiモジュールはPython 3.11で非推奨、3.13で削除が予定されおり、詳細と代替が「PEP 594 – Removing dead batteries from the standard library」(https://peps.python.org/pep-0594/#cgi )に記載されている。下記理由からここではcgiモジュールを使用。
  * 現在のコードをそのまま利用する目的で「legacy-cgi」などの互換モジュールが提供されている。
  * cgiモジュール以外への移行ではコードの書き換えが必要になるが、標準的な手法が存在しない。
  * シンプルなアプリケーションではcgiモジュールが最も事例が多く、習得が容易。
  * FastCGIやWSGIなどcgiを拡張した手法や、オープンなフレームワークを利用したWebアプリケーション構築が増えている。

<br>

この時点で下表のディレクトリー、ファイル、オブジェクトが作成され、PythonのCGIスクリプトを実行する準備が完了します。

|ディレクトリー/ファイル/オブジェクト|備考|
|---------------------------------|----|
|/www/osswxx|HTTPサーバーディレクトリー|
|/www/osswxx/conf|HTTPサーバー構成ディレクトリー|
|/www/osswxx/conf/httpd.conf|HTTPサーバー構成ファイル|
|/www/osswxx/htdocs|ドキュメント・ルート|
|/www/osswxx/htdocs/hello.html|CGI呼び出し用HTMLファイル|
|/www/osswxx/logs|ログディレクトリー|
|/www/osswxx/logs/access_log.Qxxxxxxxxx<br>/www/osswxx/logs/error_log.Qxxxxxxxxx|自動生成。HTTP構成でロギングを指定した場合に作成されるログファイル|
|QUSRSYS/QATMHINSTC(OSSWXX)|インスタンス定義の物理ファイルメンバー|
|/QOpenSys/usr/python-scripts|Pythonスクリプト配置ディレクトリー|
|/QOpenSys/usr/python-scripts/osswxx|ユーザーOSSWXX用ディレクトリー|
|/QOpenSys/usr/python-scripts/osswxx/pycgi|Python CGIラッパー|
|/QOpenSys/usr/python-scripts/osswxx/helloPython.py|Python CGIスクリプト|

5250画面からSTRTCPSVRコマンドでHTTPサーバーを開始します。

```
> STRTCPSVR SERVER(*HTTP) HTTPSVR(OSSWXX)          
  HTTP サーバーは開始中である。                    
```

WRKACTJOBコマンドを実行し、サブシステムQHTTPSVR下でHTTPサーバー名と同名のジョブが動作していれば正常に起動しています。

```
> WRKACTJOB SBS(QHTTPSVR) JOB(OSS*)

                                活動ジョブ処理                         XXXXXX
                                                         23/XX/XX  16:55:11 JST 
 CPU %:     2.7     経過時間 :   00:01:19     活動ジョブ :   191                
                                                                                
 オプションを入力して，実行キーを押してください。                               
   2= 変更   3= 保留     4= 終了   5= 処理   6= 解放   7= メッセージ表示        
   8=ｽﾌﾟｰﾙ･ﾌｧｲﾙ の処理   13= 切断 ...                                           
                      現行                                                      
 OPT  ｻﾌﾞｼｽﾃﾑ/ｼﾞｮﾌﾞ   ﾕｰｻﾞｰ      ﾀｲﾌﾟ  CPU %   機能            状況             
        OSSWXX       QTMHHTTP    BCH      .0  PGM-QZHBMAIN     SIGW             
        OSSWXX       QTMHHTTP    BCI      .0  PGM-QZSRLOG      SIGW             
        OSSWXX       QTMHHTTP    BCI      .0  PGM-QZSRLOG      SIGW             
        OSSWXX       QTMHHTTP    BCI      .0  PGM-QZSRHTTP     SIGW             
        OSSWXX       QTMHHTP1    BCI      .0  PGM-QZSRCGI      TIMW             
        OSSWXX       QTMHHTTP    BCI      .0  PGM-QZSRHTTP     DEQW             
```
                                                                                 
Webブラウザから「http://(IBM iのホスト名またはIPアドレス):200xx/hello.html」にアクセスしてHTMLを表示します。任意の値を入力して「送信」をクリックし、結果が返る事を確認します。

![HTTPサーバーの構成.jpg](/files/HTTPサーバーの構成.jpg)

<br>

実行時にエラーとなる場合は下記のような項目を確認します。

* ディレクトリーやファイルの権限は適切に設定されているか。
* 各ファイルの文字コードや改行コードは正しいか。
* ログファイル「/www/osswxx/logs/error_log.Qxxxxxxxxx」にエラーが記録されている場合は対応を実施。
* Webブラウザの種類/バージョンを変えて試行。
* ネットワークに制約や問題が無いか確認。

<br>

**<u>3) ILE-RPGからPython CGIスクリプトを呼出し</u>**

ILE-RPGからWebアプリケーションを呼出して結果を得るには、下記の様の方法でHTTP通信を行います。

①	POSIX socket APIを利用。RPGにはC言語のようなヘッダー(プロトタイプ)が提供されていないため、独自に作成するか、Webのフリーウェアなどを利用する必要あり

②	RPGの組み込みSQLから、ライブラリーSYSTOOLS、あるいは、ライブラリーQSYS2のHTTP機能(SQLテーブル関数、または、スカラー関数)を利用

?> SYSTOOLSのHTTP機能はIBM i 7.1 TR6以降、QSYS2のHTTP機能はIBM i 7.3 TR11/IBM i 7.4 TR4以降で利用可能。詳細は「HTTP 関数の概要」(https://www.ibm.com/docs/ja/i/7.5?topic=systools-http-function-overview )、「New HTTP functions based in QSYS2」(https://www.ibm.com/support/pages/new-http-functions-based-qsys2 )、「SQLでウェブ・サービスを起動する」(https://www.e-bellnet.com/category/jungle/1402/1402-832.html )などを参照。

③	統合Webサービス(IWS)サーバーの「Transport API」を利用

?> 「Transport API」はAXIS(Apache Extensible Interaction System)がベース。API仕様は「Web Services Client for ILE Programming Guide」(https://public.dhe.ibm.com/systems/support/i/iws/systems_i_software_iws_pdf_WebServicesClient_new.pdf )の「Chapter 17. Axis C core APIs」を参照。

①および③は比較的複雑なコーディングが必要なため、ここでは②の手法を採用します。②にはほぼ同等の機能が2セット(ライブラリーSYSTOOLSとQSYS2)提供されていますが、IBMのサポートがあり、かつ実行時のオーバーヘッドが小さい、QSYS2のHTTP機能を利用します。

?> 「SYSTOOLSの使用」(https://www.ibm.com/docs/ja/i/7.5?topic=systools-using )に「SYSTOOLS内のツールおよび例は、使用の準備ができているものと考えられています。ただし、これらはIBM製品の一部とは見なされないため、IBM サービスおよびサポートの対象ではありません。」と記載有り。

<br>

実行するSQLを下記に示します。


![ILE-RPGからPython_CGIスクリプトを呼出し.jpg](/files/ILE-RPGからPython_CGIスクリプトを呼出し.jpg)

<br>

RPGのコーディングを始める前に、ACSのSQLスクリプトを使用 して、SQLのHTTP機能から作成済みのPython CGIスクリプトを実行できるか確認します。

?> STRSQLコマンドで起動する対話型SQLでは結果が*POINTERと表示される。Qshellのdb2コマンドでは下記の要領で確認が可能。<br><code>> db2 -S "VALUES QSYS2.HTTP_GET('http://ibmi:200xx/python-script/helloPython.py<br>  ?name=' || QSYS2.URL_ENCODE(' 伊藤 '), '')" | sed -n 4P | xargs⏎<br>   こんにちは、伊藤さん。                                                      </code>

SQLスクリプトを起動して下図のように実行します。HTTP_GETスカラー関数の第二パラメーターはブランクですが、必要な場合にHTTPヘッダー、基本認証、タイムアウトなどのHTTPオプションをJSON形式で指定できます。URL_ENCODEスカラー関数はUTF-8文字列を「%xx」形式の16進数などにエンコードします。

![ILE-RPGからPython_CGIスクリプトを呼出し2.jpg](/files/ILE-RPGからPython_CGIスクリプトを呼出し2.jpg)

下部ペインにCGIスクリプトの出力が表示されます。

<br>

SQLの正常動作が確認できたら、このSQLを組み込んだRPGプログラムと、RPGを呼び出すCLプログラムを作成します。

**「RPGプログラム HTTPGET」**

```
0001.00 **free                                                             
0002.00 CTL-OPT MAIN(httpGet);                                             
0003.00 CTL-OPT ACTGRP(*CALLER) OPTION(*SRCSTMT : *NODEBUGIO : *NOUNREF);  
0004.00                                                                    
0005.00 DCL-PROC httpGet;                                                  
0006.00   DCL-PI *N EXTPGM;                                                
0007.00     inStr CHAR(4096);                                              
0008.00     outStr LIKE(inStr);                                            
0009.00     outStrLen PACKED(5 : 0);                                       
0010.00   END-PI;                                                          
0011.00                                                                    
0012.00   DCL-S inStrV VARCHAR(4096);                                      
0013.00   DCL-S outStrV LIKE(inStrV);                                      
0014.00   DCL-C url 'http://ibmi:20011/python-script/helloPython.py?name=';
0015.00   DCL-C crlfblank X'0D2540'; // EBCDIC                             
0016.00                                                                    
0017.00   inStrV = %SUBST(inStr : 1 : %LEN(%TRIMR(inStr)));                
0018.00   EXEC SQL                                                         
0019.00     VALUES QSYS2.HTTP_GET(:url || QSYS2.URL_ENCODE(:inStrV), '')   
0020.00       INTO :outStrV;                      
0021.00   outStr = outStrV;                       
0022.00   outStrLen = %CHECKR(crlfblank : outStr);
0023.00                                           
0024.00 END-PROC;                                 
```

* 17行目：RPGの文字列パラメーターは固定長なので、SQLで使用する可変長文字変数に値を代入。
* 18～20行目：スカラー関数HTTP_GETを実行し、結果をホスト変数outStrVに代入。
* 22行目：HTTPサーバーからの応答文字列末尾に含まれるEBCDICの復帰(CR/0x0d)、改行(LF/0x25)、ブランク(0x40)を除去。

**「CLプログラム HTTPGETC」**

```
0001.00              PGM        PARM(&NAME)                                       
0002.00              DCL        VAR(&NAME) TYPE(*CHAR) LEN(32)                    
0003.00              DCL        VAR(&INSTR) TYPE(*CHAR) LEN(4096)                 
0004.00              DCL        VAR(&OUTSTR) TYPE(*CHAR) LEN(4096)                
0005.00              DCL        VAR(&OUTSTRLEN) TYPE(*DEC) LEN(5 0)               
0006.00                                                                           
0007.00              CHGVAR     VAR(&INSTR) VALUE(&NAME)                          
0008.00              CALL       PGM(HTTPGET) PARM((&INSTR) (&OUTSTR) (&OUTSTRLEN))
0009.00              SNDPGMMSG  MSG(%SST(&OUTSTR 1 &OUTSTRLEN)) TOPGMQ(*EXT)      
0010.00                                                                           
0011.00              ENDPGM                                                       
```

* 7行目：コマンド入力画面から直接実行できるように、文字パラメーターの長さを32で指定。32バイト以下の文字列が指定されると、右側にブランクが埋め込まれた32バイトの文字列が渡される。
* 9行目：RPGプログラムから返された文字列(&OUTSTR)の、文字列長(&OUTSTRLEN)までを外部メッセージ待ち行列に送信。

<br>

プログラムを実行すると下記のようになります。

```
> CHGCURLIB CURLIB(OSSWXX)                  
   現行ライブラリーが OSSWXX に変更された。
> CALL PGM(HTTPGETC) PARM((' 斉藤 '))

                         プログラム・メッセージの表示                           
                                                                                
 QSYS のサブシステム QINTER のジョブ 407240/XXXXXX/QPADEV0001 が 23/XX/XX 09:   
  こんにちは、斉藤さん。                                                        
```

<br>

HTTPサーバーを利用したこの仕組みは、容易にWebサービスに拡張できます。既存のRPG/CLで記述されたアプリケーションでPythonの機能を利用する、あるいは、他のサーバーとのデータ交換や連携処理を行なう場合の、有力なデザイン・パターンになるでしょう。

