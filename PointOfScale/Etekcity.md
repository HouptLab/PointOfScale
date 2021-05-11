## From Bluetooth explorer

Device: "Etekcity Nutrition Scale" = 45 74 65 6b 63 69 74 79 20 4e 75 74 72 69 74 69 6f 6e 20 53 63 61 6c 65
Address: 01-B3-A2-19-74-36

ServiceSearchAttributeRequest:
	ServiceSearchPattern = { <1002> };
	MaximumAttributeByteCount = 0xffff;
	AttributeIDList = { 0x0000-0xffff };
	
	
Service UUID: 1910
Manufacturer Data: { length = 10, bytes = 0xc0a2367419a2b3010201}

UUID 180A
    2A23 0x367419a2b301 Read
    2A50 0x01940000001001 Read
  UUID 1910
     2C12   Value   Notify, Indicate
     2C11 Value WriteWOResponse, Write
     2C10 0x367419a2b301 Read

## Turn on Scale

```
Mar 07 08:39:41.705  HCI Event        0x0000  01:B3:A2:19:74:36  LE - Advertising Report - 1 Report - Normal - Public - 01:B3:A2:19:74:36  -80 dBm - Manufacturer Specific Data - Channel 39/38  
	Parameter Length: 31 (0x1F)
	Num Reports: 0X01
	Report 0
		Event Type: Scan Mode: Normal Scan Mode - Channel: 39/38 - Antenna: BT - Connectable Undirected Advertising (ADV_IND)
		Address Type: Public
		Peer Address: 01:B3:A2:19:74:36
		Data Length: 19
		Flags: 0X06
		16 Bit UUIDs: 0X1910 
		Data: 02 01 06 03 03 10 19 0B FF C0 A2 36 74 19 A2 B3 01 02 01 
		RSSI: -80 dBm
Mar 07 08:39:41.705  HCI Event        0x0000                     00000000: 3E1F 0201 2000 3674 19A2 B301 1302 0106  >... .6t........  
	00000000: 3E1F 0201 2000 3674 19A2 B301 1302 0106  >... .6t........
	00000010: 0303 1019 0BFF C0A2 3674 19A2 B301 0201  ........6t......
	00000020: B0                                       

```


```
Mar 07 08:39:41.724  HCI Command      0x0000  01:B3:A2:19:74:36  LE Add Device To White List - Public - 01:B3:A2:19:74:36  
	Opcode: 0x2011 (OGF: 0x08    OCF: 0x11)
	Parameter Length: 7 (0x07)
	Address Type: Public
	Address: 01:B3:A2:19:74:36
Mar 07 08:39:41.724  HCI Command      0x0000                     00000000: 1120 0700 3674 19A2 B301                 . ..6t....  
	00000000: 1120 0700 3674 19A2 B301                 . ..6t....


```




```
Mar 07 08:39:41.706  HCI Event        0x0000  01:B3:A2:19:74:36  LE - Advertising Report - 1 Report - Normal - Public - 01:B3:A2:19:74:36  -80 dBm - Etekcity Nutrition Scale - Channel 39/38  
	Parameter Length: 38 (0x26)
	Num Reports: 0X01
	Report 0
		Event Type: Scan Mode: Normal Scan Mode - Channel: 39/38 - Antenna: BT - Scan Response (SCAN_RSP)
		Address Type: Public
		Peer Address: 01:B3:A2:19:74:36
		Data Length: 26
		Local Name: Etekcity Nutrition Scale
		Data: 19 09 45 74 65 6B 63 69 74 79 20 4E 75 74 72 69 74 69 6F 6E 20 53 63 61 6C 65 
		RSSI: -80 dBm
Mar 07 08:39:41.706  HCI Event        0x0000                     00000000: 3E26 0201 2400 3674 19A2 B301 1A19 0945  >&..$.6t.......E  
	00000000: 3E26 0201 2400 3674 19A2 B301 1A19 0945  >&..$.6t.......E
	00000010: 7465 6B63 6974 7920 4E75 7472 6974 696F  tekcity Nutritio
	00000020: 6E20 5363 616C 65B0                      n Scale.
```




