setlocal
PATH=C:\cygwin64\bin;%PATH%
PATH=D:\LATICE\oss-cad-suite\bin;%PATH%
PATH=D:\LATICE\oss-cad-suite\lib;%PATH%
rem PATH=D:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\Extensions\Microsoft\Python\Miniconda\Miniconda3-x64;%PATH%
PATH=C:\Users\user\AppData\Local\Programs\Python\Python310;%PATH%
PATH=D:\LATICE\OpenOCD-20210729-0.11.0\bin;%PATH%
rem set PYTHONHOME=D:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\Extensions\Microsoft\Python\Miniconda\Miniconda3-x64
rem set PYTHONHOME=C:\Users\user\AppData\Local\Programs\Python\Python310
cd fpga
make %1
