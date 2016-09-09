//
//      This file for Award BIOS version 4.5 disassemble.
//
// History:
//
// 18.05.96 23:19 Started by Alexey Kulentsov
// 13/07/96 20:03 Edited for IDA 3.06.14 (OpOffset -> OpOff)

#include <idc.idc>

static main(void) {
  auto addr,x,i,base;

  base = 0xF000;   // The segment base
  x = base<<4;

  Message("Make Font at F000:FA6E\n");
  MakeByte(x+0xFA6E);
  MakeArray(x+0xFA6E,1024);
  MakeName(x+0xFA6E,"Font8x8");

  addr=0xFEE3;
  Message(form("Flags=%lX\n",GetFlags(x+addr)));
  if(Word(x+Word(x+addr))==0x501E)
  { Message("Award Int_Table at F000:FEE3 found\n");
    for(addr=0xFEE3;addr<0xFF1D;addr=addr+2)
    { GetFlags(x+addr);
      OpOff(x+addr,-1,x);
//    SetFlags(x+addr,0x416FLU);      
    }  
  }

  Message("Check for the stackless proc. calling\n");
  for(addr=0;addr<0x10000L;addr=addr+ItemSize(addr+x))
  {
        i=addr+x;
        // Check for the stackless proc. calling:
        //      mov sp, offset @@olabel
        //      jmp proc
        //@@olabel:
        //      dw      offset @@clabel
        //@@clabel:
        //      ; next instructions..
        if(Byte(i)==0xBC
        && Word(i+1)==addr+6
        && Word(i+6)==addr+8
        && Byte(i+3)==0xE9
        )
        {       auto ProcAddr;
/*                MakeCode(i);
                MakeCode(i+8);
*/
                AutoMark(i,AU_CODE);AutoMark(i+8,AU_CODE);
                Wait();
                MakeUnkn(i+6,1);
                MakeWord(i+6);

                OpOff(i+6,0,base);
                OpOff(i,1,base);
/*
                SetFlags(i+6,GetFlags(i+6)|FF_0OFF);
                SetFlags(i,GetFlags(i)|FF_1OFF);
*/
                ProcAddr=x+((Word(i+4)+addr+6)&0xFFFF);
                AutoMark(ProcAddr,AU_CODE);
                AutoMark(ProcAddr,AU_PROC);
/*              SetFlags(ProcAddr,GetFlags(ProcAddr)|FF_PROC);
                MakeProc(x+((Word(i+4)+addr+6)&0xFFFF),1); */
                Message(form("RetAddr in [[SP]] proc fixed at %04X\n",addr));
        } else
        // mov bx,const or mov di,const
        if(Byte(i)==0xBB || Byte(i)==0xBF)
        {       if(Word(i+1)==addr+5 && Byte(i+3)==0xEB)        // jmp short
                {       MakeCode(i);MakeCode(i+5);Wait();
                        OpOff(i,1,base);
                        Message(form("RetAddr in BX or DI proc fixed at %04X\n",addr));
                } else
                if(Word(i+1)==addr+6 && Byte(i+3)==0xE9)        // jmp near
                {       MakeCode(i);MakeCode(i+6);Wait();
                        OpOff(i,1,base);
                        Message(form("RetAddr in BX or DI proc fixed at %04X\n",addr));
                }
        }
  }
}
