@echo lang fix en_US >lang.inc
@fasm.exe -m 16384 opendial.asm opendial
@erase lang.inc
@kpack opendial
@pause
