#!/QOpenSys/pkgs/bin/python
import cgi

print("Content-Type: text/plain; charset=utf-8\r\n")

form = cgi.FieldStorage()
print("こんにちは、" + form["name"].value + "さん。")
