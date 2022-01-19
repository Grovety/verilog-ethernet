setlocal
PATH=C:\cygwin64\bin;%PATH%
PATH=D:\LATICE\Yosys;%PATH%
PATH=D:\LATICE\Trellis\bin;%PATH%
PATH=D:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\Extensions\Microsoft\Python\Miniconda\Miniconda3-x64;%PATH%
PATH=D:\LATICE\OpenOCD-20210729-0.11.0\bin;%PATH%
set PYTHONHOME=D:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\Extensions\Microsoft\Python\Miniconda\Miniconda3-x64
cd fpga
make %1
