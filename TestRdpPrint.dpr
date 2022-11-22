program TestRdpPrint;

{$APPTYPE CONSOLE}

uses
  SysUtils, Printers;

// this VCL type is defined in Printers.pas
type
  TPrinterDevice = class
    Driver, Device, Port: String;
  end;

var
  i: integer;
  device: TPrinterDevice;

begin
  try
    for i := 0 to Printer.Printers.Count - 1 do
    begin
      device := TPrinterDevice(Printer.Printers.Objects[i]);
      writeln(i, '. driver: ', device.driver);
      write('   device: ', device.device);
      if i = Printer.PrinterIndex then
        write(' *');
      writeln;
      writeln('   port: ', device.port);
    end;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
