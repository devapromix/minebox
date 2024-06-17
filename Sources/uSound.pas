unit uSound;

interface

uses
  Bass;

type
  TChannelType = (ctUnknown, ctStream, ctMusic);

  TSound = class(TObject)
  private
    FChannelID: Byte;
    FChannel: array [0 .. 15] of DWORD;
    FChannelType: TChannelType;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Play(FileName: String);
  end;

implementation

uses
  uVars;

constructor TSound.Create;
var
  BassInfo: BASS_INFO;
begin
  FChannelID := 0;
  BASS_Init(1, 44100, BASS_DEVICE_3D, 0, nil);
  BASS_Start;
  BASS_GetInfo(BassInfo);
end;

destructor TSound.Destroy;
var
  I: Byte;
begin
  for I := 0 to High(FChannel) do
    BASS_ChannelStop(FChannel[I]);
  inherited;
end;

procedure TSound.Play(FileName: String);
begin
  if not IsGameSound then
    Exit;
  FChannel[FChannelID] := BASS_StreamCreateFile(False,
    PChar(SoundPath + FileName), 0, 0, 0);
  if (FChannel[FChannelID] <> 0) then
  begin
    FChannelType := ctStream;
    BASS_ChannelPlay(FChannel[FChannelID], False);
  end;
  Inc(FChannelID);
  if (FChannelID > High(FChannel)) then
    FChannelID := 0;
end;

end.
