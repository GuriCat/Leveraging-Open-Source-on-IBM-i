# 3 IBM iでのPython基本操作


この章ではIBM iのPythonで基本的な操作を行います。Python言語自体の解説は各種書籍やインターネットの情報を参照ください。

なお、IBM iではPythonの他にも多くのプログラミング言語がOSSとして利用可能です。R、Node.js、perlなどの他のスクリプト言語を利用する場合にこのハンズオンの経験が参考になるでしょう。下表は2022年12月時点においてPASE環境で利用できる主要なプログラミング言語です。

|言語|言語種別|配布元・参照先|
|----|-------|-------------|
|gcc、GFortran、Java|コンパイラ|IBMのrpmリポジトリー|
|perl、Python、R、Node.js|スクリプト(インタープリター)|IBMのrpmリポジトリー|
|PHP||https://www.ibm.com/support/pages/node/6226878|
|ruby (on Rails)||https://github.com/AndreaRibuoli/RIBY|

<font size="-3">
※ gccなど一般的なコンパイラはソースコードをターゲットCPUの機械語に変換する。JavaはJVM(Java仮想マシン)が実行できる「バイトコード」に変換。
</font>


<p>　</p>

## 3.1 Python環境の確認

Pythonを実行する前に、インストール状況と実行環境を確認しましょう。2023年1月時点でIBM iで利用できるPythonには下記バージョンがあります。

?> Pythonのリリース・サイクルは https://devguide.python.org/versions/#versions などを参照。

|バージョン|Pythonバイナリー|備考|
|---------|---------------|----|
|2.7|/QOpenSys/pkgs/bin/python2.7|2020年1月1日サポート終了|
|3.6|/QOpenSys/pkgs/bin/python3.6|2021年12月23日サポート終了|
|3.9|/QOpenSys/pkgs/bin/python3.9|最新バージョンは3.11|

<font size="-3">
※ メモリー割当(malloc)強化版とされる「python3.6m」も存在するが、IBM iのPythonバイナリーはcmpおよびmd5sumハッシュの比較で「python3.6」と同一。
</font>

<br>

まず、デフォルトのPythonバージョンを確認します。下の例では「3.6.15」となります。
```bash
bash-5.1$ python -V 
Python 3.6.15 
```

<br>

### (参考) Pythonのデフォルトバージョンの設定

PASE環境ではalternatives コマンドでデフォルトのPythonバージョンを指定できます。下の例では「/QOpenSys/pkgs/bin/python3.6」がデフォルトです。 

?> alternativesは機能の重複するプログラムのいずれをデフォルトとするか設定する汎用の仕組みおよびコマンドで、RedHatなどいくつかのLinuxのディストリビューションにも含まれている。この画面からデフォルトのPythonバージョンを変更するとサーバー全体に適用されるので、実施には配慮が必要。

```bash
bash-5.1$ alternatives --config python
There are 3 choices for the alternative python (providing /QOpenSys/pkgs/bin/python).

  Selection    Path                          Priority   Status
------------------------------------------------------------
  0            /QOpenSys/pkgs/bin/python3.9   309       auto mode
  1            /QOpenSys/pkgs/bin/python2.7   207       manual mode
* 2            /QOpenSys/pkgs/bin/python3.6   306       manual mode
  3            /QOpenSys/pkgs/bin/python3.9   309       manual mode

Press <enter> to keep the current choice[*], or type selection number:
```

下記の要領で、alternativesコマンドで設定された環境を追跡できます。

* Python (実行コマンド)	
  * ① whichでフルパスを確認→/QOpenSys/pkgs/bin/python (シンボリックリンク)
    * ② lsでリンク先を確認→/QOpenSys/etc/alternatives/python (シンボリックリンク)
      * ③ lsでリンク先を確認→/QOpenSys/pkgs/bin/python3.6
        * ④ lsでリンク先が無いので、最終的に実行されるバイナリと確定

実施例を以下に示します。

```bash
bash-5.1$ which python                               ①「python」のフルパス確認
/QOpenSys/pkgs/bin/python
bash-5.1$ ls -la /QOpenSys/pkgs/bin/python           ②リンク先確認
lrwxrwxrwx 1 xxxxxx 0     66 Jul 22  2020 /QOpenSys/pkgs/bin/python -> /QOpenSys/etc/alternatives/python
bash-5.1$ ls -la /QOpenSys/etc/alternatives/python   ③リンク先確認
lrwxrwxrwx 1 xxxx 0 56 Nov 21 23:03 /QOpenSys/etc/alternatives/python -> /QOpenSys/pkgs/bin/python3.6                      
bash-5.1$ ls -la /QOpenSys/pkgs/bin/python3.6        ④リンク先確認→確定
-rwxr-xr-x 2 qsys 0 235202 Dec 18  2021 /QOpenSys/pkgs/bin/python3.6 
```

<br>

## 3.2 対話型にPythonを実行

Pythonではスクリプトを実行するのが一般的ですが、簡単なテストや機能の実行などはスクリプトなしでPythonのコードを実行できます。

以下、特に指定の無い場合は<u>**Pythonバージョン3.6以降**</u>を使用します。

