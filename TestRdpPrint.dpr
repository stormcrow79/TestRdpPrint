program TestRdpPrint;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows, WinSpool,
  Classes,
  Printers;

const
  SDeviceOnPort = '%s on %s';

// this VCL type is defined in Printers.pas
type
  TPrinterDevice = class
    Driver, Device, Port: String;
    constructor Create(ADriver, ADevice, APort: PChar);
    function IsEqual(ADriver, ADevice, APort: PChar): Boolean;
  end;

constructor TPrinterDevice.Create(ADriver, ADevice, APort: PChar);
begin
  inherited Create;
  Driver := ADriver;
  Device := ADevice;
  Port := APort;
end;

function TPrinterDevice.IsEqual(ADriver, ADevice, APort: PChar): Boolean;
begin
  Result := (Device = ADevice) and ((Port = '') or (Port = APort));
end;

function FetchStr(var Str: PChar): PChar;
var
  P: PChar;
begin
  Result := Str;
  if Str = nil then Exit;
  P := Str;
  while P^ = ' ' do Inc(P);
  Result := P;
  while (P^ <> #0) and (P^ <> ',') do Inc(P);
  if P^ = ',' then
  begin
    P^ := #0;
    Inc(P);
  end;
  Str := P;
end;

var
  i: integer;
  device: TPrinterDevice;
  FPrinters: TStrings;

function GetPrinters: TStrings;
var
  LineCur, Port: PChar;
  Buffer, PrinterInfo: PChar;
  Flags, Count, NumInfo: DWORD;
  I: Integer;
  Level: Byte;
begin
  FPrinters := TStringList.Create;
  Result := FPrinters;
  try
    if Win32Platform = VER_PLATFORM_WIN32_NT then
    begin
      Flags := PRINTER_ENUM_CONNECTIONS or PRINTER_ENUM_LOCAL;
      Level := 4;
    end
    else
    begin
      Flags := PRINTER_ENUM_LOCAL;
      Level := 5;
    end;
    Count := 0;
    EnumPrinters(Flags, nil, Level, nil, 0, Count, NumInfo);
    if Count = 0 then Exit;
    GetMem(Buffer, Count);
    try
      if not EnumPrinters(Flags, nil, Level, PByte(Buffer), Count, Count, NumInfo) then
        Exit;
      PrinterInfo := Buffer;
      for I := 0 to NumInfo - 1 do
      begin
        if Level = 4 then
          with PPrinterInfo4(PrinterInfo)^ do
          begin
            FPrinters.AddObject(pPrinterName,
              TPrinterDevice.Create(nil, pPrinterName, nil));
            Inc(PrinterInfo, sizeof(TPrinterInfo4));
          end
        else
          with PPrinterInfo5(PrinterInfo)^ do
          begin
            LineCur := pPortName;
            Port := FetchStr(LineCur);
            while Port^ <> #0 do
            begin
              FPrinters.AddObject(Format(SDeviceOnPort, [pPrinterName, Port]),
                TPrinterDevice.Create(nil, pPrinterName, Port));
              Port := FetchStr(LineCur);
            end;
            Inc(PrinterInfo, sizeof(TPrinterInfo5));
          end;
      end;
    finally
      FreeMem(Buffer, Count);
    end;
  except
    FPrinters.Free;
    FPrinters := nil;
    raise;
  end;
end;

procedure SetToDefaultPrinter;
var
  I: Integer;
  ByteCnt, StructCnt: DWORD;
  DefaultPrinter: array[0..1023] of Char;
  Cur, Device: PChar;
  PrinterInfo: PPrinterInfo5;
  Printers: TStrings;
begin
  ByteCnt := 0;
  StructCnt := 0;
  if not EnumPrinters(PRINTER_ENUM_DEFAULT, nil, 5, nil, 0, ByteCnt,
    StructCnt) and (GetLastError <> ERROR_INSUFFICIENT_BUFFER) then
  begin
    // With no printers installed, Win95/98 fails above with "Invalid filename".
    // NT succeeds and returns a StructCnt of zero.
    if GetLastError = ERROR_INVALID_NAME then
      raise exception.create('no default printer') //RaiseError(SNoDefaultPrinter)
    else
      raise exception.create('windows error'); //RaiseLastOSError;
  end;
  PrinterInfo := AllocMem(ByteCnt);
  try
    EnumPrinters(PRINTER_ENUM_DEFAULT, nil, 5, PrinterInfo, ByteCnt, ByteCnt,
      StructCnt);
    if StructCnt > 0 then
      Device := PrinterInfo.pPrinterName
    else begin
      GetProfileString('windows', 'device', '', DefaultPrinter,
        SizeOf(DefaultPrinter) - 1);
      Cur := DefaultPrinter;
      Device := FetchStr(Cur);
    end;
    Printers := GetPrinters;
    with Printers do
      for I := 0 to Count-1 do
      begin
        if AnsiSameText(TPrinterDevice(Objects[I]).Device, Device) then
        begin
          with TPrinterDevice(Objects[I]) do
          begin
            writeln('matched printer');
            writeln('  Device: ', PChar(Device));
            writeln('  Driver: ', PChar(Driver));
            writeln('  Port: ', PChar(Port));
            //SetPrinter(PChar(Device), PChar(Driver), PChar(Port), 0);

          end;
          Exit;
        end;
      end;
  finally
    FreeMem(PrinterInfo);
  end;
  raise exception.Create('no default printer');//raiserrror(SNoDefaultPrinter);
end;

begin
  try
    for i := 0 to Printer.Printers.Count - 1 do
    begin
      device := TPrinterDevice(Printer.Printers.Objects[i]);
      write('   device: ', device.device);
      if i = Printer.PrinterIndex then
        write(' *');
      writeln;
      writeln(i, '. driver: ', device.driver);
      writeln('   port: ', device.port);
    end;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
