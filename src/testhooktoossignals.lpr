program TestHookToOSSignals;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  BaseUnix,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  Classes, SysUtils, CustApp;

type

{ THookToOSSignals }
  THookToOSSignals = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

var
  Application: THookToOSSignals;

{ Signal Handling }
{$IFDEF UNIX}
procedure SignalHandler(signal: longint; info: psiginfo; context: psigcontext); cdecl;
begin
  case signal of
    SIGTERM, SIGINT:
      begin
        if signal = SIGINT then WriteLn;
        WriteLn('Received termination signal.');
        if Assigned(Application) then
          Application.Terminate;
      end;
    SIGHUP:
      begin
        //WriteLn('Received SIGHUP - could implement config reload here');
        // Could implement configuration reload here
      end;
  end;
end;

procedure SetupSignalHandlers;
var
  act: SigActionRec;
begin
  FillChar(act, SizeOf(act), 0);
  act.sa_handler:= @SignalHandler;
  act.sa_flags:= 0;

  // Set up signal handlers
  fpSigAction(SIGTERM, @act, nil);
  fpSigAction(SIGINT, @act, nil);
  fpSigAction(SIGHUP, @act, nil);
end;
{$ENDIF}

{$IFDEF WINDOWS}
function ConsoleCtrlHandler(CtrlType: DWORD): BOOL; stdcall;
begin
  case CtrlType of
    CTRL_C_EVENT, CTRL_BREAK_EVENT, CTRL_CLOSE_EVENT:
      begin
        WriteLn('Received termination signal.');
        if Assigned(Application) then
          Application.Terminate;
        Result := True;
        Exit;
      end;
  end;
  Result := False;
end;

procedure SetupSignalHandlers;
begin
  SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);
end;
{$ENDIF}

{ THookToOSSignals }

procedure THookToOSSignals.DoRun;
var
  ErrorMsg: String;
begin
  // Signal Handling
  SetupSignalHandlers;
  // quick check parameters
  ErrorMsg:=CheckOptions('h', 'help');
  if ErrorMsg<>'' then begin
    //ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  WriteLn('This application demonstrates hooking to OS signals.');
  WriteLn('Use CTRL-C or a kill signal to terminate the application.');
  { Infinite loop waiting for a termination signal }
  while not Terminated do
  begin
    Sleep(1);
  end;
end;

constructor THookToOSSignals.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor THookToOSSignals.Destroy;
begin
  inherited Destroy;
end;

procedure THookToOSSignals.WriteHelp;
begin
  { add your help code here }
  WriteLn('This application demonstrates hooking to OS signals.');
  WriteLn('Usage: ', ExeName, ' -h');
end;

begin
  Application:=THookToOSSignals.Create(nil);
  Application.Title:='Hook To OS Signals';
  Application.Run;
  Application.Free;
end.

