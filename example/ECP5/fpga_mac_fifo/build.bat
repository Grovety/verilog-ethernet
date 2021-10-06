setlocal
PATH=C:\cygwin64\bin;%PATH%
PATH=D:\LATICE\yosys-master;%PATH%
PATH=D:\LATICE\nextpnr-master\out\build\x64-Release;%PATH%
PATH=D:\LATICE\nextpnr-master\out\install\x64-Release\lib;%PATH%
PATH=D:\LATICE\OpenOCD-20210729-0.11.0\bin;%PATH%
cd fpga
make %1
