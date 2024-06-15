unit Stages;

interface

uses Windows, SysUtils, Controls;

type
  TStageEnum = (stGame, stCraft);

type
  TStage = class(TObject)
    procedure Render; virtual; abstract;
    procedure Update(var Key: Word); virtual; abstract;
    procedure Timer; virtual; abstract;
    procedure MouseDown(Button: TMouseButton; X, Y: Integer); virtual; abstract;
    procedure MouseUp; virtual; abstract;
    procedure MouseWheelDown; virtual; abstract;
    procedure MouseWheelUp; virtual; abstract;
  end;

type
  TStages = class(TStage)
  private
    FStage: array [TStageEnum] of TStage;
    FStageEnum: TStageEnum;
    FPrevStageEnum: TStageEnum;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Back;
    procedure Render; override;
    procedure Update(var Key: Word); override;
    procedure Timer; override;
    procedure MouseDown(Button: TMouseButton; X, Y: Integer); override;
    procedure MouseUp; override;
    procedure MouseWheelDown; override;
    procedure MouseWheelUp; override;
    property Stage: TStageEnum read FStageEnum write FStageEnum;
    function GetStage(I: TStageEnum): TStage;
    procedure SetStage(StageEnum: TStageEnum); overload;
    procedure SetStage(StageEnum, CurrStageEnum: TStageEnum); overload;
    property PrevStage: TStageEnum read FPrevStageEnum write FPrevStageEnum;
  end;

type
  TStageGame = class(TStage)
  private

  public
    procedure Render; override;
    procedure Update(var Key: Word); override;
    procedure Timer; override;
    procedure MouseDown(Button: TMouseButton; X, Y: Integer); override;
    procedure MouseUp; override;
    procedure MouseWheelDown; override;
    procedure MouseWheelUp; override;
  end;

type
  TStageCraft = class(TStage)
  private

  public
    procedure Render; override;
    procedure Update(var Key: Word); override;
    procedure Timer; override;
    procedure MouseDown(Button: TMouseButton; X, Y: Integer); override;
    procedure MouseUp; override;
    procedure MouseWheelDown; override;
    procedure MouseWheelUp; override;
  end;

implementation

uses uGame, uVars, uRegions, uCraft, Utils, uMain, Graphics;

{ TStages }

procedure TStages.Update(var Key: Word);
begin
  if (FStage[Stage] <> nil) then
    FStage[Stage].Update(Key);
end;

procedure TStages.Render;
begin
  //Saga.Engine.Clear;
  if (FStage[Stage] <> nil) then
    FStage[Stage].Render;
end;

constructor TStages.Create;
var
  I: TStageEnum;
begin
  for I := Low(TStageEnum) to High(TStageEnum) do
    case I of
      stGame:
        FStage[I] := TStageGame.Create;
      stCraft:
        FStage[I] := TStageCraft.Create;
    end;
end;

destructor TStages.Destroy;
var
  I: TStageEnum;
begin
  for I := Low(TStageEnum) to High(TStageEnum) do
    FStage[I].Free;
  inherited;
end;

procedure TStages.SetStage(StageEnum: TStageEnum);
begin
  Self.Stage := StageEnum;
  if Assigned(Game) then Render;
end;

procedure TStages.SetStage(StageEnum, CurrStageEnum: TStageEnum);
begin
  FPrevStageEnum := CurrStageEnum;
  SetStage(StageEnum);
end;

procedure TStages.Back;
begin
  Stage := FPrevStageEnum;
end;

function TStages.GetStage(I: TStageEnum): TStage;
begin
  Result := FStage[I];
end;

procedure TStages.Timer;
begin
  if (FStage[Stage] <> nil) then
    FStage[Stage].Timer;
end;

procedure TStages.MouseWheelDown;
begin
  if (FStage[Stage] <> nil) then
    FStage[Stage].MouseWheelDown;
end;

procedure TStages.MouseWheelUp;
begin
  if (FStage[Stage] <> nil) then
    FStage[Stage].MouseWheelUp;
end;

procedure TStages.MouseDown(Button: TMouseButton; X, Y: Integer);
begin
  if (FStage[Stage] <> nil) then
    FStage[Stage].MouseDown(Button, X, Y);
end;

procedure TStages.MouseUp;
begin
  if (FStage[Stage] <> nil) then
    FStage[Stage].MouseUp;
end;

{ TStageGame }

procedure TStageGame.MouseDown(Button: TMouseButton; X, Y: Integer);
begin
  if (Y >= ScreenHeight * CellSize - Game.Panel.Surface.Height) then
  begin
    if (X >= (HalfScreenWidth * CellSize - 142))
      and (X <= (HalfScreenWidth * CellSize + 142))
    then begin
      PPM := (X - 340) div 35;
      if (PPM < 0) then PPM := 0;
      if (PPM > 7) then PPM := 7;
      Game.Graphic.DrawGame;
    end;
    Exit;
  end;
  if not Game.IsDist then Exit;
  Deep := 1;
  if (GetKeyState(VK_CONTROL) < 0) then Deep := 0;
  with Game do case Button of
    mbLeft:
      begin
        BRC := 0;
        TimerBlockID := 0;
        fMain.Timer1.Enabled := True;
        Exit;
      end;
    mbRight:
      begin
        PutBlock(MousePos.X div 32, MousePos.Y div 32, Deep);
        SaveRegions;
        Exit;
      end;
  end;
