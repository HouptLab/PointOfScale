Etekcity Luminary Smart Nutrition Scale
model # ENS-L221S-SUS

FROM LIGHTBLUE:


UUID: 1BBEE1E5-923F-7DDO-7904-10BDB992BCEC

Manufacturer Data: [OxD006]: 0x016706040E93390202

Services:
OxFFFO
OxFFF2 Properties: Write without Response


OxFFF1 Properties: Notify (so subscribe to 0xFFF1)
0x180A
0x2A27 Properties: Read
0x2A28 Properties: Read

FFF0 service with notifications:

216g: (xD8) *10 = 0x870

0xA5 22 02 0B 00 7D 01 87 A1 00 00 7A 08 00 02 00 01
                                   __ __
18g: (x12) *10 = 0xB4

0xA5 22 10 0B 00 47 01 87 A1 00 00 AA 00 00 02 00 01
                                   __
58g *10 = 0x244

0xA5 22 17 0B 00 B8 01 87 A1 00 00 30 02 00 02 00 01

0xA5 02 03 0B 00 D9 01 87 A1 00 00 44 02 00 02 00 00
   0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 
                                   __ __
OxA5 02 04 05 00 34 01 78 A1 00 01

0g

0xA5 02 21 0B 00 C5 01 87 A1 00 00 3A 02 00 02 00 00
OxA5 02 0C 05 00 2C 01 78 A1 00 01

-57g = 0x243

0xA5 02 05 0B 00 E0 01 87 A1 00 01 3A 02 00 02 00 00
0xA5 02 04 05 00 34 01 78 A1 00 01

stable weight?


2.00 oz 200 = 0xC8

OxA5 22 1E 0B 00 13 01 87 A1 00 00 CD 00 00 04 01 01
   0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16      
               0  1  2  3  4  5  6  7  8  9 10 11 12
               
               
value[10] = sign: 0x00 positive ; 0x01 negative     
weight = value[11] + 256* value[12] / 10
value[14] = unit
00 oz
01 lb oz
02 g
03 ml
04 fl oz

value[15] 

value[16]  measuring = 0  stable = 1
(note: zero value is sometimes left as "measuring")


OxA502110B00FA0187A10000190000000000
OxA502100B00740187A100009F0100000000
