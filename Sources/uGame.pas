unit uGame;

interface

uses Classes, Types, Stages, Player, uGraphics, uRegions, uCraft, uSound;

type
  TGame = class
  private
    FStages: TStages;
    FPanel: TPanel;
    FInvPanel: TInvPanel;
    procedure LoadBlocks;
  public
    Pos: TPoint;
    MousePos: TPoint;
    Player: TPlayer;
    Graphic: TGraphic;
    Craft: TCraft;
    Sound: TSound;
    PutList: TStringList;
    TakeList: TStringList;
    function IsDist: Boolean;
    function GetDurability(BlockID: Integer): Integer;
    function GetFootCellID: Integer;
    function GetCell(AX, AY, AZ: Integer): TCell;
    function GetMoveCell(BlockID: Integer): Boolean;
    procedure SetCell(AX, AY, AZ, BlockID: Integer);
    procedure PutBlock(AX, AY, AZ: Integer);
    procedure FallBlock(AX, AY, AZ: Integer);
    procedure TakeBlock(AX, AY, AZ: Integer);
    procedure Move(AX, AY: Integer);
    procedure BlockSound(BlockID: Integer);
    procedure Load;
    procedure Save;
    constructor Create;
    destructor Destroy; override;
    property Stages: TStages read FStages write FStages;
    property Panel: TPanel read FPanel;
    property InvPanel: TInvPanel read FInvPanel;
  end;

var
  Game: TGame;

implementation

uses SysUtils, uVars, Utils;

{ TGame }

constructor TGame.Create;
begin
  FStages := TStages.Create;
  ForceDirectories(Path + '\Save');
  PutList := TStringList.Create;
  TakeList := TStringList.Create;
  LoadBlocks;
  Player := TPlayer.Create;
  Graphic := TGraphic.Create;
  Craft := TCraft.Create;
  Sound := TSound.Create;
  FPanel := TPanel.Create;
  FInvPanel := TInvPanel.Create;
  Pos := Point(0, 0);
  Load;
end;

destructor TGame.Destroy;
begin
  Save;
  FStages.Free;
  FPanel.Free;
  FInvPanel.Free;
  PutList.Free;
  TakeList.Free;
  Craft.Free;
  Graphic.Free;
  Player.Free;
  Sound.Free;
  inherited;
end;

procedure TGame.Move(AX, AY: Integer);

  function AdvMove(AX: Integer): Boolean;
  var
    C: Integer;
  begin
    Result := False;
    with Player do
    begin
      Move;
      if (GetCell(HalfScreenWidth - 1 + AX, HalfScreenHeight, 1).Move = False)
        and (GetCell(HalfScreenWidth - 1 + AX, HalfScreenHeight + 1, 1).Move = False)
        then begin
            Result := True;
            Exit
          end else if (GetCell(HalfScreenWidth - 1 + AX, HalfScreenHeight + 1, 1).Move = False)
          and (GetCell(HalfScreenWidth - 1 + AX, HalfScreenHeight, 1).Move = True)
            then begin
              Self.Pos.X := Self.Pos.X + AX;
              AY := -1;
            end else
            begin
              for C := HalfScreenHeight + 3 to ScreenHeight - 1 do
              if (GetCell(HalfScreenWidth - 1 + AX, C, 1).Move = False) then Break;
              if (GetCell(HalfScreenWidth - 1 + AX, HalfScreenHeight + 2, 1).Move = True)
                and (GetCell(HalfScreenWidth - 1 + AX, C, 1).Move = False) then
                begin
                  Self.Pos.X := Self.Pos.X + AX;
                  AY := C - (HalfScreenHeight + 2);
                end else Self.Pos.X := Self.Pos.X + AX;
            end;
    end;
  end;

begin
  case AX of
    -1: with Player do
        begin
          if MoveToRight then
          begin
            MoveToRight := False;
            Exit;
          end;
          //
          if AdvMove(-1) then Exit;
        end;
     1: with Player do
        begin
          if not MoveToRight then
          begin
            MoveToRight := True;
            Exit;
          end;
          if AdvMove(1) then Exit;
        end;
  end;
  Player.Move(0, AY);
  Self.Pos.X := Self.Pos.X + AX;
  Self.Pos.Y := Self.Pos.Y + AY;
  case GetFootCellID of
    bSky, bBase, bLeaves: Exit;
    bGrass, bDirt:
      Sound.Play('grass_footstep.wav');
    bSand, bGravel:
      Sound.Play('gravel_footstep.wav');
    bStone, bCStone, bCoal, bIronOre:
      Sound.Play('hard_footstep.wav');
    bWood, bLadder, bBoard:
      Sound.Play('wood_footstep.wav');
    else
      Sound.Play('default_footstep.wav');
  end;
