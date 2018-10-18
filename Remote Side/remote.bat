asm86 converts.asm m1 ep db
asm86 display.asm m1 ep db
asm86 keyfunc.asm m1 ep db
asm86 init.asm m1 ep db
asm86 keypad.asm m1 ep db
asm86 qproc.asm m1 ep db
asm86 rmtmain.asm m1 ep db
asm86 rmtpars.asm m1 ep db
asm86 segtab14.asm m1 ep db
asm86 serial.asm m1 ep db
asm86 srlevnt.asm m1 ep db
asm86 srltab.asm m1 ep db
asm86 tmrevnt.asm m1 ep db
link86 converts.obj,display.obj,keyfunc.obj,keypad.obj,init.obj,qproc.obj,rmtpars.obj,segtab14.obj,serial.obj to temp1.lnk
link86 srlevnt.obj,srltab.obj,tmrevnt.obj,rmtmain.obj to temp2.lnk
link86 temp1.lnk,temp2.lnk to remote.lnk
loc86 remote.lnk to remote noic AD(SM(code(4000H),data(400H), stack(7000H)))