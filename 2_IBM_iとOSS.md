# 2 IBM iとOSS

多くのIBM iユーザーは、日々の業務にRPGやCOBOLで記述されたアプリケーションを利用しているでしょう。これら既存のアプリケーションとOSSを組み合わせれば、最新の技術を迅速かつ容易に利用できるようになります。

また、OSSはDX(デジタルトランスフォーメーション)やクラウドとの親和性が高く、IBM iユーザーに新たなポートフォリオを提供します。モダナイゼーションの促進、既存システムのWeb API/マイクロサービス化など、DXを実現する手段としてOSSの活用は非常に有効です。

さらに、IBM i上で直接OSSを実行すれば、クラウドやLinux/Windowsサーバーで稼働するOSSとIBM iを連携するパターンと比較し、シンプルな構成で安定運用できるケースも多いでしょう。

OSSはIBM iにとって重要な位置を占めており、現在IBM iで利用できるOSSは、質・量ともに、過去最高レベルと言えます。1990年代からIBM i (当時のOS/400)でOSSを利用する試みが行われてきましたが、2010年より前はごく少数のユーザーが関心を示す程度と思われますが、2009年のZend PHPはOSに無料で同梱したこともあり、一定の支持を得ました。2014年以降はIBM i向けに多数のOSSが配布されています。

|年度|ツール名|提供者|OS前提|URL/備考|
|----|-------|-----|------|--------|
|1999|ILE perl (5.005_02)|個人|V4R3|http://www.cpan.org/ports/archive-2011-03-26.html#os400|
|2000|zlib、wwwcount、Analogなど|個人|V4R2|http://uzaemon.d.dooo.jp/|
|200?|IBM Tools for Developers PRPQ  (5799-PTL)|IBM社|V4R5など|perl、bison、gawkなどを同梱。2003年にはX-Windowも追加。2018年に提供終了、現在は入手不可|
|2009|Zend Core (PHP)|Zend社|V5R4|当初IBM iに同梱|
|2014|Open Source Technologies on IBM i (5733-OPS)|IBM社|7.1 TR9|2014/12のGA時はNode.jsのみ、以降Pythonなどを追加。IBMの正式サポート無し。2019年末以降は利用不可|
|2018|RPM packages|IBM社|7.3 TR5|サポートについては https://www.ibm.com/support/pages/open-source-support-ibm-iを参照|

?> 「IBM Tools for Developers PRPQ」の「PRPQ」はIBM用語でProgramming Request for Price Quoteの略。IBMが提供するライセンス・プログラムのような追加ソフトウェアパッケージであるが、提供方法やサポート、多国語対応が制限されることが多い。5799-PTLは無償のPRPQ。

<br>

## 2.1 IBM iとUNIXの特性

PASE上で動作するオープンソース・アプリケーションはAIX (以下「UNIX」または「Linux」も同義)版をベースにしているソフトウェアが多く、IBM iと多くの点で異なる動作をします。まずIBM iとUNIXの特性の違いを確認しましょう。
<br>

主要な差異を下表に示します。

|特性|**<font color="blue">IBM i</font>**|**<font color="#0ba334">UNIX</font>**|
|----|-----|----|
|基本入出力|ブロック(レコード)|ストリーム|
|入出力データ|バイナリ|テキスト(制御文字含む)|
|入出力の一時変更|OVR(指定変更)|パイプとリダイレクト|
|ファイルシステム|3階層(ネイティブ)および階層構造(IFS)|階層構造|
|ファイルのセキュリティ|オブジェクト権限/データ権限|ファイルのパーミッション|
|ユーザーインターフェース(CUI)|5250画面|ターミナル|
|ユーザーインターフェース(GUI)|Nagivator for i (Webブラウザを利用)|X Window＋デスクトップ環境(GNOMEなど)|
|基本文字コード|EBCDIC|ASCII/UTF-8|
|多国語対応|OSが提供|アプリケーション対応|
|基本実行単位|ジョブ|プロセス|
|運用・管理コマンド|CLコマンド|シェルコマンド|
|主要プログラミング言語|CL/RPG/COBOL (OPMおよびILE)、C/C++、Java、PHPなど|シェルスクリプト、C/C++、perl、PHP、Python、Javaなど|
|DBMS|Db2 for i (OSに組み込み)|Oracle、Db2、PostgreSQL、MariaDBなど|
|OSの開発・提供元|IBM社|多数(Linux)|
|ソースコード|非公開|ほぼ公開(Linux)|

<br>

これらの差異のほとんどはPASE環境にも当てはまります。この節ではOSSを利用するための基礎知識の一部を、IBM iとの比較で解説します。

<br>

### 2.1.1 入出力とファイルシステム

<br>

**<u>基本入出力</u>**

?> この資料ではIBM iは5250画面、UNIXはシェルとの入出力を指すものとする。Webブラウザやウインドゥなどとの入出力は対象外。

