unit uGraphics;

interface

uses Windows, Types, Graphics, uCraft;

const
  FrameSize = 4;
  CraftSize = 3;
  InvWidth  = 8;
  InvHeight = 4;

type
  TCustomInterf = class(TObject)
  private
    FLeft: Word;
    FTop: Word;
    FSurface: TBitmap;
  public
    constructor Create;
    destructor Destroy; override;
    property Left: Word read FLeft;
    property Top: Word read FTop;
    property Surface: TBitmap read FSurface write FSurface;
    procedure Rectangle(X, Y: Word);
  end;

type
  TPanel = class(TCustomInterf)
  private

  public
    constructor Create;
    destructor Destroy; override;
    procedure Render(IsGray: Boolean = False);
  end;

type
  TCraftCells = class(TCustomInterf)
  private

  public
    constructor Create;
    destructor Destroy; override;
    procedure Render;
  end;

type
  TRCraftCell = class(TCustomInterf)
  private

  public
    constructor Create;
    destructor Destroy; override;
    procedure Render;
  end;

type
  TInvPanel = class(TCustomInterf)
  private
    FCraftCells: TCraftCells;
    FRCraftCell: TRCraftCell;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Render;
    property CraftCells: TCraftCells read FCraftCells write FCraftCells;
    property RCraftCell: TRCraftCell read FRCraftCell write FRCraftCell;
  end;

type
  TGraphic = class
  private
  public
    BG, SD: TBitmap;
    Marker, GameMarker, RedGameMarker, PB, PHL, PHR, CP, HP, HG: TBitmap;
    DeepBlocks, Blocks: array [0..256 - 1] of TBitmap;
    Items: array [0..256 * 3] of TBitmap;
    procedure DrawCell(X, Y: Integer);
    function IsTransparentBlock(BlockID: Integer): Boolean;
    procedure SetTransparentBlocks();
    procedure Draw;
    function GetCell(AX, AY, AZ: Integer): Integer;
    procedure DrawGame;
    procedure RefreshGame;
    procedure DrawBlock(AX, AY: Integer; AItem: TItem; IsGray: Boolean = False);
    procedure DrawInfo;
    procedure MakeSDCraft; 
    procedure DrawPlayer;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses SysUtils, Dialogs, uMain, uVars, uRegions, Player, uGame,
  uGraphUtils, Utils;

{ TGraphic }

function TGraphic.IsTransparentBlock(BlockID: Integer): Boolean;
begin
  case BlockID of
    bLeaves, bPapirus, bRose, bDandelion, bMushroom1, bMushroom2, bLadder,
    bTorch, bDoor1, bOpenDoor1, bOpenDoor2, bNet
      : Result := True;
    else Result := False;
  end;
end;

constructor TGraphic.Create;
var
  I: Integer;
