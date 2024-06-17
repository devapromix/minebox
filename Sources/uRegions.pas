unit uRegions;

interface

uses
  Types,
  uVars;

type
  TCell = record
    Block: Char;
    BlockID: Integer;
    Move: Boolean;
  end;

type
  TRegion = class
  private
    FX, FY: Integer;
    function FileName: string;
    procedure Load;
    procedure Gen;
  public
    Map: array [0 .. ScreenWidth - 1, 0 .. ScreenHeight - 1, 0 .. 2] of TCell;
    constructor Create(AX, AY: Integer);
    destructor Destroy; override;
    procedure Assign(AX, AY: Integer);
    procedure Save;
  end;

procedure CreateRegions;
procedure SaveRegions;

var
  RMap: array [0 .. (ScreenWidth * 3) - 1, 0 .. (ScreenHeight * 3) - 1,
    0 .. 2] of TCell;
  Region: array [1 .. 9] of TRegion;
  RegionPoint: TPoint;
  BaseLine: Integer = 0;
  Density: Integer = 0;
  Deep: Integer = 0;

implementation

uses
  Classes,
  SysUtils,
  Dialogs,
  uGame,
  Utils;

var
  PG: Integer = 0;
  PL: Integer = 0;
  PR: Integer = 0;
  PP: Integer = 0;

  { TRegion }

procedure TRegion.Assign(AX, AY: Integer);
var
  X, Y, Z: Integer;
begin
  for Y := 0 to ScreenHeight - 1 do
    for X := 0 to ScreenWidth - 1 do
      for Z := 0 to 2 do
        RMap[X + (AX * ScreenWidth)][Y + (AY * ScreenHeight)][Z] :=
          Map[X][Y][Z];
end;

constructor TRegion.Create(AX, AY: Integer);
begin
  FX := AX;
  FY := AY;
  if (FileExists(FileName)) then
    Load
  else
    Gen;
end;

destructor TRegion.Destroy;
begin

  inherited;
end;

function TRegion.FileName: string;
begin
  Result := SavePath + Format('%d~%d', [FX, FY])
end;

procedure TRegion.Gen;
var
  Block, DeepBlock, C, D, W, X, Y: Integer;
  B, F, K: Boolean;

  procedure AddCell(X, Y, Z, BlockID: Integer);
  begin
    if (BlockID = bLeaves) then
    begin
      if (Ord(Map[X][Y][Z].Block) = bWood + BS) then
        Exit;
      if (Rand(1, 999) <= 5) then
        Map[X][Y][2].Block := Chr(bNet + BS)
    end;
    Map[X][Y][Z].Block := Chr(BlockID + BS)
  end;

  procedure AddLeaves(X, Y: Integer);
  begin
    if (Rand(1, 9) > 1) then
      AddCell(X, Y, 0, bLeaves);
    AddCell(X, Y, 1, bLeaves);
    if (Rand(1, 9) > 1) and (Map[X][Y][2].BlockID = 0) then
      AddCell(X, Y, 2, bLeaves);
  end;

  procedure AddSpot(X, Y, BlockID: Integer);
  var
    FX, FY: Integer;
  begin
    if (X < 2) or (X > ScreenWidth - 3) or (Y < 2) or (Y > ScreenHeight - 3) or
      (BaseLine < 1) then
      Exit;
    for FX := 0 to 4 do
      for FY := 0 to 4 do
      begin
        case Rand(1, 9) of
          1:
            Map[X + (FX - 2)][Y + (FY - 2)][1].Block := Chr(BlockID + BS);
          2, 3:
            Map[X + (FX - 2)][Y + (FY - 2)][0].Block := Chr(BlockID + BS);
        end;
      end;
  end;

