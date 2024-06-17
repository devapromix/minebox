unit uCraft;

interface

uses
  Classes;

type
  TItem = record
    ItemID: Integer;
    Count: Integer;
  end;

  TCraft = class
  private
    CraftList: TStringList;
    procedure LoadCraft;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DoCraft;
    procedure Load;
    procedure Save;
  end;

function AddItem(ItemID: Integer; Count: Integer = 1): Boolean;

var
  PP: array [0 .. 45] of TItem;
  MCD, RCD: TItem;
  PPM: Integer = 0;
  BRC: Integer = 0;

implementation

uses
  SysUtils,
  uVars,
  uGame,
  Utils;

procedure ClearItems;
var
  I: Integer;
begin
  MCD.ItemID := 0;
  MCD.Count := 0;
  RCD.ItemID := 0;
  RCD.Count := 0;
  for I := 0 to High(PP) do
  begin
    with PP[I] do
    begin
      ItemID := 0;
      Count := 0;
    end;
  end;
end;

function AddItem(ItemID: Integer; Count: Integer = 1): Boolean;
var
  I, J: Integer;

  procedure Add();
  begin
    Result := True;
    PP[I].ItemID := ItemID;
    PP[I].Count := PP[I].Count + Count;
    Game.Sound.Play('item_ec.wav');
  end;

begin
  if (Count < 1) or (Count > 9) then
    Count := 1;
  J := -1;
  Result := False;
  for I := 0 to 31 do
    if (PP[I].ItemID = ItemID) then
    begin
      J := I;
      Add();
      Break;
    end;
  if (J = -1) then
    for I := 0 to 31 do
      if (PP[I].ItemID = 0) then
      begin
        Add();
        Break;
      end;
end;

procedure TCraft.DoCraft;
var
  I, J, K, B: Integer;
  R, F, C: TExplodeResult;
begin
  RCD.Count := 0;
  RCD.ItemID := 0;
  for I := 0 to CraftList.Count - 1 do
  begin
    R := Explode('=', CraftList[I]);
    F := Explode(',', R[0]);
    C := Explode(',', R[1]);
    if (F[0][1] = '#') then
    begin
      Delete(F[0], 1, 1);
      B := 0;
      for J := 0 to High(F) do
      begin
        for K := 32 to 40 do
          if (PP[K].ItemID > 0) and (PP[K].ItemID = StrToInt(F[J])) then
          begin
            Inc(B);
            Break;
          end;
      end;
      J := 0;
      for K := 32 to 40 do
        if (PP[K].ItemID > 0) then
          Inc(J);
      if (B = High(F) + 1) and (J = High(F) + 1) then
      begin
        RCD.ItemID := StrToInt(C[0]);
        RCD.Count := StrToInt(C[1]);
        Exit;
      end;
    end
    else if (PP[32].ItemID = StrToInt(F[0])) and (PP[33].ItemID = StrToInt(F[1])
      ) and (PP[34].ItemID = StrToInt(F[2])) and (PP[35].ItemID = StrToInt(F[3])
      ) and (PP[36].ItemID = StrToInt(F[4])) and (PP[37].ItemID = StrToInt(F[5])
      ) and (PP[38].ItemID = StrToInt(F[6])) and (PP[39].ItemID = StrToInt(F[7])
      ) and (PP[40].ItemID = StrToInt(F[8])) then
    begin
      RCD.ItemID := StrToInt(C[0]);
      RCD.Count := StrToInt(C[1]);
      Exit;
    end;
  end;
end;

{ TCraft }

constructor TCraft.Create;
begin
  CraftList := TStringList.Create;
  LoadCraft;
end;

destructor TCraft.Destroy;
begin
  CraftList.Free;
  inherited;
end;

procedure TCraft.Load;
var
  I: Integer;
  T, K: TStringList;
begin
  ClearItems;
  if FileExists(SavePath + '$') and FileExists(SavePath + '$$') then
  begin
    T := TStringList.Create;
    K := TStringList.Create;
    try
      T.LoadFromFile(SavePath + '$');
      K.LoadFromFile(SavePath + '$$');
      for I := 0 to T.Count - 1 do
      begin
        PP[I].ItemID := StrToInt(T[I]);
        PP[I].Count := StrToInt(K[I]);
      end;
    finally
      T.Free;
      K.Free;
    end;
  end;
end;

procedure TCraft.Save;
var
  I: Integer;
  T, K: TStringList;
begin
  T := TStringList.Create;
  K := TStringList.Create;
  try
    for I := 0 to High(PP) do
      with PP[I] do
      begin
        T.Append(IntToStr(ItemID));
        K.Append(IntToStr(Count));
      end;
    T.SaveToFile(SavePath + '$');
    K.SaveToFile(SavePath + '$$');
  finally
    T.Free;
    K.Free;
  end;
end;

procedure TCraft.LoadCraft;
var
  I: Integer;
begin
  CraftList.LoadFromFile(DataPath + 'Craft.txt');
  for I := CraftList.Count - 1 downto 0 do
  begin
    CraftList[I] := Trim(CraftList[I]);
    if (Trim(CraftList[I]) = '') or (CraftList[I][1] = '-') then
      CraftList.Delete(I);
  end;
end;

end.