IBM iの基本的な入出力モードは「<b><font color="blue">ブロック入出力</font></b>」で、一定のバイト列をまとめて入力/出力します。例えば、5250画面で実行(機能)キーを押すと、画面に入力されたすべてのデータがIBM iに送られます。

対して、UNIXの基本は「<b><font color="#0ba334">ストリーム入出力</font></b>」です。UNIXのターミナルで1文字タイプすると、即座にデータがOSに送られます。

ブロック入出力では機能キーを押すまでホストに負荷が発生しないため、非常に多数の端末をホストできます。一方でストリーム入出力はユーザーのアクションに即座に反応できるので、入力補完などリアルタイムの操作性が向上します。

<br>

**<u>入出力の一時変更</u>**

IBM iで入出力を一時変更するには、<b><font color="blue">OVR(Override：指定変更)系のコマンド</font></b>が利用できます。ただし、入出力データがバイナリを含むブロック型であり、WRK/DSP系のコマンドの多くには、<b><font color="blue">OUTPUTパラメーターで出力先を「\*(画面)」、「\*FILE」、「\*PRINT」に変更</font></b>する専用処理が用意されています。特に「*FILE」が指定できる場合は専用のレイアウトのデータベースに書き出されるため、後処理が非常に容易です。

UNIX系OSは<b><font color="#0ba334">リダイレクト</font></b>によって入出力(標準入力、標準出力、標準エラー出力)を切り替えます。コンソールの場合、入力であればキーボードからタイプするデータをファイルや他のコマンドの出力に変更したり、出力であれば画面に表示するデータをファイルや他のコマンドの入力に変更したりすることができます。ただし、多くの出力は人間が読んで分かるようにヘッダーなどの情報が付加されており、後処理でこれらの除去を行うケースが多いでしょう。とはいえ、シェルでは複数のコマンドを1行に連結して実行できるので、複雑な処理でも柔軟に対応ができます。

?> リダイレクトには「>」「>>」「<」で標準入出力の、「2>」「2>>」で標準エラー出力の変更が可能。「>&」で標準出力と標準エラー出力を同じファイルにリダイレクト。パイプ「|」は左側のコマンドの標準出力を、右側のコマンドの標準入力に流す。

<br>

**<u>ファイルシステム</u>**

IBM iネイティブのファイル・システム(オブジェクトの階層)は、<b><font color="blue">ライブラリー/オブジェクトの2階層、メンバーを持つオブジェクトはこれを加えた3階層</font></b>です。各階層の<b><font color="blue">名前の長さは最大10文字</font></b>で、英大文字と一部の記号が使用でき、<b><font color="blue">英大文字と小文字は区別しません</font></b>。

PASE環境で利用するファイルはIFS(統合ファイルシステム)に階層型に格納されます。<b><font color="#0ba334">パス名の最大長は16MB</font></b>で、基本的にジョブのCCSIDで定義されている文字が使用できます。IFSの/QOpenSysファイル・システムでは<b><font color="#0ba334">英語大文字/小文字が区別されます</font></b>。

?> ネイティブのファイル・システム(QSYS.LIB)は/QSYS.LIB/MYLIB.LIB/MYFILE.FILE/MYMBR.MBRの4階層(メンバーが無いオブジェクトは3階層)で表される。

?> パス名ではMKDIRコマンドのDIRパラメーターなどの一部でユニコードを指定可能。ただし、QCMDはユニコードをサポートしないのでQCAPCMD APIなどを利用する必要がある。

<br>

**<u>ファイルのセキュリティ</u>**

IBM iではシステム上のオブジェクトに対して<b><font color="blue">オブジェクト・レベル・セキュリティ</font></b>。が適用されます。デフォルトの権限を示す*PUBLICと、個別のユーザー/グループ/権限リストに対して、オブジェクト権限(操作/管理/存在/変更/参照)と、データ権限(読取/追加/更新/削除/実行)をCHGAUTなどのコマンドで設定できます。

IFSのストリーム・ファイルに対してPASEから<b><font color="#0ba334">パーミッション</font></b>。を設定できます。具体的には、ファイルの「u(所有者)」「g(所有グループ)」「o(その他)」の3タイプのユーザーに対し、chmodコマンドで「r(読取)」「w(書込)」「x(実行)」の権限を指定します。

例えば、<b><font color="#bd8911">*PUBLIC/その他(o)</font></b>のユーザーの権限を設定すると下表のようになります。

![2.1.1_入出力とファイルシステム.jpg](/files/2.1.1_入出力とファイルシステム.jpg)

<br>

### 2.1.2 文字コード

<br>

**<u>基本文字コード</u>**

ネイティブの文字コードは、IBM iは<b><font color="blue">EBCDIC</font></b>、UNIXは<b><font color="#0ba334">ASCII</font></b>が基本です。いくつか注意点を挙げます。

