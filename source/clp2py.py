import sys, subprocess

if len(sys.argv) > 2 :
    cmdStr = "SNDBRKMSG MSG('こんにちは、" + sys.argv[2] + \
             "さん。') TOMSGQ(" + sys.argv[1]  + ")"
else :
    cmdStr = "SNDBRKMSG MSG('パラメーターが必要です。') TOMSGQ(" + \
             sys.argv[1]  + ")"

res = subprocess.run(["system", "-v", cmdStr], stdout=subprocess.PIPE)
sys.stdout.buffer.write(res.stdout)
print()
cmdRc = res.returncode
print("実行したCLのリターンコード:" + str(cmdRc))

if len(sys.argv) < 3 or cmdRc > 0 :
    print("エラーで終了。")
    sys.exit(1)
else :
    print("正常終了。")
