# S65xx Computer System

Yet another 8bit Retro Computer

Completely bloated, overkill and fully hackable!

## ToDo

- [x] Finish Hardware
- Software
  - [ ] WozMon
    - [x] Implement Serial IO
    - [x] Implement Input Buffer
    - [ ] extended for block write
  - [ ] Kernel Functions
    - [ ] General SysCalls
    - [ ] Hardware Drivers
  - [x] RAM-Kernel
  - [x] Basic
  - [x] EhBasic
  - [ ] File System
  - [ ] Operating System
- Hardware
  - [ ] order PCBs
  - [ ] order parts
  - [ ] solder together

## Hardware

- Modules
  - [x] Backplane Bus
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
  - [x] LPT Interface
  - [x] MyCPU Graphics Unit Interface

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

| Start | End  | Usage      | Size   |
|-------|------|------------|--------|
| 0000  | 7FFF | RAM        | 32.768 |
| 8000  | BEFF | RAM Banked | 16.128 |
| BF00  | BFFF | IO Space   |    256 |
| C000  | FFFF | ROM Banked | 16.384 |

IO Space:

| Start | End  | Usage         |Size|
|-------|------|---------------|----|
| BF00  | BF07 | Bank & IRQ    | 8  |
| BF08  | BF0F | TPI IDE       | 8  |
| BF10  | BF12 | LPT           | 2  |
| BF13  | BF14 | --- (LPT2)    | 2  |
| BF14  | BF16 | MyCPU VGA     | 3  |
| BF17  | BF1B | ---           | 5  |
| BF1C  | BF1F | PIA LEDs      | 4  |
| BF20  | BF2F | VIA 1 LCD IRQ | 16 |
| BF30  | BF3F | VIA 2         | 16 |
| BF40  | BF4F | VIA 3         | 16 |
| BF50  | BF53 | ACIA 1        | 4  |
| BF54  | BF57 | ACIA 2        | 4  |
| BF58  | BF5B | --- (ACIA 3)  | 4  |
| BF5C  | BF5F | --- (ACIA 4)  | 4  |
| BF60  | BF7F | SID 8580      | 32 |
| BF80  | BF87 | Simple IDE    | 8  |
| BF88  | BF8F | CF Card       | 8  |
| BF90  | BF9F | RTC           | 16 |
| BFA0  | BFFF | ---           | 96 |

## Interrupts

The TPI Chip for the memory banks also functions as a priority interrupt controller, providing 5 seperate interrupt lines.  
IRQ_0 is further divided into 8 lines for communication modules, giving an overall of 14 available IRQ-Lines.  

These are currently used as follows:

- IRQ -> TPI
  - IRQ_0 -> VIA0
    - IRQ_0.0 -> ACIA0
    - IRQ_0.1 -> ACIA1
    - IRQ_0.2 -> ACIA2
    - IRQ_0.3 -> ACIA3
    - IRQ_0.4 -> RTC
    - IRQ_0.5 -> ---
    - IRQ_0.6 -> ---
    - IRQ_0.7 -> ---
  - IRQ_1 -> VIA1
  - IRQ_2 -> VIA2
  - IRQ_3 -> ---
  - IRQ_4 -> ---
- NMI -> ---

Note that the NMI is connected to a push button on the bus board.