<br>

### 3.2.1 Pythonの対話モード

引き数無しでPythonを実行すると対話モードに入ります。変数に値を代入してこれを画面に表示してみます。

?> 「対話モード」は、Python標準のREPL(Read-Eval-Print Loop)と呼ばれる機能。

```python
bash-5.1$ python
Python 3.6.15 (default, Dec 17 2021, 09:57:34)
[GCC 6.3.0] on aix7
Type "help", "copyright", "credits" or "license" for more information.
>>> name='IBM i '
>>> print(name+'さん')
IBM i さん
>>> (Ctrl+z)
[1]+  Stopped                 python
bash-5.1$
```

対話モードの終了は「Ctrl+z」(Windows 10標準sshクライアントの場合)または「exit()⏎」を打鍵します。

変数「name」の宣言や型指定が無い事に留意ください。Pythonでは変数の型を宣言する必要がなく、型が動的に設定されます。

```python
>>> a=123
>>> print(a+321)
444
>>> a='abc'
>>> print(a+321)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: must be str, not int
>>>
```

Pythonの基本データ型にはint(整数)、float(小数点)、str(文字列)、bool(真偽値)、list(リスト)、tuple(タプル)、dict(辞書)があります。ある時点の変数の型はtype()関数で確認できます。文字⇔数値変換や、文字列のエンコード変換を行う際には、対話モードで型を確認すればエラーを見つけやすいでしょう。

?> タプル型は中身の変更ができないリスト型に近い。Pythonでは「定数」が定義できないので、値が変わらない事を明確にしたい場合などに利用。

<br>

### 3.2.2 Pythonの引き数でコードを実行

Pythonコマンドを呼び出すときに「-c」オプションで実行するコードを指定できます。bashなどのシェルに組み込むこともできるので、知っておくと役に立つかもしれません。

?> これらは1行(1回の実行)で完結する事から「ワンライナー」(one liner)と呼ばれる。

<br>

指定したホスト名のIPアドレスを表示する例です。Pythonで同じ行に複数の命令を記述するには「;」(セミコロン)を使います

```bash
bash-5.1$ python -c 'import socket; print(socket.gethostbyname("localhost"))'
127.0.0.1
```

