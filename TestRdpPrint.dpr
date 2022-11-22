program TestRdpPrint;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows, WinSpool,
  Classes,
  Printers;

function GetDefaultPrinter(pszBuffer: PChar; var pcchBuffer : DWORD) : bool; stdcall; external 'winspool.drv' name 'GetDefaultPrinterA';

var
  sDefault : array[0..255] of char;
  iDefault : dword;
  i : integer;

begin
  iDefault := 256;
  FillChar(sDefault, iDefault, 0);
  GetDefaultPrinter(@sDefault[0], iDefault);
  writeln(sDefault);
  writeln;

  try
    for i := 0 to Printer.Printers.Count - 1 do
    begin
      write(i, '. ', Printer.Printers[i]);
      if i = Printer.PrinterIndex then
        write(' *');
      writeln;
    end;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
