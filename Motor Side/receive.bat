asm86 init.asm m1 ep db
asm86 motors.asm m1 ep db
asm86 converts.asm m1 ep db
asm86 mtrevnt.asm m1 ep db
asm86 mtrtbl.asm m1 ep db
asm86 parsing.asm m1 ep db
asm86 qproc.asm m1 ep db
asm86 rcvfunc.asm m1 ep db
asm86 motore.asm m1 ep db
asm86 rcvmain.asm m1 ep db
asm86 serial.asm m1 ep db
asm86 srlevnt.asm m1 ep db
asm86 srltab.asm m1 ep db
asm86 trigtbl.asm m1 ep db
link86 init.obj,motors.obj,mtrevnt.obj,mtrtbl.obj,parsing.obj,qproc.obj,converts.obj,motore.obj to temp1.lnk
link86 serial.obj,srlevnt.obj,srltab.obj,trigtbl.obj,rcvfunc.obj,rcvmain.obj to temp2.lnk
link86 temp1.lnk,temp2.lnk to receiver.lnk
loc86 receiver.lnk to receiver noic AD(SM(code(4000H),data(400H), stack(7000H)))