begin
  with fMain do
  begin
    BG := TBitmap.Create;
    BG.Width := ClientWidth;
    BG.Height := ClientHeight;
    BG.Canvas.Font.Color := clBlack;
    SD := TBitmap.Create;
    SD.Width := ClientWidth;
    SD.Height := ClientHeight;
    SD.Canvas.Font.Color := clBlack;
  end;
  // Terrain
  for I := 0 to High(Blocks) do
  begin
    Blocks[I] := TBitmap.Create;
    DeepBlocks[I] := TBitmap.Create;
  end;
  SplitImage(Blocks, DataPath + 'Terrain.bmp', True);
  for I := 0 to High(Blocks) do
  begin
    DeepBlocks[I].Assign(Blocks[I]);
    if not IsTransparentBlock(I) then Gamma(DeepBlocks[I], 0.7);
  end;
  // Load add blocks
  Blocks[bOpenDoor1].LoadFromFile(DataPath + 'OpenDoor.bmp');
  Blocks[bOpenDoor2].LoadFromFile(DataPath + 'OpenDoor.bmp');
  SetTransparentBlocks();
  // Items
  for I := 0 to High(Items) do Items[I] := TBitmap.Create;
  SplitImage(Items, DataPath + 'Terrain.bmp', True);
  SplitImage(Items, DataPath + 'Items.bmp', True, 256);
  SplitImage(Items, DataPath + 'Blocks.bmp', False, 256 * 2);
  for I := 0 to High(Items) do
  begin
    Items[I].Transparent := IsTransparent;
    Items[I].TransparentColor := clBlack;
  end;
  //
  PB := TBitmap.Create;
  PB.LoadFromFile(DataPath + 'PB.bmp');
  PHR := TBitmap.Create;
  PHR.LoadFromFile(DataPath + 'PH.bmp');
  PHL := TBitmap.Create;
  PHL.Assign(PHR);
  FlipBmp(PHL);
  CP := TBitmap.Create;
  CP.LoadFromFile(DataPath + 'Craft.bmp');
  //
  Marker := TBitmap.Create;
  Marker.Transparent := True;
  Marker.TransparentColor := clFuchsia;
  Marker.LoadFromFile(DataPath + 'Marker.bmp');
  HP := TBitmap.Create;
  HP.Transparent := True;
  HP.LoadFromFile(DataPath + 'Bars.bmp');
  HG := TBitmap.Create;
  HG.Transparent := True;
  HG.Width := 8; HG.Height := 8;
  HG.Canvas.CopyRect(Bounds(0, 0, 8, 8), HP.Canvas, Bounds(8, 0, 8, 8));
  HP.Width := 8; HP.Height := 8;
  GameMarker := TBitmap.Create;
  GameMarker.Transparent := True;
  GameMarker.LoadFromFile(DataPath + 'Border.bmp');
  GameMarker.TransparentColor := GameMarker.Canvas.Pixels[1, 1];
  RedGameMarker := TBitmap.Create;
  with RedGameMarker do
  begin
    Transparent := True;
    Assign(GameMarker);
    TransparentColor := Canvas.Pixels[1, 1];
    Canvas.Pen.Color := clRed;
    Canvas.MoveTo(0, 0);
    Canvas.LineTo(0, 31);
    Canvas.MoveTo(0, 31);
    Canvas.LineTo(31, 31);
    Canvas.MoveTo(31, 31);
    Canvas.LineTo(31, 0);
    Canvas.MoveTo(31, 0);
    Canvas.LineTo(0, 0);
  end;
end;

destructor TGraphic.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(Blocks) do
  begin
    Blocks[i].Free;
    DeepBlocks[i].Free;
  end;
  GameMarker.Free;
  Marker.Free;
  PHL.Free;
  PHR.Free;
  PB.Free;
  BG.Free;
  SD.Free;
  HP.Free;
  HG.Free;
  inherited;    
end;

procedure TGraphic.Draw;
begin

end;

procedure TGraphic.DrawInfo;
begin
  {if IsDrawInfo then
  with fMain do
  case Scene of
    scGame:
    begin
      BG.Canvas.TextOut(32, 32,  'PC.X = ' + IntToStr(Game.Player.X + (HalfScreenWidth - 1)));
      BG.Canvas.TextOut(32, 48,  'PC.Y = ' + IntToStr(Game.Player.Y + HalfScreenHeight));
      BG.Canvas.TextOut(32, 64,  'Reg.X = ' + IntToStr(RegionPoint.X));
      BG.Canvas.TextOut(32, 80,  'Reg.Y = ' + IntToStr(RegionPoint.Y));
      BG.Canvas.TextOut(32, 96,  'BaseLine = ' + IntToStr(BaseLine));
      BG.Canvas.TextOut(32, 112, 'TGL = ' + IntToStr(BaseLine * ScreenHeight + Game.Y));
      BG.Canvas.TextOut(32, 128, 'Density = ' + IntToStr(Density));
      BG.Canvas.TextOut(32, 144, 'Cell = ' +
        IntToStr(Ord(RMap[Game.X + ScreenWidth + (HalfScreenWidth - 1),
          Game.Y + ScreenHeight + (HalfScreenHeight + 2), 1].Block) - BS));
      BG.Canvas.TextOut(32, 160, 'MX = ' + IntToStr(Game.MX div 32));
      BG.Canvas.TextOut(32, 176, 'MY = ' + IntToStr(Game.MY div 32));
      BG.Canvas.TextOut(32, 192, 'GameX = ' + IntToStr(Game.X));
      BG.Canvas.TextOut(32, 208, 'GameY = ' + IntToStr(Game.Y));
    end;
    scCraft:
    begin }
      BG.Canvas.TextOut(32, 32,  'MX = ' + IntToStr(Game.MousePos.X));
      BG.Canvas.TextOut(32, 48,  'MY = ' + IntToStr(Game.MousePos.Y));
    //end;
  //end;
end;

procedure TGraphic.MakeSDCraft;  
var
  X, Y: Integer;