end;

procedure TStageGame.MouseUp;
begin
  BRC := 0;
  fMain.Timer1.Enabled := False;
end;

procedure TStageGame.MouseWheelDown;
begin
  PPM := Clamp(succ(PPM), 0, 7, False);
end;

procedure TStageGame.MouseWheelUp;
begin
  PPM := Clamp(pred(PPM), 0, 7, False);
end;

procedure TStageGame.Render;
begin
  Game.Graphic.DrawGame;
end;

procedure TStageGame.Timer;
var
  I, AX, AY, BlockID, Durability: Integer;
begin
  with Game do
  begin
    AX := MousePos.X div CellSize;
    AY := MousePos.Y div CellSize;
    for I := 2 downto 0 do
    begin
      if (Game.GetCell(AX, AY, I).BlockID > 0) then
      begin
        Deep := I;
        Break;
      end;
    end;
    BlockID := GetCell(AX, AY, Deep).BlockID;
    Durability := GetDurability(BlockID);
    TimerBlockID := BlockID;
    if (BlockID > 0) then begin
      if (PL = 1) then Game.BlockSound(BlockID);
      if (PL > 4) then PL := 0 else Inc(PL);
      if (AX <> PX) or (AY <> PY) then begin
        BRC := 0;
        PX := AX;
        PY := AY;
      end;
      if (BRC > 0) then begin
        Graphic.BG.Canvas.Draw(AX * CellSize, AY * CellSize,
          Graphic.Blocks[240 + (BRC div 20)]);
        Graphic.RefreshGame;
      end else begin
        PL := 0;
        BRC := 0;
        Game.Graphic.DrawGame;
      end;
      Inc(BRC, Durability); if (BRC > 199) or (Durability = 0) then
      begin
        PL := 0;
        BRC := 0;
        with Game do
        begin
          if (Game.GetCell(AX, AY, 2).BlockID > 0) then
            TakeBlock(AX, AY, 2) else
              TakeBlock(AX, AY, Deep);
        end;
        SaveRegions;
      end;
    end else begin
      PL := 0;
      BRC := 0;
      Game.Graphic.DrawGame;
    end;
  end;
end;

procedure TStageGame.Update(var Key: Word);
begin
  case Key of
    37: begin
          Game.Move(-1, 0);
          if (Game.Pos.X <= -ScreenWidth) then
          begin
            Dec(RegionPoint.X);
            Game.Pos.X := 0;
            CreateRegions;
          end;
        end;
    39: begin
          Game.Move(1,  0);
          if (Game.Pos.X >= ScreenWidth) then
          begin
            Inc(RegionPoint.X);
            Game.Pos.X := 0;
            CreateRegions;
          end;
        end;
    38: begin
          Game.Move(0, -1);
          if (Game.Pos.Y <= -ScreenHeight) then
          begin
            Dec(RegionPoint.Y);
            Game.Pos.Y := 0;
            CreateRegions;
          end;
        end;
    40: begin
          Game.Move(0,  1);
          if (Game.Pos.Y >= ScreenHeight) then
          begin
            Inc(RegionPoint.Y);
            Game.Pos.Y := 0;
            CreateRegions;
          end;
        end;
    32: begin

        end;
    49..56:
        begin
          PPM := Key - 49;
        end;
    ord('G'):
        begin
          IsGameGrid := not IsGameGrid;
          Game.Graphic.DrawGame;
        end;
    ord('T'):
        begin
          IsTransparent := not IsTransparent;
          Game.Graphic.SetTransparentBlocks;
        end;
    ord('L'): IsDrawInfo := not IsDrawInfo;
    ord('S'): IsGameSound := not IsGameSound;
    ord('I'), ord('E'):
        begin
          BRC := 0;
          fMain.Timer1.Enabled := False;
          Game.Graphic.MakeSDCraft;
          Game.Stages.SetStage(stCraft, stGame);
        end;
  end;
end;

{ TStageCraft }

procedure TStageCraft.MouseDown(Button: TMouseButton; X, Y: Integer);
var
  P: Integer;
label
  trans;