begin
  PP := 0;
  PG := HalfScreenHeight;
  PR := 0;
  PL := 0;
  if (Density = 0) then
    Density := Rand(1, 100);
  if (Rand(1, 2) = 1) then
    Inc(Density, 10)
  else
    Dec(Density, 10);
  if (Density > 100) then
    Density := 100;
  if (Density < 1) then
    Density := 1;

  // Density := 100;

  for X := 0 to ScreenWidth - 1 do
  begin
    B := True;
    F := False;
    K := False;
    for Y := 0 to ScreenHeight - 1 do
    begin
      Block := bBase;
      DeepBlock := bBase;
      case BaseLine of
        - 1000 .. -1: // Sky
          begin
            Block := bSky;
            DeepBlock := bSky;
          end;
        0: // Ground
          begin
            Block := bSky;
            DeepBlock := bSky;
            //
            if (Rand(1, Density) = 1) and B then
            begin
              if (X + PG + 1 > ScreenHeight) and (PG <> ScreenHeight div 2) then
                if (PG > ScreenHeight div 2) then
                  Dec(PG)
                else
                  Inc(PG)
              else if (Rand(1, 3) = 1) then
                Inc(PG)
              else
                Dec(PG);
              B := False;
            end;
            if (PG < 1) then
              PG := 1;
            if (PG > 19) then
              PG := 19;
            if (Rand(1, 2) = 1) then
              if (Rand(1, 2) = 1) then
                Inc(PP)
              else
                Dec(PP);
            if (PP <= PG) then
              PP := PG + 5;
            if (PP < 10) then
              PP := 10;
            if (PP > 20) then
              PP := 20;
            //
            if (Y > PG) then
            begin
              if (Density <= 80) then
              begin
                Block := bDirt;
                DeepBlock := bDirt;
              end
              else
              begin
                Block := bSand;
                DeepBlock := bSand;
              end;
              if F then
                Block := bGravel;
              if (Rand(1, 7) = 1) then
                F := not F;
              if K then
                DeepBlock := bGravel;
              if (Rand(1, 7) = 1) then
                K := not K;
              if Odd(X) then
            end;
            if (Y > PP) then
            begin
              Block := bStone;
              DeepBlock := bStone;
            end;
          end;
        1 .. 1000: // Underworld
          begin
            Block := bStone;
            DeepBlock := bStone;
            case Rand(0, 555) of
              0 .. 9:
                AddSpot(X, Y, bCoal);
            end;
            if (BaseLine > 1) then
              case Rand(0, 999) of
                0 .. 2:
                  AddSpot(X, Y, bIronOre);
              end;
          end;
      end;
      Map[X][Y][0].Block := Chr(DeepBlock + BS);
      Map[X][Y][1].Block := Chr(Block + BS);
      Map[X][Y][2].Block := Chr(BS);
      if (RegionPoint.X > 0) then
        PR := PG
      else
        PL := PG;
    end;
  end;
  // Add cactus
  if (BaseLine = 0) then
    for X := 1 to ScreenWidth - 2 do
      for Y := 1 to ScreenHeight - 2 do
        if (Ord(Map[X][Y][1].Block) = bSand + BS) and
          (Ord(Map[X][Y - 1][1].Block) = bSky + BS) and (Rand(0, 24) = 0) then
        begin
          C := Rand(1, 3);
          for D := Y - 1 downto Y - C - 1 do
            Map[X][D][1].Block := Chr(bCactus + BS);
          Break;
        end;
  // Add grass
  if (BaseLine = 0) then
    for X := 0 to ScreenWidth - 1 do
      for Y := 0 to ScreenHeight - 1 do
        if (Ord(Map[X][Y][1].Block) = bDirt + BS) then
        begin
          Map[X][Y][0].Block := Chr(bGrass + BS);
          Map[X][Y][1].Block := Chr(bGrass + BS);
          Break;
        end;
  // Add pumpkins
  if (BaseLine = 0) and (Density <= 10) then
    for X := 1 to ScreenWidth - 2 do
      for Y := 1 to ScreenHeight - 2 do
        if (Ord(Map[X][Y][1].Block) = bGrass + BS) and
          (Ord(Map[X][Y - 1][1].Block) = bSky + BS) and (Rand(0, 49) = 0) then
        begin
          Map[X][Y - 1][1].Block := Chr(bPumpkin + BS);
          Break;
        end;
  // Add watermelon
  if (BaseLine = 0) and (Density >= 70) and (Density <= 80) then
    for X := 1 to ScreenWidth - 2 do
      for Y := 1 to ScreenHeight - 2 do
        if (Ord(Map[X][Y][1].Block) = bGrass + BS) and
          (Ord(Map[X][Y - 1][1].Block) = bSky + BS) and (Rand(0, 49) = 0) then
        begin
          Map[X][Y - 1][1].Block := Chr(bWaterMelon + BS);
          Break;
        end;
  // Plants
  if (BaseLine = 0) then
    for X := 1 to ScreenWidth - 2 do
      for Y := 1 to ScreenHeight - 2 do
        if (Ord(Map[X][Y][1].Block) = bGrass + BS) and
          (Ord(Map[X][Y - 1][1].Block) = bSky + BS) and (Rand(0, 49) = 0) then
        begin
          case Rand(1, 2) of
            1:
              AddCell(X, Y - 1, 2, bRose);
            2:
              AddCell(X, Y - 1, 2, bDandelion);
          end;
          Break;
        end;
  // Add papirus
  if (BaseLine = 0) and (Density >= 70) and (Density <= 80) then
    for X := 1 to ScreenWidth - 2 do
      for Y := 1 to ScreenHeight - 2 do
        if (Rand(0, 49) = 0) and (Ord(Map[X][Y][1].Block) = bGrass + BS) and
          (Ord(Map[X][Y - 1][1].Block) = bSky + BS) then
        begin
          C := Rand(1, 3);
          for D := Y - 1 downto Y - C - 1 do
            if (Map[X][D][1].Block = Chr(bSky + BS)) then
              Map[X][D][2].Block := Chr(bPapirus + BS)
            else
              Break;
          Break;
        end;
  // Add tree
  if (BaseLine = 0) and (Density >= 20) and (Density <= 60) then
    for X := 5 to ScreenWidth - 6 do
      for Y := 5 to ScreenHeight - 6 do
        if (Rand(1, 2) = 1) and (Ord(Map[X][Y][1].Block) = bGrass + BS) then
          if (Ord(Map[X + 1, Y - 1][1].Block) = bSky + BS) and
            (Ord(Map[X - 1][Y - 1][1].Block) = bSky + BS) then
          begin
            W := 1;
            C := Rand(5, 9);
            if (Y - C - 1 <= 0) then
              Continue;
            for D := Y - 1 downto Y - C do
              AddCell(X, D, 1, bWood);
            AddLeaves(X, Y - C - 1);
            if (Rand(1, 2) = 1) then
              AddLeaves(X, Y - C - 2);
            for D := Y - Rand(3, 4) downto Y - C - 1 do
            begin
              AddLeaves(X - W, D);
              AddLeaves(X + W, D);
              AddCell(X, D, 0, bLeaves);
              AddCell(X, D, 2, bLeaves);
            end;
            B := False;
            if (Rand(1, 2) = 1) then
              for D := Y - Rand(2, 3) downto Y - C do
              begin
                W := 2;
                AddLeaves(X - W, D);
                AddLeaves(X + W, D);
                B := True;
              end;
            if B and (Rand(1, 2) = 1) then
              for D := Y - Rand(2, 3) downto Y - C do
              begin
                W := 3;
                AddLeaves(X - W, D);
                AddLeaves(X + W, D);
              end;
            // Add mushroom
            if (Rand(1, 5) = 1) then
            begin
              W := Rand(1, W);
              if (Rand(1, 2) = 1) then
                W := -W;
              if (Ord(Map[X + W, Y - 1][1].Block) = bSky + BS) and
                (Ord(Map[X + W, Y][1].Block) = bGrass + BS) then
                case Rand(1, 2) of
                  1:
                    AddCell(X + W, Y - 1, 2, bMushroom1);
                  2:
                    AddCell(X + W, Y - 1, 2, bMushroom2);
                end;
            end;
            Break;
          end;
  Save;
