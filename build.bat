@echo off

WHERE wla-6502.exe
IF %ERRORLEVEL% NEQ 0 (
	ECHO wla-6502.exe needs to be added to the PATH.
	goto :end
)

IF EXIST "main.obj" (
	del main.obj
)
wla-6502.exe -o main.obj main.s 

IF %ERRORLEVEL% NEQ 0 (
	ECHO build failed
	goto :end
)

WHERE wlalink.exe
IF %ERRORLEVEL% NEQ 0 (
	ECHO wlalink.exe needs to be added to the PATH.
	goto :end
)

IF EXIST "out.nes" (
	del out.nes
)

wlalink.exe -r linkfile out.nes

IF %ERRORLEVEL% NEQ 0 (
	ECHO linking failed.
	goto :end
)

:end