IBMのOSSサイト(https://ibmi-oss-docs.readthedocs.io/en/latest/troubleshooting/YUM.html )ではホストhttps通信の可否チェックに使用しています。

```bash
bash-5.1$ /QOpenSys/pkgs/bin/python2.7 -c "import socket; import ssl; hostname='public.dhe.ibm.com'; ssl.create_default_context().wrap_socket(socket.create_connection((hostname,443), 30), server_hostname=hostname) ; print 'success'"
success
```

同じコマンドを下記のように複数行で記述できます。

```python
bash-5.1$ python -c "\
> import socket;
> import ssl;
> hostname='public.dhe.ibm.com';
> ssl.create_default_context().wrap_socket(socket.create_connection((hostname,443), 30), server_hostname=hostname);
> print('success');
> "
success
```
<br>

別の例として、文字コードの確認をしてみます。Pythonの標準文字コード（バージョン3.x以降）は UTF-8であり、下記のコードで確認できます。

```bash
bash-5.1$ python -c 'import sys; print(sys.getdefaultencoding())'
utf-8
```
<br>

次の例では指定した文字列の16進表記を出力します。エンコードによって内部表現が異なる事がわかります。

?> Pythonで利用可能なコーディングは「標準エンコーディング」(https://docs.python.org/ja/3/library/codecs.html#standard-encodings )に記載あり。

```bash
bash-5.1$ python -c 'print("abc123あいう".encode("utf_8").hex())'
616263313233e38182e38184e38186
bash-5.1$ python -c 'print("abc123あいう".encode("cp932").hex())'
61626331323382a082a282a4
```

<br>

### <u>ワーク3 Pythonの直接実行</u>

**□ W3-1.** sshクライアントからIBM iにログインし、「python -V」でPythonのバージョンが3である事(3.6.x、3.9.xなど)を確認。

**□ W3-2.** Pythonの対話モードに入り、print文で「こんにちは」と表示する。

**□ W3-3.** Pythonの対話モードで自分の年齢を求める。次のコードを入力し、最後に自分の年齢が表示される事を確認。各行のインデントの有無と桁ずれが無い事を意識して入力。

?> Pythonはインデント(タブやスペース文字による字下げ)がブロック(グループ)を表す。Pythonの標準コーディング規約であるPEP8(Python Enhancement Proposals 8)ではインデントはスペース(空白文字)4文字を推奨。

```python
bash-5.1$ python⏎
Python 3.6.15 (default, Dec 17 2021, 09:57:34)
[GCC 6.3.0] on aix7
Type "help", "copyright", "credits" or "license" for more information.
>>> import datetime⏎
>>> def age(year, month, day):⏎
...     today = datetime.date.today()⏎
...     birthday = datetime.date(year, month, day)⏎
...     return (int(today.strftime("%Y%m%d")) - int(birthday.strftime("%Y%m%d"))) // 10000⏎
... ⏎
>>> print(age(1984,4,22))⏎    ←生年月日を指定
38                             ←今日時点の年齢
>>> exit()⏎
bash-5.1$
```

**□ W3-4.** 「<code>python -c 'import socket; print(socket.gethostbyname("ホスト名"))'</code>」を任意のホストに対して実行し、IPアドレスが表示されるか確認。

(実行例)

```bash
bash-5.1$ python -c 'import socket; print(socket.gethostbyname("google.com"))'
142.250.199.110
```

<font size="-3">
※	名前解決ができない場合、IBM iに5250画面から高権限ユーザーでサインオンし、CHGTCPDMN⇒F4の表示で「ドメイン・ネーム・サーバー」(INTNETADRパラメーター)が登録されているか確認。登録されていない場合、CFGTCP⇒「10. TCP/IPホスト・テーブル項目の処理」に登録されているホスト名を指定。
</font>

<br>

## 3.3 Pythonスクリプトの実行

この節ではPythonスクリプトを作成・実行します。Pythonスクリプト(ファイル)は次のような形式で呼出します。

|呼出し方|例|備考|
|-------|--|----|
|pythonコマンドの引き数で指定|python スクリプト名|実行するpythonのバージョンはフルパス指定や、alternativesで設定|
|スクリプト名のみ指定|./スクリプト名|1行目にシバン(Shebang) を指定。通常は次のいずれか。<br>・ Pythonバイナリへのフルパス<br>・ envコマンドでPythonバイナリのパスを指定<br>スクリプトのパーミッションに実行権限が必要|

?> Windowsのcmd.exeは「現行ディレクトリー」⇒「PATH環境変数」の順でコマンドが検索するが、Linuxなどの環境では現行ディレクトリーはデフォルトで検索されない。このため、現行ディレクトリーに存在するスクリプトを実行するには環境変数PATHに現行ディレクトリー「.」を指定するか、「./」でスクリプトのパスを明示指定する。
<br>

?> 「シバン」はLinuxなどでスクリプトの1行目に記述する文字列(通常「#!」で始まる)やその仕組み、スクリプトを実行するインタープリタ(シェルやスクリプト言語)を指定。

以下ではPythonスクリプト「script.py」をそれぞれの方法で呼び出します。

<br>

### 3.3.1 Pythonスクリプトの準備

echoコマンドでスクリプトファイルを作成します。1行目は「#」のみになります。

```bash
bash-5.1$ echo '#' > script.py
```

2行目に、実行しているPythonのバージョンを表示するコードを追加します。

?> Pythonのコーディング規約(PEP8)では、基本的に1行1ステートメントを推奨。

```bash
bash-5.1$ echo 'import platform; print("Python バージョン "+platform.python_version())' >> script.py
```

catコマンドでスクリプトファイルの内容を確認します。

```bash
bash-5.1$ cat script.py
# 
import platform; print("Python バージョン "+platform.python_version())
```

<br>

### 3.3.2 Pythonコマンドの引き数でスクリプトを呼出し

Pythonコマンドの引き数にスクリプトファイルを指定して呼び出します。使用されるPythonのバージョンは「(参考) Pythonのデフォルトバージョンの設定」で解説したバージョンになります。

```bash
bash-5.1$ python script.py 
Python バージョン 3.6.15
```

明示的にバージョンを使い分ける場合などはPythonコマンドの絶対パスを指定します。

```bash
bash-5.1$ /QOpenSys/pkgs/bin/python3 script.py
Python バージョン 3.6.15
bash-5.1$ /QOpenSys/pkgs/bin/python3.9 script.py
Python バージョン 3.9.14
```

Python2は3系列と文字コードの扱いが異なり、日本語を含むソースをそのまま実行するとエラーになります。このため、1行目にエンコーディングをUTF-8とする宣言を記述します。

?> Python3でデフォルトのソース エンコーディングがASCIIからUTF-8 に変更された。詳細はPEP3120(https://peps.python.org/pep-3120/ )を参照。

```bash
bash-5.1$ /QOpenSys/pkgs/bin/python2.7 script.py
  File "script.py", line 2
SyntaxError: Non-ASCII character '\xe3' in file script.py on line 2, but no encoding declared; see http://python.org/dev/peps/pep-0263/ for details
bash-5.1$ sed -i '1c # -*- coding: utf-8 -*-' script.py
bash-5.1$ cat script.py
# -*- coding: utf-8 -*-
import platform; print("Python バージョン "+platform.python_version())
bash-5.1$ /QOpenSys/pkgs/bin/python2.7 script.py
Python バージョン 2.7.18
```

<br>

### 3.3.3 Pythonスクリプト名のみで呼出し

次に、スクリプト名のみでPythonスクリプトを実行します。
<br>

「echo $PATH」で現行ディレクトリー「.」がPATHに存在することを確認します。

```bash
bash-5.1$ echo $PATH
/QOpenSys/pkgs/bin:/QOpenSys/usr/bin:/usr/ccs/bin:/QOpenSys/usr/bin/X11:/usr/sbin:.:/usr/bin                       ←「.」が現行ディレクトリー
```

スクリプト名のみで実行すると、パーミッションエラーになります。

```bash
bash-5.1$ script.py 
bash: ./script.py: 指定されたアクションにはファイルのアクセス権がありません。
```

chmodコマンドでスクリプトにユーザー実行権限を追加します。

```bash
bash-5.1$ chmod u+x script.py
```

再度実行すると、1行目の「#」はコメント行と解され、シェルスクリプトとして実行されてbashがエラーを返します。

```bash
bash-5.1$ script.py
./script.py: line 2: syntax error near unexpected token `"Python バージョン "+platform.python_version'
./script.py: line 2: `import platform; print("Python バージョン "+platform.python_version())'
```

1行目をPython3.9バイナリのフルパスを指定するシバンに置き換えて実行すると、Python3.9でスクリプトが実行されます。

```bash
bash-5.1$ sed -i '1c #!/QOpenSys/pkgs/bin/python3.9' script.py 
bash-5.1$ cat script.py
#!/QOpenSys/pkgs/bin/python3.9
import platform; print("Python バージョン "+platform.python_version())
bash-5.1$ script.py
Python バージョン 3.9.14 
```

シバンを環境変数からPythonを選択するように変更すると、環境変数から検索されたPython(この例では3.6.15)が呼ばれます。

```bash
bash-5.1$ sed -i '1c #!/QOpenSys/pkgs/bin/env python' script.py
bash-5.1$ cat script.py
#!/QOpenSys/pkgs/bin/env python
import platform; print("Python バージョン "+platform.python_version())
bash-5.1$ script.py
Python バージョン 3.6.15
```

<br>

### <u>ワーク4 Pythonスクリプトの実行</u>

**□ W4-1.** sshクライアントからIBM iにログインし、「python -V」でPythonのバージョン(2.7、3.6、3.9など)と環境変数PATHの値を確認。

**□ W4-2.** 自身のホームディレクトリに、実行中のPythonのバージョンを表示するスクリプト「script.py」を任意のエディターで作成・編集し、次の3通りの方法で実行する。

?> エディターには、汎用性からはvi、使いやすさからはmcまたはnanoを推奨。IBM iのEDTFコマンドを利用する場合、5250セッションのホスト・コード・ページが939か1399で構成されている事、ジョブのCCSIDが5035または1399である事、EDTFの「F15= 保守」で「3.  ファイルの CCSID の変更」に1208(UTF-8)、「5.  ｽﾄﾘｰﾑ･ﾌｧｲﾙ の EOL ｵﾌﾟｼｮﾝ」に「*LF」が指定されている事を確認。NetServerの共有フォルダーとしてWindowsから作成・編集する場合は、文字コードUTF-8、BOM(byte order mark)なし、改行コードLFを指定できるエディターを利用。

1.	Pythonコマンドの引き数にスクリプトを指定して実行。
1.	1行目(シバン)に任意のPythonバイナリを指定し、「スクリプト名」で実行。
1.	シバンに「#!(パス)/env Python」を指定し、「スクリプト名」で実行。

  ?> Pythonバイナリは、例えば「whereis -b python | sed 's/ /\n/g' | sort」や「alternatives --list python」でインストール済みのPythonを確認。

**□ W4-3.** (オプション) 運用状況を想定し、alternativesによるデフォルトバージョンの設定も含めて、「実行時のPythonバージョン選択」にどの方法が適切かを考察。

<br>

## 3.4 Python開発・実行環境

最新技術の実装や機能拡張が頻繁に行われるOSSでは、バージョン間で非互換性が発生するケースがままあります。OSSを利用したアプリケーションを長期間、安定して利用するために実行環境を分離する様々な技術、仮想マシン、chroot、Linux名前空間、AIXのWPAR、コンテナなどが、提案・利用されています。

?> 「chroot」はルートディレクトリーを変更し、外のディレクトリへのアクセスを禁止する機能。「名前空間」はLinuxカーネルのリソースを分離し、独立した環境のように見せる機能。「WPAR」はワークロード・パーティション(Workload Partition)の略。AIX 6.1で実装され、単一のAIXイメージ内に作成される仮想化されたAIX環境。

この節では、Python独自の仮想環境、および、ほとんどのPythonスクリプトで必要となる外部パッケージのインストールについて解説します。

<br>

### 3.4.1 Python仮想環境

Pythonは独自の軽量な「仮想環境」を提供しており、異なるバージョンのPython／外部パッケージを、独立した環境で利用できます。この仮想環境は「仮想マシン」や「コンテナ」と類似した機能であり、例えば「PEP 405 – Python仮想環境」によると、次のような目的で利用されます。

* 依存関係の管理と分離
* システム管理者のアクセスなしでのPythonパッケージのインストールと使用の容易さ
* 複数のPythonバージョンにわたるPython ソフトウェアの自動テスト

<br>

Python仮想環境は下表の操作例のように非常に容易に作成・利用・削除できます。

|操作|コマンド例|解説|
|-------------|---------|----|
|作成  |<code>bash-5.1$ pwd⏎<br>&nbsp;/home/OSSWXX</code>`|仮想環境作成先(現行ディレクトリー)を確認|
|    |<code>bash-5.1$ /QOpenSys/pkgs/bin/python3.9<br>&nbsp; -m venv py39venvxx⏎</code>|モジュール「venv」に仮想環境名(ディレクトリー名)を指定して実行し、新規の仮想環境を作成。例ではPython 3.9の仮想環境「py39venvxx」(「xx」はハンズオン用に使用する番号)をユーザーのホームディレクトリーに作成|
|    |<code>bash-5.1$ python –V⏎<br>&nbsp;Python 3.6.15</code>|作成したのみでは仮想環境は無効で、Pythonコマンドもデフォルトのバージョンのまま|
|有効化|<code>bash-5.1$ source py39venvxx/bin/activate⏎<br>&nbsp;(py39venvxx) bash-5.1$</code>|仮想環境ディレクトリー下の「activate」コマンドを実行すると仮想環境が有効になる。有効化時にはプロンプトの先頭に仮想環境名が表示される|
|      |<code>(py39venvxx) bash-5.1$ python -V⏎<br>&nbsp;Python 3.9.14</code>|Pythonのバージョンは仮想環境を作成したPythonである「3.9」となる|
|終了|<code>(py39venvxx) bash-5.1$ deactivate⏎<br>&nbsp;bash-5.1$</code>|deactivateコマンドで仮想環境を終了。プロンプトの表示が元に戻る|
|削除|<code>bash-5.1$ rm -rf py39venvxx/⏎</code>|仮想環境を削除するにはdeactivateした後に仮想環境のディレクトリーを削除|

<br>

### 3.4.2 Python外部パッケージ

Pythonで使用する機能(関数)は次のような形で提供されます。

|提供方法|例|import|インストール|備考|
|-------|--|------|-----------|----|
|組み込み関数|abs()、print()、help()、type()、zip() など|不要|不要|Pythonの思想に則り、すぐに使える機能が初めから豊富に用意されている。標準ライブラリの一覧は「pydoc modules」で表示|
|標準ライブラリ|datetime()、math()、socket()、ssl()、sys()、os()、csv()、json() など|必要|不要|(同上)|
|外部ライブラリ(パッケージ)|matplotlib、ReportLab、itoolkit など|必要|必要|pipコマンドでインストール。配布元ではPyPI が著名。インストール済みパッケージ一覧は「pip3 freeze」で表示|

?> 「Pythonの思想」を、Pythonの公式ドキュメントでは「バッテリー同梱 (batteries included)」(必要なものは全て揃っていてすぐ利用できる)哲学と表現。

?> PyPI(パイピーアイ。Python Package Index)は、Python向けのサードパーティーソフトウェアリポジトリ。PerlのCPAN(シーパン。Comprehensive Perl Archive Network)的なサイト。

それぞれの機能は次のように定義されます。

?> 関連した用語に「クラス」と「メソッド」があるが、当資料では触れない。

* 関数：print()などの命令で、渡した値に対して結果の値を返す
* モジュール：Pythonのコード(関数を含む)を記述したファイル。拡張子は「.py」
* パッケージ：関連するモジュールをまとめたファイル群

組み込み関数と標準ライブラリはPythonと一体で配布されるので、Pythonのバージョン間の非互換性に留意が必要です。一方、外部パッケージは対応するPythonバージョンの確認が必要です。

?> 例えば、2022年12月時点のmatplotlib 3.6.2はPython 3.8以上が前提とPyPIに記載あり。

また、外部パッケージを使用する場合は、このパッケージが呼び出す関連パッケージやモジュール、前提とするPythonのバージョンなどが相互に依存関係を持ちます。これらの整合性を維持するために膨大なワークロード、あるいは、専用のツールが必要となるケースも少なくありません。

?> このようなケースは俗に「依存関係地獄」(Dependency Hell)と呼ばれる。

<br>

例として、インストールされているパッケージの依存関係を表示する「pipdeptree」パッケージをpipコマンドでインストールします。

?> pipはPythonのパッケージ管理システム。「Pip Installs Packages」または「Pip Installs Python」の略。仮想環境ではシバンに「#!/home/OSSWXX/py39venvyy/bin/python(バージョン)」が記述されたpip、pip3、pip3.9が作成される。

```bash
(py39venvxx) bash-5.1$ pip install pipdeptree      ←パッケージをインストール
Collecting pipdeptree
  Downloading pipdeptree-2.3.3-py3-none-any.whl (16 kB)
Installing collected packages: pipdeptree
Successfully installed pipdeptree-2.3.3
(py39venvxx) bash-5.1$ pipdeptree                  ←依存関係の調査と出力
altair-saver==0.5.0
  - altair [required: Any, installed: 4.2.0]
    - entrypoints [required: Any, installed: 0.4]
    - jinja2 [required: Any, installed: 3.1.2]
      - MarkupSafe [required: >=2.0, installed: 2.1.1]
～～～～～～～～～～～～～～～ 中略 ～～～～～～～～～～～～～～～～～
stdlib-list==0.8.0
wheel==0.36.2
(py39venvxx) bash-5.1$ pipdeptree | wc -l         ←出力行数のカウント
146
(py39venvxx) bash-5.1$ pipdeptree -r              ←逆引き
async-generator==1.10
  - trio==0.22.0 [requires: async-generator>=1.9]
    - selenium==4.7.2 [requires: trio~=0.17]
      - altair-saver==0.5.0 [requires: selenium]
    - trio-websocket==0.9.2 [requires: trio>=0.11]
      - selenium==4.7.2 [requires: trio-websocket~=0.9]
～～～～～～～～～～～～～～～ 後略 ～～～～～～～～～～～～～～～～～
```
<br>

Pythonでは仮想環境ごとに外部パッケージをインストールし、管理対象の依存関係を最小限にしてアプリケーションの動作を確認・安定化する事が可能です。本番環境への影響を避けつつ、開発・テスト環境を構築する際に活用できるでしょう。

<br>

### 3.4.3 IBM iにおける外部パッケージと仮想環境の考慮点

IBM iでPythonの仮想環境を利用する際は、外部パッケージの配布方法の違いに留意が必要です。

他のプラットフォームではpipコマンドでインストールする外部パッケージの多くがIBM iではyumで提供されています。<b><u>同じパッケージがyumとpipの双方で提供されている場合はyum(RPM)でのインストールが推奨</b></u>されています。

?> 「Installing Python Packages」(https://ibmi-oss-docs.readthedocs.io/en/latest/python/INSTALLING_PYTHON_PKGS.html )参照。

<u><b><font color="blue">yum</font></b>コマンド、および、<b><font color="blue">デフォルト指定のpip</font></b>コマンドでインストールされた外部パッケージは<b><font color="blue">システム(グルーバル)のPython環境</font></b>にインストールされます。一方、仮想環境内で実行した<b><font color="#0ba334">pip</font></b>コマンドでインストールした外部パッケージは基本的にその<b><font color="#0ba334">仮想環境内</font></b>でのみ有効です。</u>

オプションを指定せずに作成した仮想環境からは、システムのPython環境にインストールされたほとんどのパッケージは見えません。IBMが提供するyumパッケージには多くの基本Pythonパッケージが含まれるので、仮想環境作成時に「<b><font color="blue">--system-site-packages</font></b>」オプションを指定して見える(利用できる)ようにする必要があるでしょう。下表はこれらの組合せによる外部パッケージの使用可否を示します。

?> オプションを指定せずに作成した仮想環境を「pip list」で確認すると、pipとsetuptools(Pythonのパッケージ開発プロセス ライブラリ)のみが存在。

![3.4.3_仮想環境.jpg](/files/3.4.3_仮想環境.jpg)

yumでインストールしたパッケージはrepoqueryコマンドで表示できます。

?> repoqueryコマンドの他にpyodbcの導入確認に利用したyum listも利用できる。結果をgrepしたり、ファイルに残したりする場合はrepoqueryコマンドを推奨。例えば導入済みかつ文字列「pyodbc」を含むパッケージのリストは「<code>repoquery --all --pkgnarrow=installed | grep pyodbc</code>」で得られる。

```bash
bash-5.1$ repoquery --all --pkgnarrow=installed | grep py
libsnappy1-0:1.1.8-1.ppc64
python-rpm-macros-0:3.6-6.noarch
～～～～～～～～～～～～～～～ 後略 ～～～～～～～～～～～～～～～～～
```

<br>

### (参考) yumで提供されるIBM i用Pythonパッケージ

?> 「バージョン」は2023年1月時点のPython 3.9対応版。

|パッケージ名|バージョン|備考|
|-----------|---------|----|
|bcrypt|3.2.0|パスワードハッシュ化関数|
|cffi|1.14.5|Cで実装された処理をPythonから呼び出すための仕組み|
|cryptography|3.4.7|暗号化ライブラリー|
|Cython|0.29.24|Python類似の言語からC言語のコードを生成|
|ibm-db|2.0.5.12|IBM Db2用のドライバー|
|itoolkit|1.7.0|IBM i 用 XMLSERVICE ツールキットへの Python インターフェース|
|lxml|4.6.3|XMLやHTMLファイル処理用ライブラリー|
|numpy|1.21.4|数値計算の高速化、効率化|
|pandas|1.3.4|データ解析を容易にする機能を提供|
|paramiko|2.7.2|SSHv2プロトコルのpure-Python実装。クライアントとサーバーの両方の機能を提供|
|Pillow|8.3.1|画像処理ライブラリー|
|psutil|5.8.0|実行中のプロセスやシステムの使用状況に関する情報を取得|
|psycopg2|2.9.1|PostgreSQLに接続するためのライブラリー|
|pycparser|2.20|C言語用のパーサー|
|PyNaCl|1.4.0|libsodium(暗号化、復号化、署名、パスワードハッシュなど)に対するPythonのバインディング|
|pyodbc|4.0.31|ODBCデータベースへのアクセス|
|python-dateutil|2.8.1|標準のdatetimeモジュールの強力な拡張|
|pytz|2021.1|タイムゾーン関連の処理|
|pyzmq|22.1.0|ØMQへのPythonバインディング|
|scikit-learn|1.0.1|機械学習ライブラリ|
|scipy|1.7.3|数学・科学・工学のための数値解析ソフトウェア|
|setuptools|57.0.0|Pythonパッケージのダウンロード、ビルド、インストール、アップグレード、アンインストール|
|six|1.16.0|Python2と3の互換性ライブラリー|
|threadpoolctl|3.0.0|スレッドプールで使用されるスレッド数を制限するためのPythonヘルパー|
|Wheel|0.36.2|Pythonのwheelパッケージ規格リファレンス実装|

<br>

### <u>ワーク5 Python仮想環境の操作</u>

**□ W5-1.** 自身のホームディレクトリ(「~」)にPython 3.9の仮想環境を「OSSWXX」という名前で「--system-site-packages」オプション指定で作成し、有効化。Pythonのバージョンを確認。

```bash
bash-5.1$ cd ~
bash-5.1$ pwd
/home/OSSWXX
bash-5.1$ python -V
Python 3.6.15
bash-5.1$ /QOpenSys/pkgs/bin/python3.9 -m venv py39venvxx --system-site-packages
bash-5.1$ source py39venvxx/bin/activate
(py39venvxx) bash-5.1$ python -V
Python 3.9.14
```

**□ W5-2.** 仮想環境にパッケージ「pipdeptree」をインストールして実行。インストール済みパッケージの依存関係が表示される事を確認。

**□ W5-3.** pipコマンドのリストオプションで仮想環境に「pipdeptree」が存在する事を確認。仮想環境を終了し、システム環境に「pipdeptree」が存在しない事を確認。

```bash
(py39venvxx) bash-5.1$ pip list | grep pipdep
pipdeptree         2.3.3
(py39venvxx) bash-5.1$ deactivate
bash-5.1$ pip list | grep pipdep
bash-5.1$
```

<br>

### 3.4.4 PythonからDb2 for iへのアクセス

この節では、PythonからODBCを利用してDBアクセスを行う「pyodbc」パッケージでスクリプトからDb2 for iを利用します。
Pythonで利用する前に、isqlコマンドでIBM iにODBC接続できることを確認します。

?> OSSからDb2 for iを利用する方法はODBCを推奨。詳細は「Why ODBC」(https://ibmi-oss-docs.readthedocs.io/en/latest/odbc/why-odbc.html )を参照。

?> isqlが正常に実行されない場合、「odbcinst -j」でODBCドライバーのインストール状況を確認。

```bash
bash-5.1$ isql --version
unixODBC 2.3.9
bash-5.1$ isql *local
+---------------------------------------+
| Connected!                            |
|                                       |
| sql-statement                         |
| help [tablename]                      |
| quit                                  |
|                                       |
+---------------------------------------+
SQL> select tkbang,tknakj from qeol.tokmsp where tkbang < '01100'
+----------------+----------------------------------------------------------+
| TKBANG         | TKNAKJ                                                   |
+----------------+----------------------------------------------------------+
| 01010          | 阿井旅館　　　　　                                 |
| 01020          | 阿井工業　　　　　                                 |
| 01030          | 相川工業　　　　　                                 |
| 01040          | 阿井旅行社　　　　                                 |
| 01050          | 阿井食品Ｋ．Ｋ　　                                 |
| 01060          | 阿井自動車　　　　                                 |
| 01070          | 相川カメラ　　　　                                 |
| 01080          | 相川広告Ｋ．Ｋ　　                                 |
| 01090          | 相川電機Ｋ．Ｋ　　                                 |
+----------------+----------------------------------------------------------+
SQLRowCount returns -1
9 rows fetched
SQL> quit (またはCtrl+C)
bash-5.1$
```

<font size="-3">
※	SQLの実行でエラーになる場合は、他のテーブル(qiws.qcustcdtなど)にアクセスする、-vオプションで詳細を表示する、isqlに-e(Use SQLExecDirect not Prepare)オプションを付けて実行する(例えば「isql *local -e」)、別のユーザーID/パスワードで接続する(例えば「isql *local ユーザーID パスワード」)、などを試行して原因を判別します。
</font>

<br>

<br>

次に、PythonからDBを利用できるかを確認します。

PythonからDb2 for iを利用するにはpyodbcパッケージを利用します。「1.2.1事前準備」ですべてのパッケージをインストールした場合はその中にpyodbcも含まれており、下記のようにして確認できます。

?> 「IBM i OSS Docs」サイトの「Why ODBC」(https://ibmi-oss-docs.readthedocs.io/en/latest/odbc/why-odbc.html )で、PythonからDb2 for iへの接続にはODBCの使用が推奨されている。ibm_dbパッケージを使用している例が散見されるが、要件に「LUW/zとのソースの共通化」がある場合などを除いてpyodbcの利用が望ましい。

```bash
bash-5.1$ yum list *pyodbc*
ibmi-base                                            | 3.6 kB  00:00
ibmi-base/primary_db                                 | 570 kB  00:03
ibmi-release                                         | 2.9 kB  00:00
ibmi-release/primary_db                              |  40 kB  00:00
インストール済みパッケージ
python3-pyodbc.ppc64                   4.0.27-0                  @ibm/7.4
python39-pyodbc.ppc64                  4.0.31-1                  @ibm/7.4
～～～～～～～～～～～～～～～ 後略 ～～～～～～～～～～～～～～～～～
```

pyodbcがインストール済みであれば、Pythonの対話モードでDb2 for iにアクセスしてSQLを実行します。この例ではデータベース「qeol.tokmsp」の始めの3行が表示されれば正常です。

?> fetchall()の結果はリスト型で返され、「\u3000」は全角ブランクのユニコードをエスケープした文字列。

```bash
bash-5.1$ python
Python 3.6.15 (default, Dec 17 2021, 09:57:34)
[GCC 6.3.0] on aix7
Type "help", "copyright", "credits" or "license" for more information.
>>> import pyodbc
>>> conn=pyodbc.connect('Driver={IBM i Access ODBC Driver};System=localhost;UID=osswxx;PWD=osswxx;')
>>> cursor=conn.cursor()
>>> cursor.execute("select * from qeol.tokmsp fetch first 3 rows only")
<pyodbc.Cursor object at 0x7000000002dbc60>
>>> print(cursor.fetchall())
[('01010', 'ｱｲ ﾘﾖｶﾝ             ', '阿井旅館\u3000\u3000\u3000\u3000\u3000', '東京都渋谷区\u3000\u3000\u3000', '桜ヶ丘２９\u3000\u3000\u3000\u3000', '02', '
～～～～～～～～～～～～～～～ 中略 ～～～～～～～～～～～～～～～～～
406  ', Decimal('136200'), Decimal('243000'), Decimal('796600'), Decimal('110000'), Decimal('1120000'), Decimal('880619'), '1')]
>>> cursor.close()
>>> conn.close()
>>>
[4]+  Stopped                 python
bash-5.1$
```
 
<br>

### <u>ワーク6 PythonからDb2 for iへのアクセス</u>

**□ W6-1.** isqlを*localに対して実行し、「QEOL/TOKMSP」、または、「QIWS/QCUSTCDT」にSQLでアクセスできることを確認。

**□ W6-2.** 自身のホームディレクトリ(「~」)に下記スクリプト「sql2csv.py」を作成して実行。生成されたCSVファイルをExcelなどで開いてデータが正常か確認。

```sql
0001 import pyodbc
0002 import pandas as pd
0003 
0004 conn = pyodbc.connect(
0005     'Driver={IBM i Access ODBC Driver}; System=localhost; UID=osswxx; PWD=osswxx;'
0006     )
0007 cursor = conn.cursor()
0008 sql = "select * from qeol.tokmsp fetch first 3 rows only"
0009 df = pd.read_sql(sql, conn)
0010 cursor.close()
0011 conn.close()
0012 
0013 df = df.applymap(lambda x: x.rstrip(" ""　") if isinstance(x, str) else x)
0014 csv = df.to_csv("./tokmsp.csv", header=True, index=False, quoting=2, encoding="cp932")
```

* 4～6行目：ODBCドライバーの設定。UIDとPWDはIBM iのユーザーID/パスワードを指定。
* 9行目：SQLの結果をpandas.DataFrameに取り込み。DataFrameは表形式のデータを保持し、行・列の選択、データの更新、ソートなど、RDBに類似した操作が可能。
* 13行目：ラムダ式(無名関数)で文字値の後続半角/全角ブランクを除去。rstrip()メソッドで指定している文字列の最初の「" "」は半角の空白、2番目の「"□"」は全角の空白。
* 14行目：to_csv ()メソッドでDataFrameをCSVに変換してファイル「./tokmsp.csv」に書き込む。「quoting=2」は文字項目のみをダブルクォーテーションで囲む指定。CSVファイルの文字コードはデフォルトでUTF-8となるが、これをExcelでそのまま開くと文字化けするため「encoding="cp932"」を指定してCSVファイルの文字コードをシフトJISに設定。

![ワーク6_Excelの絵.jpg](/files/ワーク6_Excelの絵.jpg)

<br>

### (参考) VS CodeによるPythonスクリプトの編集

短いコードや軽微な修正であればEDTFコマンドやviエディターで不便はありませんが、ある程度の長さのコードを編集する場合は「Visual Studio Code」(以下、VS Code)を利用すると効率的です。

VS Code(https://code.visualstudio.com/)はマイクロソフト社が2015年にリリースし、MITライセンスで配布しているコードエディター、もしくはIDE(Integrated Development Environment。統合開発環境)です。Windows 8以降、macOS X v10.11以降、Linux上で動作し、Pythonを含む多くのプログラミング言語やマークアップ言語をサポートします。

![3.4_参考_VS_Code.jpg](/files/3.4_参考_VS_Code.jpg)

VS Codeの拡張機能「Code for IBM i」(https://halcyon-tech.github.io/docs/#/ )をインストールすればILE-RPGやCLなどのソースコードも編集できます。Eclipseよりも軽量で拡張機能(プラグイン)も豊富であり、自組織のポリシーに制約が無ければインストールして評価することをお勧めします。

?> EclipseはTheia(テイア)やChe(チェ)などVS Codeのエディタ・エンジンを採用したIDEも提供。(https://www.eclipse.org/downloads/ )