?> Linuxを含むほとんどのUNIXの日本語実装はEUC-JP(Extended UNIX Code Packed Format for Japanese)。AIXは例外的にシフトJIS。近年ではUTF-8実装が主流。

* EBCDICでは1バイト文字の「￥」と「＼」が異なるコードポイントを持つ。ASCIIは同一コードポイント(0x5c)であるが、環境によって「￥」と「＼」のいずれかが表示される

?> ISO/IEC 646規格でコードポイント(0x5c)に国別に異なる文字の割当てを許容しているため、米国では「＼」、日本では「￥」を割り当てた。また、ユニコードでは「￥」と「＼」に異なるコードポイントが割り当てられているが、1バイト(半角)の「＼」を「￥」で表示する日本語フォントが多い。

* EBCDICにはASCIIに存在しない1バイト文字の「￢」あり
* バイナリーでソートした際の結果が異なる。例えばEBCDICは文字⇒数字の順で、ASCIIは数字⇒文字の順になる。また、記号や半角カタカナの配置も異なる
* PASE環境ではユニコード(UTF-8)の使用を推奨
    * PythonやNode.jsなどの言語で、最新バージョンのデフォルトがUTF-8
    * 各種スクリプトのソースや、JSON/XMLで多くの場合にUTF-8が使われる
    * IBM i 7.4以降であれば、ssh接続から「system (CLコマンド)」を実行した際に、出力内の非ASCII文字(漢字など)が文字化けしなくなる