end;

function TGame.GetCell(AX, AY, AZ: Integer): TCell;
begin
  Result.Block := RMap[Self.Pos.X + ScreenWidth + AX, Self.Pos.Y + ScreenHeight + AY, AZ].Block;
  Result.BlockID := Ord(Result.Block) - BS;
  Result.Move := GetMoveCell(Result.BlockID);
end;

procedure TGame.SetCell(AX, AY, AZ, BlockID: Integer);
begin
  RMap[Self.Pos.X + ScreenWidth + AX, Self.Pos.Y + ScreenHeight + AY, AZ].Block := Chr(BlockID + BS);
  if (GetCell(AX, AY + 1, AZ).BlockID = bGrass) then SetCell(AX, AY + 1, AZ, bDirt);
end;

function TGame.GetMoveCell(BlockID: Integer): Boolean;
begin
  case BlockID of
      bSky, bWood, bLeaves, bCactus, bPumpkin, bPapirus,
      bMushroom1, bMushroom2, bLadder, bRose, bDandelion, bTorch,
      bOpenDoor1, bOpenDoor2, bNet, bWaterMelon
       : Result := True;
     else Result := False;
  end;
end;

function TGame.GetDurability(BlockID: Integer): Integer;
begin
  Result := 0;
  case BlockID of
    bDirt, bGrass, bSand, bGravel:
    begin
      Result := 10;
      case PP[PPM].ItemID of
        iShovelWood : Result := Result + 10;
        iShovelStone: Result := Result + 20;
        iShovelIron : Result := Result + 30;
      end;
    end;
    bWood, bBoard, bLadder:
    begin
      Result := 6;
      case PP[PPM].ItemID of
        iAxeWood : Result := Result + 10;
        iAxeStone: Result := Result + 20;
        iAxeIron : Result := Result + 30;
      end;
    end;
    bCoal, bIronOre, bStone, bCStone:
    begin
      case BlockID of
        bStone, bCStone:
          Result := 3;
        bCoal, bIronOre:
          Result := 1;
      end;
      case PP[PPM].ItemID of
        iPickaxWood : Result := Result + 10;
        iPickaxStone: Result := Result + 20;
        iPickaxIron : Result := Result + 30;
      end;
    end else Result := 0;
  end;
  if (Result > 40) then Result := 40;
  if (Result < 0) then Result := 0;
end;

procedure TGame.PutBlock(AX, AY, AZ: Integer);
var
  I: Integer;
  R: TExplodeResult;

  procedure Put();
  begin
    with PP[PPM] do
    begin
      Count := Count - 1;
      if (Count <= 0) then ItemID := 0;
    end;
    Sound.Play('place_node.wav');
    FallBlock(AX, AY, AZ);
    Graphic.DrawGame;
  end;

begin
  if not IsDist then Exit;
  // Close door
  if (GetCell(AX, AY, AZ).BlockID = bOpenDoor1) then
  begin
    case Rand(1, 2) of
      1: Sound.Play('close_door_1.wav');
      2: Sound.Play('close_door_2.wav');
    end;
    SetCell(AX, AY, AZ, bDoor1);
    SetCell(AX, AY + 1, AZ, bDoor2);
    Graphic.DrawGame;
    Exit;
  end;
  // Open door
  if (GetCell(AX, AY, AZ).BlockID = bDoor1) then
  begin
    case Rand(1, 2) of
      1: Sound.Play('open_door_1.wav');
      2: Sound.Play('open_door_2.wav');
    end;
    SetCell(AX, AY, AZ, bOpenDoor1);
    SetCell(AX, AY + 1, AZ, bOpenDoor2);
    Graphic.DrawGame;
    Exit;
  end;
  // Put block
  if (PP[PPM].Count > 0)
    and (GetCell(AX, AY, AZ).BlockID = bSky) then
  begin
    for I := 0 to PutList.Count - 1 do
    begin
      R := Explode('>', PutList[I]);
      if (PP[PPM].ItemID = StrToInt(R[0])) then
        begin
          SetCell(AX, AY, AZ, StrToInt(R[1]));
          Put();
          Exit;;
        end;
    end;
    //
    case PP[PPM].ItemID of
      iDoor      : if (GetCell(AX, AY, AZ).BlockID = bSky) and
                     (GetCell(AX, AY + 1, AZ).BlockID = bSky) then
                   begin
                     SetCell(AX, AY, AZ, bDoor1);
                     SetCell(AX, AY + 1, AZ, bDoor2);
                   end else Exit;
      else Exit;
    end;
    Put();
  end;