//  A, R: TBitmap;
begin
  with fMain do
  begin
    BG.Canvas.Brush.Color := clSkyBlue;
    BG.Canvas.FillRect(Rect(0, 0, BG.Width, BG.Height));
    BG.Canvas.Brush.Style := bsClear;
    for Y := 0 to ScreenHeight - 1 do
      for X := 0 to ScreenWidth - 1 do
        if (X <= 10) or (X >= 19) or (Y <= 5) or (Y >= 15) then
          DrawCell(X, Y);
    ModColors(BG, clGray);
{



    A := TBitmap.Create;
    R := TBitmap.Create;
    R.Width := 32;
    R.Height := 32;


    A.Assign(PLL);
//    Gamma(A, 0.8);
    InclinationBitmap(A, 0, -25, clFuchsia);
    A.Transparent := True;
    R.Canvas.Draw(32 - 32, 32 - 24, A);
    A.Assign(PLL);
//    Gamma(A, 0.6);
    InclinationBitmap(A, 0, 25, clFuchsia);
    A.Transparent := True;
    A.TransparentColor := clFuchsia;
    R.Canvas.Draw(48 - 32, 32 - 24, A);
    A.Assign(PLL);
    RotateBitmap(A, 45, clFuchsia);
//    ScaleBmp(A, 32, 16 + 1);
    A.Transparent := True;
    R.Canvas.Draw(32 - 32, 24 - 24, A);
    ScaleBmp(R, 26, 32);

    BG.Canvas.Draw(32, 32, R);
    A.Free;
    R.Free;



}
    SD.Assign(BG);
  end;
end;

procedure TGraphic.DrawGame;
var
  X, Y: Integer;
  T: Cardinal;
begin
  T := GetTickCount;
  with fMain do
  begin
    BG.Canvas.Brush.Color := clSkyBlue;
    BG.Canvas.FillRect(Rect(0, 0, BG.Width, BG.Height));
    BG.Canvas.Brush.Style := bsClear;
    for Y := 0 to ScreenHeight - 1 do
      for X := 0 to ScreenWidth - 1 do
      begin
        DrawCell(X, Y);
        if IsGameGrid and (GetDist(14, 10, X, Y) <= 7) then
          BG.Canvas.Draw(X * 32, Y * 32, RedGameMarker);
      end;
    DrawPlayer;
    Game.Panel.Render;
    DrawInfo;
    if Game.IsDist then BG.Canvas.Draw(Game.MousePos.X div 32 * 32, Game.MousePos.Y div 32 * 32, GameMarker);
    BG.Canvas.TextOut(900, 32, IntToStr(GetTickCount - T) + ' ms');
  end;
end;

procedure TGraphic.DrawBlock(AX, AY: Integer; AItem: TItem; IsGray: Boolean = False);
var
  S: string;
  A: TSize;
  T: TBitmap;
begin
  if IsGray then
  begin
    T := TBitmap.Create;
    try
      T.Assign(Items[AItem.ItemID]);
      if (AItem.Count > 1) then
      with T.Canvas do
      begin
        Brush.Style := bsClear;
        S := IntToStr(AItem.Count);
        A := TextExtent(S);
        TextOut(27 - A.CX, 32 - A.CY, S);
      end;
      ModColors(T, clGray);
      BG.Canvas.Draw(AX, AY, T);
    finally
      T.Free;
    end;
    Exit;
  end;
  with BG.Canvas do
  begin
    Draw(AX, AY, Items[AItem.ItemID]);
    if (AItem.Count > 1) then
    begin
      S := IntToStr(AItem.Count);
      A := TextExtent(S);
      TextOut(AX + 27 - A.CX, AY + 32 - A.CY, S);
    end;
  end;
end;

procedure TGraphic.DrawPlayer;
var
  T, Y: Integer;
begin
  BG.Canvas.Draw((HalfScreenWidth - 1) * CellSize + 10, HalfScreenHeight * CellSize + 18, PB);
  if Game.Player.MoveToRight then
    BG.Canvas.Draw((HalfScreenWidth - 1) * CellSize + 7, HalfScreenHeight * CellSize, PHR)
      else
        BG.Canvas.Draw((HalfScreenWidth - 1) * CellSize + 7, HalfScreenHeight * CellSize, PHL);
  for Y := 10 to 11 do
  begin
    T := Ord(RMap[Game.Pos.X + ScreenWidth + 14, Game.Pos.Y + ScreenHeight + Y, 2].Block) - BS;
    if (T > 0) then BG.Canvas.Draw(CellSize * 14, CellSize * Y, Blocks[T]);
  end;
end;

