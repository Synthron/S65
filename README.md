# S65
Yet another 8bit Retro Computer

## ToDo

- Finish Hardware
- Software
  - [ ] WozMon
    - [ ] original (sort of)
    - [ ] extended for block write
  - [ ] Kernel Functions
    - [ ] General SysCalls
    - [ ] Hardware Drivers
    - [ ] 
  - [ ] RAM-Kernel
  - [ ] Basic
  - [ ] EhBasic
  - [ ] File System
  - [ ] Operating System
  - [ ] 

## Hardware

- Overview System Schematic
  - [x] CPU
  - [x] ROM
  - [x] RAM
  - [x] Bank/IRQ
  - [x] LCD/IRQ
  - [x] SIO
  - [x] PIO
  - [x] User Ports
  - [x] IDE
  - [x] CF
  - [x] SID
  - [x] RTC
  - [x] Clock Generation

---

- Seperate Modules
  - [ ] Bus Board
    - screw holes for card latches
    - design card latches
  - [x] CPU
  - [x] ROM
  - [x] RAM
  - [x] Bank/IRQ
  - [x] LCD/IRQ
  - [x] SIO
  - [x] PIO
  - [x] User Ports
  - [x] IDE
  - [x] Simple-IDE
  - [x] CF
  - [x] SID
  - [x] Addr + RTC + Clock
  - [x] Prototyping Board

## Software Brainstorm

- EhBasic
  - maybe Microsoft Basic? See Ben Eater
    - both in different banks
- WozMon Main Boot
- Serial Program Bootloader
- File System (FAT?)
- DOS-Like UI

boot routine:
- selftest
  - RAM Check
  - ROM Check + version
- Load Kernel functions to RAM
- Start Monitor

## Memory Map

General:

| Start | End  | Usage      |
|-------|------|------------|
| 0000  | 7FFF | RAM        |
| 8000  | BEFF | RAM Banked |
| BF00  | BFFF | IO Space   | 
| C000  | FFFF | ROM Banked |

IO Space:

| Start | End  | Usage         |Size|
|-------|------|---------------|----|
| BF00  | BF07 | Bank & IRQ    | 8  |
| BF08  | BF0F | TPI IDE       | 8  |
| BF10  | BF1B | ---           | 12 |
| BF1C  | BF1F | PIA LEDs      | 4  |
| BF20  | BF2F | VIA 1 LCD IRQ | 16 |
| BF30  | BF3F | VIA 2         | 16 |
| BF40  | BF4F | VIA 3         | 16 |
| BF50  | BF53 | ACIA 1        | 4  |
| BF54  | BF57 | ACIA 2        | 4  |
| BF58  | BF5B | ACIA 3        | 4  |
| BF5C  | BF5F | ACIA 4        | 4  |
| BF60  | BF7F | SID 8580      | 32 |
| BF80  | BF87 | Simple IDE    | 8  |
| BF88  | BF8F | CF Card       | 8  |
| BF90  | BF9F | RTC           | 16 |
| BFA0  | BFFF | ---           | 96 | 