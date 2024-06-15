unit Utils;

interface

uses Classes;

type
  TExplodeResult  = array of string;

function Clamp(Value, AMin, AMax: Integer; Flag: Boolean = True): Integer;
function GetStr(const Separator: Char; S: string; I: Integer): string;
function RandStr(const Separator: Char; S: string): string;
function ExplodeString(const Separator, Source: string): TStringlist;
function GetPath(SubDir: string = ''): string;
function BarWidth(CX, MX, WX: Integer): Integer;
function Percent(N, P: Integer): Integer;
procedure Box(); overload;
procedure Box(const S: string); overload;
procedure Box(const I: Integer); overload;
function Rand(A, B: Integer): Integer;
function GetDist(x1, y1, x2, y2: single): word;
function Explode(const StringSeparator: Char;
  Source: string): TExplodeResult;

implementation

uses Math, SysUtils, Dialogs;

function Clamp(Value, AMin, AMax: Integer; Flag: Boolean = True): Integer;
begin
  Result := Value;
  if (Result < AMin) then
    if Flag then
      Result := AMin
    else
      Result := AMax;
  if (Result > AMax) then
    if Flag then
      Result := AMax
    else
      Result := AMin;
end;

function ExplodeString(const Separator, Source: string): TStringlist;
begin
  Result := TStringlist.Create();
  Result.Text := StringReplace(Source, Separator, #13, [rfReplaceAll]);
end;

function GetStr(const Separator: Char; S: string; I: Integer): string;
var
  SL: TStringlist;
begin
  SL := ExplodeString(Separator, S);
  Result := Trim(SL[I]);
end;

function RandStr(const Separator: Char; S: string): string;
var
  SL: TStringlist;
begin
  SL := ExplodeString(Separator, S);
  Result := Trim(SL[Math.RandomRange(0, SL.Count)]);
end;

function GetPath(SubDir: string = ''): string;
begin
  Result := ExtractFilePath(ParamStr(0));
  Result := IncludeTrailingPathDelimiter(Result + SubDir);
end;

function BarWidth(CX, MX, WX: Integer): Integer;
begin
  Result := Round(CX / MX * WX);
end;

function Percent(N, P: Integer): Integer;
begin
  Result := N * P div 100;
end;

procedure Box(); overload;
begin
  ShowMessage('');
end;

procedure Box(const S: string); overload;
begin
  ShowMessage(S);
end;

procedure Box(const I: Integer); overload;
begin
  ShowMessage(Format('%d', [I]));
end;

function Rand(A, B: Integer): Integer;
begin
  Result := Round(Random(B - A + 1) + A);
end;

function GetDist(x1, y1, x2, y2: single): word;
begin
  result := round(sqrt(sqr(x2 - x1) + sqr(y2 - y1)));
end;

function Explode(const StringSeparator: Char;
  Source: string): TExplodeResult;
var
  I: Integer;
  S: string;
begin
  S := Source;
  SetLength(Result, 0);
  I := 0;
  while Pos(StringSeparator, S) > 0 do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[I] := Copy(S, 1, Pos(StringSeparator, S) - 1);
    Inc(I);
    S := Copy(S, Pos(StringSeparator, S) + Length(StringSeparator), Length(S));
  end;
  SetLength(Result, Length(Result) + 1);
  Result[I] := Copy(S, 1, Length(S));
end;

end.
