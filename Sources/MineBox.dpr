program MineBox;

uses
  Windows,
  Forms,
  uMain in 'uMain.pas' {fMain},
  Player in 'Player.pas',
  uGraphics in 'uGraphics.pas',
  uVars in 'uVars.pas',
  uRegions in 'uRegions.pas',
  uGame in 'uGame.pas',
  uCraft in 'uCraft.pas',
  uSplah in 'uSplah.pas' {fSplash},
  uGraphUtils in 'uGraphUtils.pas',
  uSound in 'uSound.pas',
  Bass in 'Bass.pas',
  Stages in 'Stages.pas',
  Utils in 'Utils.pas';

{$R *.res}

var
  UniqueMapping: THandle;

begin
  UniqueMapping := CreateFileMapping($ffffffff,
    nil, PAGE_READONLY, 0, 32,'MineBox');
  if UniqueMapping = 0 then Halt else
  if GetLastError = ERROR_ALREADY_EXISTS then Halt;
  Application.Initialize;
  Application.Title := 'MineBox';
  fSplash := TfSplash.Create(Application);
  fSplash.Show;
  fSplash.Update;
  while fSplash.Timer1.Enabled do
    Application.ProcessMessages;
  Application.CreateForm(TfMain, fMain);
  fSplash.Hide;
  fSplash.Free;
  Application.Run;
end.
