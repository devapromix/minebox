unit Player;

interface

uses Types;

type
  TPlayer = class
  private
    FHC: Word;
    FPos: TPoint;
    FLife: Integer;
    FHung: Integer;
    FMoveToRight: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function GetStartYPos: Integer;
    property Pos: TPoint read FPos write FPos;
    property Life: Integer read FLife write FLife;
    property Hung: Integer read FHung write FHung;
    property MoveToRight: Boolean read FMoveToRight write FMoveToRight;
    procedure Move; overload;
    procedure Move(X, Y: ShortInt); overload;
    procedure Load;
    procedure Save;
  end;

implementation

uses SysUtils, Classes, Dialogs, uCraft, uVars, uRegions, uGame;

{ TPlayer }

constructor TPlayer.Create;
begin
  MoveToRight := True;
  Pos := Point(0, 0);
  FHC := 0;
  Life := 14;
  Hung := 14;
end;

destructor TPlayer.Destroy;
begin

  inherited;
end;

function TPlayer.GetStartYPos: Integer;
var
  Y: Integer;
  C: Char;
begin
  Result := 0;
  for Y := 0 to ScreenHeight - 1 do
  begin
    C := RMap[44][ScreenHeight + Y][1].Block;
    if (C <> Chr(BS)) and not Game.GetMoveCell(Ord(C) - BS) then
    begin
      Result := Y - (ScreenHeight div 2) - 2;
      Exit;
    end;
  end;
end;

procedure TPlayer.Move(X, Y: ShortInt);
begin
  FPos.X := FPos.X + X;
  FPos.Y := FPos.Y + Y;
end;

procedure TPlayer.Move;
begin
  Inc(FHC);
  if (FHC > 25) then
  begin
    FHC := 0;
    Hung := Hung - 1;
  end;
  if (Hung <= 0) then
  begin
    Hung := 0;
    Life := Life - 1;
  end;
  if (Life <= 0) then
  begin
    //Scene := scDefeat;
    Game.Graphic.Draw;
  end;
end;

procedure TPlayer.Load;
begin

end;

procedure TPlayer.Save;
begin

end;

end.