function TGraphic.GetCell(AX, AY, AZ: Integer): Integer;
begin
  Result := Ord(RMap[Game.Pos.X + ScreenWidth + AX, Game.Pos.Y + ScreenHeight + AY, AZ].Block) - BS;
  if (Result > 255) or (Result < 0) then Result := 0;
end;

procedure TGraphic.DrawCell(X, Y: Integer);
var
  R0, R1, R2: Integer;
begin
  R0 := 0; R1 := GetCell(X, Y, 1); R2 := GetCell(X, Y, 2);
  if IsTransparentBlock(R1) or (R1 = 0) then R0 := GetCell(X, Y, 0);
  if (R0 > 0) then BG.Canvas.Draw(X * CellSize, Y * CellSize, DeepBlocks[R0]);
  if (R1 > 0) then BG.Canvas.Draw(X * CellSize, Y * CellSize, Blocks[R1]);
  if (R2 > 0) then BG.Canvas.Draw(X * CellSize, Y * CellSize, Blocks[R2]);
end;

procedure TGraphic.SetTransparentBlocks;
var
  I: Integer;
begin
  for I := 0 to High(Blocks) do
  begin
    if IsTransparentBlock(I) then
    begin
      Blocks[I].Transparent := IsTransparent;
      Blocks[I].TransparentColor := clBlack;
      DeepBlocks[I].Transparent := IsTransparent;
      DeepBlocks[I].TransparentColor := clBlack;
    end;
    if (I >= 240) and (I <= 250) then
    begin
      Blocks[I].Transparent := True;
      Blocks[I].TransparentColor := clWhite;
    end;
  end;
end;

procedure TGraphic.RefreshGame;
begin
  with fMain do
  begin
    DrawPlayer;
    Game.Panel.Render;
    DrawInfo;
    Canvas.Draw(0, 0, BG);
  end;
end;

{ TCustomInterf }

constructor TCustomInterf.Create;
begin
  Surface := TBitmap.Create;
  Surface.Canvas.Brush.Color := clGrayText;
end;

destructor TCustomInterf.Destroy;
begin

  inherited;
end;

procedure TCustomInterf.Rectangle(X, Y: Word);
begin
  Surface.Canvas.Pen.Color := clSilver;
  Surface.Canvas.Brush.Color := clSilver;
  Surface.Canvas.Brush.Style := bsSolid;
  Surface.Canvas.Rectangle(X, Y, X + CellSize, Y + CellSize);
end;

{ TPanel }

constructor TPanel.Create;
var
  I: Byte;
begin
  inherited;
  Surface.Width := (CellSize * InvWidth) + (FrameSize * (InvWidth + 1));
  Surface.Height := CellSize + (FrameSize * 2);
  Surface.Canvas.FillRect(Rect(0, 0, Surface.Width, Surface.Height));
  for I := 0 to InvWidth - 1 do
    Rectangle((CellSize * I) + (FrameSize * I) + FrameSize, FrameSize);
  FLeft := (HalfScreenWidth * CellSize) - (Surface.Width div 2);
  FTop := (ScreenHeight * CellSize) - Surface.Height;
end;

destructor TPanel.Destroy;
begin

  inherited;
end;

procedure TPanel.Render(IsGray: Boolean = False);
var
  I: Word;
begin
  Game.Graphic.BG.Canvas.Draw(Left, Top, Surface);
  if not IsGray then
  begin
    Game.Graphic.BG.Canvas.Draw(Left + (PPM * 35), Top, Game.Graphic.Marker);
    for I := 0 to Game.Player.Life - 1 do
      Game.Graphic.BG.Canvas.Draw(Left + (I * 10), Top - 10, Game.Graphic.HP);
    for I := Game.Player.Hung - 1 downto 0 do
      Game.Graphic.BG.Canvas.Draw(Left + Surface.Width - 8 - (I * 10), Top - 10, Game.Graphic.HG);
  end;
  for I := 0 to 7 do
    if (PP[I].ItemID > 0) and (PP[I].Count > 0) then
      Game.Graphic.DrawBlock(Left + I * 35 + 3, Top + 3, PP[I], IsGray);
end;

{ TCraftCells }

constructor TCraftCells.Create;
var
  I, J, X, Y: Word;