end;

procedure TGame.FallBlock(AX, AY, AZ: Integer);
begin

end;

procedure TGame.TakeBlock(AX, AY, AZ: Integer);
var
  I: Integer;
  R: TExplodeResult;
begin
  if not IsDist then Exit;
  for I := 0 to TakeList.Count - 1 do
  begin
    R := Explode('<', TakeList[I]);
    if (GetCell(AX, AY, AZ).BlockID = StrToInt(R[1])) then
      begin
        if not AddItem(StrToInt(R[0])) then Exit;
        SetCell(AX, AY, AZ, bSky);
        FallBlock(AX, AY, AZ);
        Graphic.DrawGame;
        Exit;
      end;
  end;
  //
  case GetCell(AX, AY, AZ).BlockID of
    bDoor1:
      if not AddItem(iDoor) then Exit;
    bWaterMelon:
      if not AddItem(iWaterMelon, Rand(5, 7)) then Exit;
    bLeaves:
      begin
        case Rand(1, 2) of
          1: Sound.Play('open_door_1.wav');
          2: Sound.Play('open_door_2.wav');
        end;
        if (Rand(1, 33) = 1) then if not AddItem(iRedApple) then Exit;
      end;
    else Exit;
  end;
  if (GetCell(AX, AY, AZ).BlockID = bDoor1) then SetCell(AX, AY + 1, AZ, bSky);
  SetCell(AX, AY, AZ, bSky);
  FallBlock(AX, AY, AZ);
  Graphic.DrawGame;
end;

procedure TGame.Load;
begin
  Craft.Load;
  Player.Load;
  CreateRegions;
  Self.Pos.Y := Player.GetStartYPos;
end;

procedure TGame.Save;
begin
  Craft.Save;
  Player.Save;
end;

procedure TGame.LoadBlocks;
var
  I: Integer;
  A: TStringList;
begin
  PutList.Clear;
  TakeList.Clear;
  A := TStringList.Create;
  try
    A.LoadFromFile(DataPath + 'Blocks.txt');
    for I := A.Count - 1 downto 0 do
    begin
      A[I] := Trim(A[I]);
      if (A[I] = '') or (A[I][1] = '-') then
      begin
        A.Delete(I);
        Continue;
      end;
      if (System.Pos('<', A[I]) > 0)then TakeList.Append(A[I]);
      if (System.Pos('>', A[I]) > 0)then PutList.Append(A[I]);
    end;
  finally
    A.Free;
  end;
end;

function TGame.IsDist: Boolean;  
begin
  Result := GetDist(14, 10, MousePos.X div 32, MousePos.Y div 32) <= 7
end;

procedure TGame.BlockSound(BlockID: Integer);
begin
  case BlockID of
    bSky, bBase, bLeaves: Exit;
    bWood, bBoard, bLadder:
      Sound.Play('dig_choppy.wav');
    bDirt, bGrass:
      Sound.Play('dig_cracky.wav');
    bSand, bGravel:
      case Rand(1, 2) of
        1: Sound.Play('dig_crumbly_1.wav');
        2: Sound.Play('dig_crumbly_2.wav');
      end;
    bStone, bCStone:
      Sound.Play('dig_hard.wav');
    bCoal, bIronOre:
      Sound.Play('dig_node.wav');
  end;
end;

function TGame.GetFootCellID: Integer;
begin
  Result := GetCell(14, 12, 1).BlockID;
end;

end.
