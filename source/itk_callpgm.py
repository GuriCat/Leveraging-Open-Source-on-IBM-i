from itoolkit import *
from itoolkit.lib.ilibcall import *

itransport = DirectTransport()
itool = iToolKit()  # Toolkit Object

itool.add(iCmd("cmd_chgcurlib", "chgcurlib osswxx"))
itool.call(itransport)
if 'success' in itool.dict_out("cmd_chgcurlib"):
	print("正常終了") 
else:
	print("エラー発生")
	exit()
print(itool.dict_out("cmd_chgcurlib"))

itool.clear()
itool.add(iPgm("call_opmpgm","OPMRPG")
	.addParm(iData("name","32A","鈴木"))
	.addParm(iData("resp","32A",""))
)
itool.call(itransport)
print(itool.dict_out("call_opmpgm").get("resp"))
print(itool.dict_out("call_opmpgm"))

itool.clear()
itool.add(iPgm("call_ilepgm","ILERPG")
	.addParm(iData("name","32A","山本"))
	.addParm(iData("resp","32A",""))
)
itool.call(itransport)
print(itool.dict_out("call_ilepgm").get("resp"))
print(itool.dict_out("call_ilepgm"))