begin
      if (Y >= 198) and (Y <=480) and (X >= 341) and (X <=618) then
      begin
        if (Y >= 252) and (Y <= 283) and (X >= 552) and (X <= 583)
          and (RCD.ItemID > 0) and (RCD.Count > 0)// and (Button = mbRight)
          and ((MCD.ItemID = 0) or (MCD.ItemID = RCD.ItemID)) then
        begin
          MCD.ItemID := RCD.ItemID;
          MCD.Count := MCD.Count + RCD.Count;
          RCD.Count := 0;
          RCD.ItemID := 0;
          for P := 32 to 40 do
          begin
            if (PP[P].Count > 0) then PP[P].Count := PP[P].Count - 1;
            if (PP[P].Count = 0) then PP[P].ItemID := 0;
          end;
          Game.InvPanel.Render;
          Exit;
        end;
        ///
        if (Y >= 217) and (Y <= 318) and (X >= 412) and (X <= 513) then
        begin
          Y := (Y - 217) div 35;
          X := (X - 412) div 35;
          P := (Y * 3) + X + 32;
          goto trans;
        end;
        ///
        case Y of
          341..442, 449..480:
          begin
            X := (X - 342) div 35;
            case Y of
              341..442: Y := 3 - (Y - 341) div 35;
              449..480: Y := 0;
            end;
            P := (Y * 8) + X;
            //
            trans:
            if (PP[P].ItemID > 0) and (PP[P].Count > 0) then
            begin
              if (MCD.ItemID = 0) and (MCD.Count = 0) then
              case Button of
                mbLeft:
                begin
                  MCD.ItemID := PP[P].ItemID;
                  MCD.Count := PP[P].Count;
                  PP[P].ItemID := 0;
                  PP[P].Count := 0;
                  Game.InvPanel.Render;
                  Exit;
                end;
                mbRight:
                begin
                  MCD.ItemID := PP[P].ItemID;
                  if (PP[P].Count > 1) then
                  begin
                    MCD.Count := PP[P].Count div 2;
                    PP[P].Count := PP[P].Count - MCD.Count;
                  end else begin
                    PP[P].Count := 0;
                    PP[P].ItemID := 0;
                    MCD.Count := PP[P].Count + 1;
                  end;
                  Game.InvPanel.Render;
                  Exit;
                end;
              end;     
              if (MCD.ItemID = PP[P].ItemID) and (MCD.Count > 0) then
              case Button of
                mbLeft:
                begin
                  PP[P].Count := PP[P].Count + MCD.Count;
                  MCD.ItemID := 0;
                  MCD.Count := 0;
                  Game.InvPanel.Render;
                  Exit;
                end;
                mbRight:
                begin
                  PP[P].Count := PP[P].Count + 1;
                  MCD.Count := MCD.Count - 1;
                  if (MCD.Count = 0) then MCD.ItemID := 0;
                  Game.InvPanel.Render;
                  Exit;
                end;
              end;
            end;
            if (PP[P].ItemID = 0) and (PP[P].Count = 0) then
            case Button of
              mbLeft:
              begin
                PP[P].ItemID := MCD.ItemID;
                PP[P].Count := MCD.Count;
                MCD.ItemID := 0;
                MCD.Count := 0;
                Game.InvPanel.Render;
                Exit;
              end;
              mbRight:
              begin
                PP[P].ItemID := MCD.ItemID;
                PP[P].Count := 1;
                MCD.Count := MCD.Count - 1;
                if (MCD.Count = 0) then MCD.ItemID := 0;
                Game.InvPanel.Render;
                Exit;
              end;
            end;           
          end;
        end;
      end;
end;

procedure TStageCraft.MouseUp;
begin

end;

procedure TStageCraft.MouseWheelDown;
begin
  PPM := Clamp(succ(PPM), 0, 7, False);
end;

procedure TStageCraft.MouseWheelUp;
begin
  PPM := Clamp(pred(PPM), 0, 7, False);
end;

procedure TStageCraft.Render;
//var
  //X, Y: Integer;
const
  F = ((7 * 3) + (6 * 2)) / 2;
  W = (32 * 4) + F;
  H = (32 * 5) + (6 * 2);
begin
  Game.Graphic.BG.Canvas.Pen.Color := clRed;
  Game.Graphic.BG.Canvas.Brush.Color := clRed;
  Game.Graphic.BG.Canvas.Brush.Style := bsSolid;
  Game.Graphic.BG.Canvas.Rectangle((HalfScreenWidth * 32) - Round(W),
    (HalfScreenHeight * 32) - Round(H),
    (HalfScreenWidth * 32) + Round(W),
    (HalfScreenHeight * 32) + Round(H));
  Game.Graphic.BG.Canvas.Brush.Style := bsClear;
  //Game.Graphic.DrawCraft;
  
  Game.InvPanel.Render;
end;

procedure TStageCraft.Timer;
begin

end;

procedure TStageCraft.Update(var Key: Word);
begin
  case Key of
    27, ord('I'), ord('E'):
    begin
      BRC := 0;
      fMain.Timer1.Enabled := False;
      Game.Craft.Save;
      Game.Stages.Back;
    end;
    49..56:
    begin
      PPM := Key - 49;
    end;
  end;
end;

end.