## Handle Value Notification from Etekcity

```
Mar 07 08:41:31.857  ATT Receive      0x0041  00:00:00:00:00:00  Handle Value Notification - Handle:0x000D - Value: FEEF C0A2 D005 0007 2600 0103   
 Handle Value Notification - Handle:0x000D - Value: FEEF C0A2 D005 0007 2600 0103 
 Opcode: 0x001B
 Attribute Handle: 0x000D (13)
Mar 07 08:41:31.857  L2CAP Receive    0x0041  00:00:00:00:00:00  Channel ID: 0x0004  Length: 0x000F (15) [ 1B 0D 00 FE EF C0 A2 D0 05 00 07 26 00 01 03 ]  
 Channel ID: 0x0004  Length: 0x000F (15) [ 1B 0D 00 FE EF C0 A2 D0 05 00 07 26 00 01 03 ]
 L2CAP Payload:
 00000000: 1B0D 00FE EFC0 A2D0 0500 0726 0001 03    ...........&...
Mar 07 08:41:31.857  ACL Receive      0x0041  00:00:00:00:00:00  Data [Handle: 0x0041, Packet Boundary Flags: 0x2, Length: 0x0013 (19)]  
 Packet Boundary Flags: [10] 0x02 - First Packet Of Higher Layer Message (i.e. Start Of An L2CAP Packet)
 Broadcast Flags: [00] 0x00 - Point-to-point
 Data (0x0013 Bytes)
Mar 07 08:41:31.857  ACL Receive      0x0000                     00000000: 4120 1300 0F00 0400 1B0D 00FE EFC0 A2D0  A ..............  
 00000000: 4120 1300 0F00 0400 1B0D 00FE EFC0 A2D0  A ..............
 00000010: 0500 0726 0001 03                        ...&...
 
```

00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22
41 20 13 00 0F 00 04 00 1B 0D 00 FE EF C0 A2 D0 05 00 07 26 00 01 03

| index | value | description                             |
| ---:  | :----: | :----                                 |
|  0     | 41    |   Handle        |
|  1     | 20    |   Packet Boundary Flags 0x02?  nibble: 2  Broadcast flag 0x00 nibble: 0 Point to point?       |
|  2-3   | 13 00 |   length of ACL Receive        |
|  4-5   | 0F 00 |   (start of ACL receive) length of L2CAP Receive 0x000F = 15      |
|  6-7   | 04 00 |   channel id: 0x0004
|  8     | 1B    |   start of data (8-22 = 15 bytes); opcode  1B -> 0x001B      |
|  9-10  | 0D 00 |   attribute handle (0x0D -> 0x000D = 13)  little endian?   |
|  11    | FE    |   start of Handle Value:  FEEF C0A2 D005 0007 2600 0103    |
|  12    | EF    |           |
|  13    | C0    |           |
|  14    | A2    |           |
|  15    | D0    |   packet type: D0 -> weight   |
|  16    | 05    |   length of packet: 0x05 -> 5 bytes for weight     |
|  17    | 00    |   sign: 0x00 positive ; 0x01 negative |
|  18-19 | 07 26 |   weight, big endian: 0x07 0x26 --> 1830 --> 183.0 g |
|  20    | 00    |   unit: 0x00(g),0x01(lboz),0x02(ml),0x03(floz),0x04(ml milk),0x05(floz milk),0x06(oz) |
|  21    | 01    |   stable: 0x00 measuring; 0x01 settled |
|  22    | 03    |   signal strength in dB as 1's complement        |

### Packet Type: 

D0 weight (5 bytes -- see weight table) ; 
D2 characteristic listening started    (1 byte, unknown) 
D3 tare (1 byte: 00 no tare; tare mode); 
E0 error mode (1 byte: 00 error reset, 01 error triggered); 
E4 item (1 byte: 00 = has item, 01 = no item);