begin
  inherited;
  Surface.Width := (CellSize * CraftSize) + (FrameSize * (CraftSize + 1));
  Surface.Height := (CellSize * CraftSize) + (FrameSize * (CraftSize + 1));
  Surface.Canvas.FillRect(Rect(0, 0, Surface.Width, Surface.Height));
  for I := 0 to CraftSize - 1 do
    for J := 0 to CraftSize - 1 do
    begin
      X := (CellSize * I) + (FrameSize * I) + FrameSize;
      Y := (CellSize * J) + (FrameSize * J) + FrameSize;
      Rectangle(X, Y);
    end;
  FLeft := (HalfScreenWidth * CellSize) - (Surface.Width div 2) - 18;
  FTop := HalfScreenHeight * CellSize - Surface.Height;
end;

destructor TCraftCells.Destroy;
begin

  inherited;
end;

procedure TCraftCells.Render;
var
  I, X, Y: Byte;
begin
  Game.Graphic.BG.Canvas.Draw(Left, Top, Surface);
  for Y := 0 to CraftSize - 1 do
    for X := 0 to CraftSize - 1 do
    begin
      I := Y * CraftSize + X;
      if (PP[I + 32].ItemID > 0) and (PP[I + 32].Count > 0) then
      begin
        Game.Graphic.DrawBlock(X * (CellSize + FrameSize) + Left + FrameSize,
          Y * (CellSize + FrameSize) + Top + FrameSize, PP[I + 32]);
      end;
    end;
end;

{ TRCraftCell }

constructor TRCraftCell.Create;
begin
  inherited;
  Surface.Width := CellSize + (FrameSize * 2);
  Surface.Height := CellSize + (FrameSize * 2);
  Surface.Canvas.FillRect(Rect(0, 0, Surface.Width, Surface.Height));
  FLeft := (HalfScreenWidth * CellSize) - (Surface.Width div 2) + (CellSize * 3) - (FrameSize * 2);
  FTop := HalfScreenHeight * CellSize - (CellSize * 2) - (FrameSize * 3);
  Rectangle(FrameSize, FrameSize);
end;

destructor TRCraftCell.Destroy;
begin

  inherited;
end;

procedure TRCraftCell.Render;
begin
  Game.Graphic.BG.Canvas.Draw(Left, Top, Surface);
  if (RCD.ItemID > 0) and (RCD.Count > 0) then
    Game.Graphic.DrawBlock(Left + FrameSize, Top + FrameSize, RCD);

end;

{ TInvPanel }

constructor TInvPanel.Create;
var
  I, J, X, Y: Word;
begin
  inherited;
  Surface.Width := (CellSize * InvWidth) + (FrameSize * (InvWidth + 1));
  Surface.Height := (CellSize * InvHeight) + (FrameSize * (InvHeight + 1));
  Surface.Canvas.FillRect(Rect(0, 0, Surface.Width, Surface.Height));
  for I := 0 to InvWidth - 1 do
    for J := 0 to InvHeight - 1 do
    begin
      X := (CellSize * I) + (FrameSize * I) + FrameSize;
      Y := (CellSize * J) + (FrameSize * J) + FrameSize;
      Rectangle(X, Y);
    end;
  FLeft := (HalfScreenWidth * CellSize) - (Surface.Width div 2);
  FTop := HalfScreenHeight * CellSize + 18;
  CraftCells := TCraftCells.Create;
  RCraftCell := TRCraftCell.Create;
end;

destructor TInvPanel.Destroy;
begin
  CraftCells.Free;
  RCraftCell.Free;
  inherited;
end;

procedure TInvPanel.Render;
var
  I, X, Y: Word;
begin
  Game.Graphic.BG.Canvas.Draw(0, 0, Game.Graphic.SD);
  Game.Craft.DoCraft;
  Game.Graphic.BG.Canvas.Draw(Left, Top, Surface);
  for Y := 0 to InvHeight - 1 do
    for X := 0 to InvWidth - 1 do
    begin
      I := Y * InvWidth + X;
      if (PP[I].ItemID > 0) and (PP[I].Count > 0) then
      begin
        Game.Graphic.DrawBlock(X * (CellSize + FrameSize) + Left + FrameSize,
          Y * (CellSize + FrameSize) + Top + FrameSize, PP[I]);
      end;
    end;
  CraftCells.Render;   
  RCraftCell.Render;
  Game.Graphic.BG.Canvas.Draw(Left + (PPM * (CellSize + FrameSize)), Top, Game.Graphic.Marker);
  Game.Panel.Render(True);
  if (MCD.ItemID > 0) and (MCD.Count > 0) then
    Game.Graphic.DrawBlock(Game.MousePos.X, Game.MousePos.Y, MCD);
end;

end.