* IBM i側のEBCDIC CCSIDは、扱える漢字が多い1399か、一部の文字で発生する「不自然な変換」がない5035のいずれかを選択

  ?> 「不自然な変換」の詳細は「Alternative CCSID 1399 conversion」(https://www.ibm.com/docs/api/v1/content/ssw_ibm_i_75/nls/rbagsalt1399conv.htm )やWikipediaの「Unicode」(https://ja.wikipedia.org/wiki/Unicode )の「波ダッシュ・全角チルダ問題」などを参照。

<br>

### 2.1.3 実行管理と運用

<br>

**<u>基本実行単位</u>**

IBM iが行なうすべての作業は<b><font color="blue">ジョブ</b></font>と呼ばれる単位に分割されます。ジョブはIBM iが作業を編成し、追跡し、処理する仕組みです。一方でUNIX(Linuxなど)ではプログラム実行単位を<b><font color="#0ba334">プロセス</b></font>と呼びます。

PASE環境のプロセスは、例えばコマンド「ps aux」で出力できます。各プロセスはIBM iのジョブに対応しており、PASEのgetjobidコマンドで指定したプロセスIDに対応するIBM iの「ジョブ番号/ユーザー/ジョブ名」を確認できます。

?> psコマンドのオプションの「a」で自分以外のユーザーのプロセスも表示、「u」でユーザー名と開始時刻を表示、「x」でデーモンプロセスを表示する。

```bash
bash-5.1$ ps aux
USER       PID %CPU %MEM   SZ  RSS    TTY STAT    STIME  TIME COMMAND
qdbts      123  0.0  0.0 528464    0      - A      Dec 08 44:55 /QOpenSys/QIBM/Pr
qlwisvr     39  0.0  0.0 245928    0      - A      Dec 08 17:44 /QOpenSys/QIBM/Pr
qlwisvr     36  0.0  0.0 309060    0      - A      Dec 08  5:35 /QOpenSys/QIBM/Pr
qsys        34  0.0  0.0 12188    0      - A      Dec 08  2:49 /QIBM/ProdData/OS
qlwisvr     37  0.0  0.0 215616    0      - A      Dec 08  2:41 /QOpenSys/QIBM/Pr
qwebadmi    77  0.0  0.0 71344    0      - A      Dec 08  1:08 /QOpenSys/QIBM/Pr
qwebadmi    41  0.0  0.0 189876    0      - A      Dec 08  0:33 /QOpenSys/QIBM/Pr
qwebadmi    38  0.0  0.0 280060    0      - A      Dec 08  0:26 /QOpenSys/QIBM/Pr
qwebadmi    40  0.0  0.0 175068    0      - A      Dec 08  0:19 /QOpenSys/QIBM/Pr
qsecofr      9  0.0  0.0 68384    0      - A      Dec 08  0:04 /QOpenSys/QIBM/Pr
osswxx   12605  0.0  0.0 12832    0  pts/0 A    15:24:43  0:00 bash
～～～～～～～～～～～～～～～ 中略 ～～～～～～～～～～～～～～～～～
bash-5.1$ getjobid       ← PIDを指定しない場合は現行プロセスが対象
プロセスID 12605は398841/QSECOFR/QP0ZSPWPです
bash-5.1$ getjobid 34
プロセスID 34は383613/QSYS/QSLPSVRです
```
<br>

psコマンド出力の各カラムの意味を下表に示します。

|カラム|意味|
|------|----|
|USER|所有ユーザー名|
|PID|プロセスID|
|%CPU|CPU使用率|
|%MEM|使用しているメモリ量の割合|
|SZ([Virtual] Set Size)|使用している仮想メモリのサイズ|
|RSS(Resident Set Size)|使用している物理メモリのサイズ|
|TTY|制御端末の種類と番号(「-」はプロセスが端末と関連付けられていない)|
|STAT|プロセスの状況|
|START|プロセスの開始時刻|
|TIME|CPU使用時間|
|COMMAND|そのプロセスにより最後に実行が行われたプログラム、メニュー、またはコマンド|

<br>

**<u>運用・管理コマンド</u>**

IBM iネイティブ環境とPASE環境では、運用・管理に使用されるコマンドが全く異なります。類似した機能を対比すると表のようになるでしょう。

|機能||IBM i|PASE|
|----|--|----|---|
|ライブラリー/ディレクトリー|現行の表示|DSPLIBL(*CURと表示)|pwd|
||現行の変更|CHGCURLIB|cd|
||作成|CRTLIB|mkdir|
||削除|DLTLIB|rmdir|
|ファイル<br>(IBM iではPFを想定)|一覧|DSPLIB、WRKF|ls|
||表示|DSPPFM|cat、lessなど|
||コピー|CPYF、CRTDUPOBJ|cp|
||移動|MOVOBJ|mv|
||名前の変更|RNMOBJ|mv、rename|
||削除|DLTF|rm|
||ファイル名で検索|WRKF|find|
||権限の変更|CHGAUT、WRKAUT|chmod|
||所有者の変更|CHGOBJOWN|chown|
||アーカイブ|CRTSAVF⇒SAVxxx|tar、zipなど|
|プロセス|一覧表示|WRKACTJOB|ps|
||現行環境の表示|DSPJOB|set|
||サブミット|SBMJOB|(コマンド) &|
||終了|ENDJOB|kill|
||ログオフ|SIGNOFF|exit|
|その他|ソース/テキスト編集|STRSEU、EDTF|viなど|
||ファイラー|WRKxxxPDM|mcなど|
||プログラムの実行|CALL プログラム名|(プログラム名)|
||電源オフ|PWRDWNSYS|shutdown|
||対話型SQL|STRSQL|isql、db2など|
||環境変数の表示|WRKENVVARexport|
<br>

Linuxでは良く利用されるが、PASEに存在しないコマンドがあります。例として、top(タスク一覧やシステム概要情報を表示)、dmesg(Linux起動時のメッセージを表示)、ifconfig(ネットワーク・インタフェースの設定)、ping(IPホストとの接続確認)、sudo/su(一時的に他のユーザに変更)、useradd(新規ユーザの作成)、passwd(パスワードの変更)、Xウインドゥ・マネージャーなどが挙げられます。

topのような一般コマンドは、単に移植の優先順位が低いのかもしれません。他方、構成コマンドやユーザー管理コマンドは、PASEがOSではなくIBM i上の「環境」であるため、移植が不可能、あるいは困難なためと思われます。

<br>

IBMから提供されていないコマンドが必要な場合は、次のいずれかを検討する事になるでしょう。

* IBM iのネイティブ機能で代替
* IBM公式以外、あるいは、AIX(PowerPC)バイナリーを提供するリポジトリ― を検索し、ここから取得・インストール
* PASEで動作する可能性があるソースコード を入手して自身でビルド

例えばpingはIBM iのping(VFYTCPCNN)コマンドで代替できます。

```bash
bash-5.1$ export LANG=JA_JP.UTF-8
bash-5.1$ system ping google.com
TCP3203: アドレス142.250.196.142でホスト・システムGOOGLE.COMへの接続を検査中である。
TCP3215: 142.250.196.142からのPING応答1は2ミリ秒の256バイトです。TTLは114です。
TCP3215: 142.250.196.142からのPING応答2は2ミリ秒の256バイトです。TTLは114です。
TCP3215: 142.250.196.142からのPING応答3は2ミリ秒の256バイトです。TTLは114です。
TCP3215: 142.250.196.142からのPING応答4は2ミリ秒の256バイトです。TTLは114です。
TCP3215: 142.250.196.142からのPING応答5は2ミリ秒の256バイトです。TTLは114です。
TCP3211: 往復（ミリ秒）最小/平均/最大= 2/2/2。
TCP3210: 接続検査の統計：5の5は正常に実行された(100 %)。
```

<p>　</p>

## 2.2 IBM iのシェル環境

「シェル」はUNIX系のOSに対してユーザーが基本操作を行うインターフェースを提供するプログラムであり、IBM iの「コマンド入力画面」に類似しています。

IBM iには**Qshell**と**PASE**(Portable Application Solutions Environment for i) の2種類のシェル環境があり、ほとんどのOSSはいずれかのシェル環境から利用します。いずれもIBM i標準で導入・利用できるプロダクト・オプションです。

?> QshellはOSのオプション30、PASEはオプション33。PASEはV4R4で発表された時点では有償であったが、V5R2以降は無償。

Qshellが業界標準APIで記述されたアプリケーションをILE/EBCDIC環境に移植・利用する目的であるのに対し、PASEはAIX(PowerPCプロセッサー)バイナリがそのままASCIIで動作する環境を提供します。

?> AIX(Advanced Interactive Executive)はIBMのUNIXオペレーティングシステムのブランド名。

<br>

下表は2つのシェルの概要です。このハンズオンではsshクライアントからPASE環境に接続してOSSを利用します

||Qshell|PASE|
|-|-----|----|
|ベース環境|POSIXとX/Open標準|AIXランタイム|
|利用可能バージョン|V4R2以降|V4R4以降|
|文字コード|EBCDIC|ASCII|
|オブジェクトモデル|ILE|AIX(PowerPC)バイナリ|
|OSS移植工数|中〜大|小|
|主な用途|JavaやWebアプリケーションサーバー、オープン系ILEプログラムの利用|AIX(PowerPCプロセッサー)用に移植したOSSの利用|
|シェル環境の起動|QSHまたはSTRQSHコマンドを実行|プログラムQP2TERMまたはQP2SHELLをCALL、または、sshクライアントからIBM iのsshサーバーに接続|

?> POSIX(Portable Operating System Interface)はオペレーティングシステムの標準的なインタフェースおよび環境を定義するIEEE規格。X/OpenはUNIXシステムの相互運用性を向上を目的とし、各種技術の標準化を図るために設立された団体で、1996年にOSF(Open Software Foundation)と合併してThe Open Groupとなった。

<p>　</p>

## 2.3 OSS実行環境の準備

このセクションでは最小限の実行環境を設定する過程を解説します。

<br>

### 2.3.1 sshでPASE環境へのログイン

<br>

**<u>OSS実行用ユーザーの作成</u>**

ユーザーはIBM i側(5250画面)から作成します。UNIXでは英小文字を多用するので、ユーザー・プロフィールのCCSIDに5035(日本ローマ字/漢字)または1399(日本 ユーロ対応)を指定します。
```
> CRTUSRPRF USRPRF(OSSWxx) PASSWORD() USRCLS(*PGMR) INLMNU(*SIGNOFF) CCSID(
  5035)                                                                    
  *NONE 特殊権限が認可された。                                             
  ユーザー・プロファイル OSSWXX が作成された。                            
```

  * USRPRFパラメーターの「xx」は共有ハンズオン・サーバーを利用するときはインストラクターのガイドに従って設定してください。
  * PASSWORDパラメーターのデフォルトは、7.4以前は*USRPRF(ユーザー名と同じ)ですが、7.5では*NONEに変更されています。

<br>

**<u>sshd(SSHサーバー)の起動確認</u>**

IBM iのsshサーバーが起動していない状態でクライアントが接続を試みると、「ssh: connect to host idemo port 22: Connection refused」とエラーになるので、5250画面からコマンド「STRTCPSVR SERVER(*SSHD)」でsshdを起動します。
```
> STRTCPSVR SERVER(*SSHD)          
  SSHD サーバーは開始中である。   
```

sshdが正常に起動すると、サブシステムQUSRWRK内のジョブQP0ZSPWP(機能「PGM-sshd」)が常駐し、ポート22でssh接続を待機している事をNETSTAT OPTION(*CNN)で確認できます。

?> sshdが稼働するサブシステムを変更したい場合は「Starting the SSH Daemon in a Dedicated Subsystem Environment」(https://www.ibm.com/support/pages/starting-ssh-daemon-dedicated-subsystem-environment )を参照。
 
<br>

**<u>sshでIBM i (PASE環境)にログイン</u>**

Windowsのコマンドプロンプトを起動し、「ssh ユーザー名@サーバー名(またはIPアドレス)」でIBM iのsshサーバーにログインします。

?> ※ クライアントからsshで初めてのホストにログインする際に警告メッセージが表示されるので、このハンズオンでは「yes」で応答して再度ログインしてください。

```bash
C:\Users\(Windowsユーザー名)> ssh osswxx@idemo
The authenticity of host 'idemo (xx.xx.xx.xx)' can't be established.
ECDSA key fingerprint is SHA256:aX48KBsokHduGRHYrw3eRn0rwe47MAygcyv8Jif/Qxw.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'idemo' (ECDSA) to the list of known hosts.
Connection closed by xx.xx.xx.xx port 22

C:\Users\(Windowsユーザー名)>
```

sshdが起動しているにも関わらずsshでログインできない場合は、pingでIBM iと疎通が取れるか、ユーザーIDがIBM iに存在するか、Firewallなどで通信が制限されていないか、などを確認します。

<br>

### 2.3.2 シェル環境の設定

<br>

**<u>ホームディレクトリーの設定</u>**

ログインすると、デフォルトで「/home/OSSWxx」をホームディレクトリに設定しようとしますが、まだ存在しないためエラーになります。

```bash
C:\Users\(Windowsユーザー名)> ssh osswxx@idemo
osswxx@ibmi's password: (パスワードを入力)
Could not chdir to home directory /home/OSSWXX: No such file or directory
$ 
```

mkdirコマンド でホームディレクトリ(通常は「/home/ユーザー名」)を作成し、いったんログオフ(exit)します。

?> デフォルトのシェル(bsh)では行編集ができないので、打ち間違いをした時はCtrl+Cでプロンプト(「$」)に戻して初めから入力し直し。

```bash
$ mkdir /home/OSSWXX
$ exit
Connection to ibmi closed.
```

再度ログインし、エラーメッセージ「Could not chdir to home directory ...」が表示されていないことを確認し、pwdコマンドで現行ディレクトリーを確認します。

```bash
C:\Users\(Windowsユーザー名)> ssh osswxx@idemo
osswxx@ibmi's password: (パスワードを入力)
$ pwd
/home/OSSWXX
$
```

ホームディレクトリに存在するファイルをlsコマンドで確認します。オプションの「l」(小文字のエル)は詳細表示を、「a」はドットファイルの表示を指定します。

?> ファイル名の戦闘が「.」(ドット)で始まるファイル。UNIXでは隠しファイルとなる。

```bash
$ ls -la
total 32
drwxr-sr-x    2 osswxx   0              8192 Nov 14 15:43 .
drwxrwsrwx   11 qsys     0              8192 Nov 14 15:43 ..
$
```

まだ通常のファイルが存在しないので、「.」(カレントディレクトリ)と「..」(親ディレクトリ)だけが表示されます。1列目の「drwxr-sr-x」はファイルの種類とパーミッション、2列目はリンク数、3列目は所有者、4列目はグループ、5列目はファイルのサイズ、6列目は最終更新日時、7列目はファイル名を表します。

?> 「.」は前のステップで作成したホームディレクトリなので所有者は自分(osswxx)。

<br>

**<u>ログインスクリプトの作成と設定</u>**

この段階では「素の」シェルが起動した状態です。IBM iのOSSを利用するために、シェルスクリプトを2つ作成して基本的な環境を整えます。

**シェルスクリプト「.profile」**

PASEはKorn、Bourne、およびC shellの3つのシェルを提供しており、デフォルトはKornシェル。Linuxではbashが広く利用されているので、ログインした時点でbashシェルを自動的に起動 

?> 「bash」は「Bourne Again Shell」の略。GNUシステム用の標準シェル。

?> デフォルトのシェルを変更する他の方法は「Setting BASH as your shell」(https://ibmi-oss-docs.readthedocs.io/en/latest/troubleshooting/SETTING_BASH.html )を参照。

**シェルスクリプト「.bashrc」**

IBM i用のOSSへのパスを設定、および、シェルの言語指定をユニコード(utf-8)に変更

<br>


bashをシェルにすると、行編集、ヒストリー、パス補完などの機能が使えるようになります。下表にIBM iのコマンド入力画面とbash、さらに、Windows 10のコマンド・プロンプトの、コマンド入力方法の比較を示します。最も直感的で分かり易いのはIBM iコマンド入力画面で、機能が多彩なのがbashと言える でしょう。

|機能|IBM iコマンド入力|bash|Windows 10のコマンド・プロンプト|
|---|-----------------|----|-----------------------------|
|コマンドの入力と編集|フルスクリーン|行編集|行編集|
|ファイル名補完|なし|ファイル名を途中までタイプしてタブキー|ファイル名を途中までタイプしてタブキー|
|ヒストリー(前、後の履歴呼出し)|F9、F8|カーソル↑/Ctrl+P、↓/Ctrl+N|カーソル↑、↓|
|ヒストリー(一覧表示)|画面のスクロール|history (直近履歴数)|doskey /hまたはF7で履歴ウインドゥ表示|
|ヒストリー(呼出し)|コマンド履歴にカーソルを合わせてF4(プロンプト)/F9|(shopt -s histverifyを実行した後) !番号|F9で番号(F7で表示される)を入力|
|ヒストリー(実行)|ヒストリー呼出しして実行|(shopt -u histverifyを実行した後) !番号|F7の一覧からカーソルで選択して実行|


?> ヒストリー機能に関しては、いずれもWindows上でターミナル画面をスクロールしてCopy&Pasteできるので、実用上の差は少ない。

<br>

まず.profileを作成し、ログイン時にbashを呼び出すようにします。

```bash
$ echo 'exec bash' > .profile     ←シェルスクリプトの作成
$ cat .profile
exec bash
$ chmod +x .profile               ←シェルスクリプトに実行権限を付与
$ .profile 
bash-5.1$ exit                    ← プロンプトが変わっている事を確認
exit
$ exit
Connection to ibmi closed.

C:\Users\(Windowsユーザー名)>
```

ログインしてホームディレクトリーに「.profile」が存在することを確認します。

```bash
C:\Users\(Windowsユーザー名)>ssh osswxx@idemo
osswxx@ibmi's password: (パスワードを入力)
bash-5.1$ pwd
/home/OSSWXX
bash-5.1$ ls -la
total 64
drwxr-sr-x    2 osswxx   0              8192 Nov 14 15:49 .
drwxrwsrwx   11 qsys     0              8192 Nov 14 15:43 ..
-rw-------    1 osswxx   0                 5 Nov 14 15:49 .bash_history
-rwxr-xr-x    1 osswxx   0                10 Nov 14 15:48 .profile
```

viエディターで「.profile」を編集します。viを起動する前に、viが認識できるターミナルタイプを設定し、「vi ファイル名」でviを起動します。

```bash
bash-5.1$ export TERM=xterm     ← viの画面崩れ防止
bash-5.1$ set                   ← 実行環境の確認
BASH=/usr/bin/bash
～～～～～～～～～～～～～～～ 中略 ～～～～～～～～～～～～～～～～～
TERM=xterm
_=export
bash-5.1$ vi .bashrc
```

フルスクリーンでviが起動し、カーソルが画面左上にある状態で「i」で挿入モードに移行し、「export ...」以下を入力。入力が終わったらEscを押して「:wq」(更新して終了)とタイプしてEnterを押します。

?> ほとんどのLinux環境で利用できるエディターとしてviを例にとる。viをプログラム開発用のエディターとして使うことはないが、設定ファイルの編集などでviを使わざるを得ない可能性を考慮。

```bash
export PATH=/QOpenSys/pkgs/bin:$PATH
export LANG=JA_JP.UTF-8
~
~
~
:wq
```

<br>

下表にviでよく使われる操作を示します。

* viにはコマンドモードと入力モードがあり、モードによって機能が異なる。
* 起動直後はコマンドモードなので、「a」や「i」を押して文字入力を開始(⏎は不要)
* どちらのモードか分からくなった時や、誤った編集を全てキャンセルする時は、ESCを連打して「:q!⏎」でファイルを更新せずにプロンプトに戻る

|モード|キー|機能|
|-----|----|----|
|コマンドモード|a|カーソルの右に文字を挿入して入力モード|
||i (小文字のアイ)|カーソルの左に文字を挿入して入力モード|
||u|やり直し(Undo)|
||x|カーソル位置の1文字を削除|
||dw|カーソル位置の単語を削除|
||dd (小文字のDを2回)|カーソル位置の行切り取り|
||:q!⏎|強制終了(編集の内容を破棄)|
||:wq⏎|保存して終了|
|入力モード|エスケープ|コマンドモードに変更|
||←/h, →/l, ↓/j, ↑/k|カーソル移動|
||文字、数字、記号|カーソル位置にテキストを入力|

<br>

catコマンドで編集した内容が正しい事を確認し、chmodコマンドでスクリプトとして実行する権限を付与します。lsコマンドで実行権限(x)があることを確認し、いったんログオフします。次回のログオンからこのスクリプトが実行されます。

```bash
bash-5.1$ cat .bashrc
export PATH=/QOpenSys/pkgs/bin:$PATH
export LANG=JA_JP.UTF-8

bash-5.1$ chmod +x .bashrc    ←すべてのユーザーに実行権限を与える
bash-5.1$ ls -la
total 96
drwxr-sr-x    2 osswxx   0              8192 Nov 14 16:06 .
drwxrwsrwx   11 qsys     0              8192 Nov 14 15:43 ..
-rw-------    1 osswxx   0               202 Nov 14 16:00 .bash_history
-rwxr-xr-x    1 osswxx   0                38 Nov 14 16:09 .bashrc
-rwxr-xr-x    1 osswxx   0                10 Nov 14 15:48 .profile
-rw-------    1 osswxx   0                45 Nov 14 16:09 .vi_history
bash-5.1$ exit
exit
Connection to ibmi closed.
```

<br>

### (参考) PASE環境のテキストファイルの属性

PASE環境では一般的なLinux同様に、構成ファイルやスクリプトなどにテキストファイルを多用します。これらのテキストファイルはWindowsと異なる点があります。

* 文字コードはUS-ASCIIまたはUTF-8

?> 10年くらい前までは多くのLinuxで漢字(DBCS/MBCS)のエンコードにEUC-JP(Extended UNIX Code Packed Format for Japanese)が使われていたが、現在ではUTF-8が利用されることが多い。

* 改行コードはLFのみが一般的

?> CR(行頭復帰)は「Carriage return」、x'0D'、「\r」、「^M」とも表記される。同様に、LF(改行)は「Line feed」、x'0A'、「\n」、「^J」とも表される。

?> OSの標準がCR+LF(Windows)やCR(旧Machintosh。macOSはLF)の場合は、これにあわせて動く言語も多い。また、XML/JSONファイルはLF、HTMLファイルはCR/LF/CR+LFのいずれも許容、インターネットメール(SMTP)はCR+LFと、処理内容に合わせて使い分ける必要がある。

<br>

いくつかの方法でIBM i 7.5のIFSにテキストファイル(ストリームファイル)を作成した場合の属性は下表の様になりました。

||テキストファイル作成方法|STMFのCCSID|改行コード|
|--|--------------------|----------|---------|
|CLコマンド|<code>> EDTF STMF('/tmp/test.txt')</code>|EBCDIC(ジョブのCCSID)|CR+LF|
||<code>> QSH CMD('echo 漢字 > /tmp/test2.txt')</code>|EBCDIC(ジョブのCCSID)|LF|
||<code>> QSH CMD('touch -C 1208 /tmp/test5.txt; <br>&nbsp;&nbsp;&nbsp;echo 文字 > /tmp/test5.txt')</code>|1208(UTF8)|LF|
||<code>> CPYTOSTMF FROMMBR('/qsys.lib/qgpl.lib/qclsrc.file<br>&nbsp;&nbsp;&nbsp;/qstrup.mbr') TOSTMF('/tmp/test4.txt')<br>&nbsp;&nbsp;&nbsp;DBFCCSID(5026) STMFCCSID(1208) ENDLINFMT(*LF)</code>|1208(UTF8)|LF|
|NetServer|(Windowsの右クリックメニューから新規テキストファイルを作成)|942(日本語シフトJIS)|CR+LF|
|FTP|<code>> ltype c 1208<br>&nbsp;> put qgpl/qclsrc.qstrup /tmp/test8.txt</code>|819(ISO 8859-1)**※1**|CR+LF|
|PASEコマンド**※2**|<code>$ echo 漢字 > /tmp/test9.txt</code>|1208(UTF8)|LF|
||<code>$ export TERM=xterm<br>&nbsp;$ vi /tmp/test10.txt</code>|1208(UTF8)|LF|

<font size="-3">
※1：テキストファイルの内容は転送元のEBCDIC(ファイルQGPL/QCLSRCのCCSID)からUTF-8に変換される。<br>
※2：漢字(DBCS)を使用する場合、記載のコマンドの前に「$ export LANG=JA_JP.UTF-8」を実行。
</font>

<p>　</p>

### (参考) PASE上のファイル操作

このハンズオンではPASE(Linux)シェルの基本操作を習得するため、標準的なコマンドのみを利用しています。これらに習熟している、あるいは、sshクライアントでディレクトリーの作成やファイルの編集などの操作を行うのが難しい時は、下記のような方法で進めても良いでしょう。

* IBM iに全てのOSSがインストール済みの場合、「/QOpenSys/pkgs/bin/mc」を実行すればCUIファイラーの「GNU Midnight Commander」が利用可能。<br>ファイルをタブとカーソルで選択し、操作をメニューバーやフッター(コマンドキー)で指定(マウス操作も可能)。新規ファイル作成は「Shift+F4」。

![2.3_MC画面.jpg](/files/2.3_MC画面.jpg)

* ハンズオン・サーバーの「/home」をNetServerで共有していれば、Windowsの通常の操作でディレクトリー(フォルダー)の作成やファイルの編集が行なえる。ただし、文字コードや改行コードに注意が必要。
* ファイル操作が不要でテキストファイルの編集だけであれば軽量なnanoエディターが便利。「/QOpenSys/pkgs/bin/nano ファイル名」で起動。また、5250画面があればEDTFコマンドなどでテキストファイルの作成・編集が可能。

<p>　</p>

### <u>ワーク2 OSS実行環境の準備</u>

**□ W2-1.** 「2.3.1 sshでPASE環境へのログイン」を参照し、sshクライアントからIBM iにログイン。

**□ W2-2.** 「2.3.2 シェル環境の設定」を参照して下記設定を行う。

* ディレクトリー「/home」下に自身のホームディレクトリー「osswxx」を作成。
* ログインスクリプトを作成し、ログイン時に下記環境が設定されるようにする。
* シェルをbashにする
* 環境変数「PATH」および「LANG」を設定する
* 環境変数「PATH」の先頭に「/QOpenSys/pkgs/bin」を追加
* 環境変数「LANG」に「JA_JP.UTF-8」を指定

**□ W2-3.** (オプション) 「set」コマンドを実行して環境を確認する。