end;

procedure TRegion.Load;
var
  F: TStringList;
  X, Y, Z: Integer;
begin
  F := TStringList.Create;
  try
    F.LoadFromFile(FileName);
    for Y := 0 to ScreenHeight - 1 do
    begin
      Z := 0;
      for X := 0 to (ScreenWidth * 3) - 1 do
      begin
        Map[X div 3][Y][Z].Block := F[Y][X + 1];
        Inc(Z);
        if (Z > 2) then
          Z := 0;
      end;
    end;
  finally
    F.Free;
  end;
end;

procedure TRegion.Save;
var
  F: TStringList;
  X, Y, Z: Integer;
  S: string;
begin
  F := TStringList.Create;
  try
    F.Clear;
    for Y := 0 to ScreenHeight - 1 do
    begin
      S := '';
      for X := 0 to ScreenWidth - 1 do
        for Z := 0 to 2 do
          S := S + Map[X][Y][Z].Block;
      F.Append(S);
    end;
    F.SaveToFile(FileName);
  finally
    F.Free;
  end;
end;

procedure DestroyRegions;
var
  I: Integer;
begin
  for I := 1 to 9 do
    Region[I].Free;
end;

procedure CreateRegions;
var
  I, X, Y: Integer;
begin
  DestroyRegions;

  X := 0;
  Y := 0;
  for I := 1 to 9 do
  begin
    BaseLine := RegionPoint.Y + Y - 1;
    Region[I] := TRegion.Create(RegionPoint.X + X - 1, RegionPoint.Y + Y - 1);
    Region[I].Assign(X, Y);
    Inc(X);
    if (X > 2) then
    begin
      X := 0;
      Inc(Y);
    end;
  end;
  //
end;

procedure SaveRegions;
var
  F: TStringList;
  X, Y: Integer;

  procedure SaveRegion(AX, AY: Integer);
  var
    X, Y, Z: Integer;
    S: string;
    C: Char;
  begin

    F.Clear;
    for Y := 0 to ScreenHeight * 3 - 1 do
    begin
      S := '';
      for X := 0 to ScreenWidth * 3 - 1 do
        S := S + RMap[X][Y][1].Block;
      F.Append(S);
    end;
    F.SaveToFile(SavePath + '#');

    F.Clear;
    for Y := ScreenHeight * AY to (ScreenHeight * (AY + 1)) - 1 do
    begin
      S := '';
      for X := ScreenWidth * AX to (ScreenWidth * (AX + 1)) - 1 do
        for Z := 0 to 2 do
        begin
          C := RMap[X][Y][Z].Block;
          if (Ord(C) < BS) then
            C := Chr(bSky + BS);
          S := S + C;
        end;
      F.Append(S);
    end;
    F.SaveToFile(SavePath + Format('%d~%d', [RegionPoint.X + AX - 1,
      RegionPoint.Y + AY - 1]));

    // ShowMessage(IntToStr(RegionPoint.X + AX - 1) + '~'
    // + IntToStr(RegionPoint.Y + AY - 1) + ':' + #13 + F.Text);

  end;

begin
  F := TStringList.Create;
  try
    for Y := 0 to 2 do
      for X := 0 to 2 do
        SaveRegion(X, Y);
  finally
    F.Free;
  end;
end;

initialization

RegionPoint.X := 0;
RegionPoint.Y := 0;

finalization

DestroyRegions;

end.
