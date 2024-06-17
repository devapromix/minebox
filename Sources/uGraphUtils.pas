unit uGraphUtils;

interface

uses
  Windows,
  Types,
  Graphics,
  uVars;

procedure RotateBitmap(Bitmap: TBitmap; Angle: Double; BackColor: TColor);
procedure InclinationBitmap(Bitmap: TBitmap; Hor, Ver: Double;
  BackColor: TColor);
procedure FlipBmp(Bitmap: TBitmap; FlipHor: Boolean = True);
procedure Gamma(Bitmap: TBitmap; L: Double);
procedure ModColors(Bitmap: TBitmap; Color: TColor);
procedure ScaleBmp(Bitmap: TBitmap; CX, CY: Integer);
procedure SplitImage(var Images: array of TBitmap; FileName: string;
  IsScale: Boolean; L: Integer = 0);
// procedure Rectangle(Surface: TBitmap; Pos: TPoint; Color: Integer; Full: Boolean = False);

implementation

{
  procedure Rectangle(Surface: TBitmap; Pos: TPoint; Color: Integer; Full: Boolean = False);
  begin
  Surface.Canvas.Pen.Color := Color;
  if not Full then Surface.Canvas.Brush.Style := bsClear
  else Surface.Canvas.Brush.Style := bsSolid;
  Surface.Canvas.Rectangle(Pos.X * 32 - 1, Pos.Y * Char.Height - 1,
  Pos.X * Char.Width + Char.Width + 1, Pos.Y * Char.Height + Char.Height + 1);
  end;
}
procedure RotateBitmap(Bitmap: TBitmap; Angle: Double; BackColor: TColor);

type
  TRGB = record

    B, G, R: Byte;

  end;

  pRGB = ^TRGB;

  pByteArray = ^TByteArray;

  TByteArray = array [0 .. 32767] of Byte;

  TRectList = array [1 .. 4] of TPoint;

var
  x, y, W, H, v1, v2: Integer;

  Dest, Src: pRGB;

  VertArray: array of pByteArray;

  Bmp: TBitmap;

  procedure SinCos(AngleRad: Double; var ASin, ACos: Double);

  begin

    ASin := Sin(AngleRad);

    ACos := Cos(AngleRad);

  end;

  function RotateRect(const Rect: TRect; const Center: TPoint; Angle: Double)
    : TRectList;

  var
    DX, DY: Integer;

    SinAng, CosAng: Double;

    function RotPoint(PX, PY: Integer): TPoint;

    begin

      DX := PX - Center.x;

      DY := PY - Center.y;

      Result.x := Center.x + Round(DX * CosAng - DY * SinAng);

      Result.y := Center.y + Round(DX * SinAng + DY * CosAng);

    end;

  begin

    SinCos(Angle * (Pi / 180), SinAng, CosAng);

    Result[1] := RotPoint(Rect.Left, Rect.Top);

    Result[2] := RotPoint(Rect.Right, Rect.Top);

    Result[3] := RotPoint(Rect.Right, Rect.Bottom);

    Result[4] := RotPoint(Rect.Left, Rect.Bottom);

  end;

  function Min(A, B: Integer): Integer;

  begin

    if A < B then
      Result := A

    else
      Result := B;

  end;

  function Max(A, B: Integer): Integer;

  begin

    if A > B then
      Result := A

    else
      Result := B;

  end;

  function GetRLLimit(const RL: TRectList): TRect;

  begin

    Result.Left := Min(Min(RL[1].x, RL[2].x), Min(RL[3].x, RL[4].x));

    Result.Top := Min(Min(RL[1].y, RL[2].y), Min(RL[3].y, RL[4].y));

    Result.Right := Max(Max(RL[1].x, RL[2].x), Max(RL[3].x, RL[4].x));

    Result.Bottom := Max(Max(RL[1].y, RL[2].y), Max(RL[3].y, RL[4].y));

  end;

  procedure Rotate;

  var
    x, y, xr, yr, yp: Integer;

    ACos, ASin: Double;

    Lim: TRect;

  begin

    W := Bmp.Width;

    H := Bmp.Height;

    SinCos(-Angle * Pi / 180, ASin, ACos);

    Lim := GetRLLimit(RotateRect(Rect(0, 0, Bmp.Width, Bmp.Height),
      Point(0, 0), Angle));

    Bitmap.Width := Lim.Right - Lim.Left;

    Bitmap.Height := Lim.Bottom - Lim.Top;

    Bitmap.Canvas.Brush.Color := BackColor;

    Bitmap.Canvas.FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));

    for y := 0 to Bitmap.Height - 1 do
    begin

      Dest := Bitmap.ScanLine[y];

      yp := y + Lim.Top;

      for x := 0 to Bitmap.Width - 1 do
      begin

        xr := Round(((x + Lim.Left) * ACos) - (yp * ASin));

        yr := Round(((x + Lim.Left) * ASin) + (yp * ACos));

        if (xr > -1) and (xr < W) and (yr > -1) and (yr < H) then
        begin

          Src := Bmp.ScanLine[yr];

          Inc(Src, xr);

          Dest^ := Src^;

        end;

        Inc(Dest);

      end;

    end;

  end;

begin

  Bitmap.PixelFormat := pf24Bit;

  Bmp := TBitmap.Create;

  try

    Bmp.Assign(Bitmap);

    W := Bitmap.Width - 1;

    H := Bitmap.Height - 1;

    if Frac(Angle) <> 0.0

    then
      Rotate

    else

      case Trunc(Angle) of

        - 360, 0, 360, 720:
          Exit;

        90, 270:
          begin

            Bitmap.Width := H + 1;

            Bitmap.Height := W + 1;

            SetLength(VertArray, H + 1);

            v1 := 0;

            v2 := 0;

            if Angle = 90.0 then
              v1 := H

            else
              v2 := W;

            for y := 0 to H do
              VertArray[y] := Bmp.ScanLine[Abs(v1 - y)];

            for x := 0 to W do
            begin

              Dest := Bitmap.ScanLine[x];

              for y := 0 to H do
              begin

                v1 := Abs(v2 - x) * 3;

                with Dest^ do
                begin

                  B := VertArray[y, v1];

                  G := VertArray[y, v1 + 1];

                  R := VertArray[y, v1 + 2];

                end;

                Inc(Dest);

              end;

            end

          end;

        180:
          begin

            for y := 0 to H do
            begin

              Dest := Bitmap.ScanLine[y];

              Src := Bmp.ScanLine[H - y];

              Inc(Src, W);

              for x := 0 to W do
              begin

                Dest^ := Src^;

                Dec(Src);

                Inc(Dest);

              end;

            end;

          end;

      else
        Rotate;

      end;

  finally

    Bmp.Free;

  end;

end;

procedure InclinationBitmap(Bitmap: TBitmap; Hor, Ver: Double;
  BackColor: TColor);

  function Tan(x: Extended): Extended;
  // Tan := Sin(X) / Cos(X)
  asm
    FLD X
    FPTAN
    FSTP ST(0) // FPTAN pushes 1.0 after result
    FWAIT
  end;

type
  TRGB = record
    B, G, R: Byte;
  end;

  pRGB = ^TRGB;

var

  x, y, WW, HH, alpha: Integer;

  OldPx, NewPx: pRGB;

  T: Double;

  Bmp: TBitmap;

begin

  Bitmap.PixelFormat := pf24Bit;

  Bmp := TBitmap.Create;

  try

    Bmp.Assign(Bitmap);

    WW := Bitmap.Width;

    HH := Bitmap.Height;

    if Hor <> 0.0 then

    begin // ѕо горизонтали

      T := Tan(Hor * (Pi / 180));

      Inc(WW, Abs(Round(HH * T)));

      Bitmap.Width := WW;

      Bitmap.Canvas.Brush.Color := BackColor;

      Bitmap.Canvas.FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));

      for y := 0 to HH - 1 do

      begin

        if T > 0 then

          alpha := Round((HH - y) * T)

        else

          alpha := -Round(y * T);

        OldPx := Bmp.ScanLine[y];

        NewPx := Bitmap.ScanLine[y];

        Inc(NewPx, alpha);

        for x := 0 to Bmp.Width - 1 do

        begin

          NewPx^ := OldPx^;

          Inc(NewPx);

          Inc(OldPx);

        end;

      end;

      Bmp.Assign(Bitmap);

    end;

    if Ver <> 0.0 then

    begin // ѕо вертикали

      T := Tan(Ver * (Pi / 180));

      Bitmap.Height := HH + Abs(Round(WW * T));

      Bitmap.Canvas.Brush.Color := BackColor;

      Bitmap.Canvas.FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));

      for x := 0 to WW - 1 do

      begin

        if T > 0 then

          alpha := Round((WW - x) * T)

        else

          alpha := -Round(x * T);

        for y := 0 to Bmp.Height - 1 do

        begin

          NewPx := Bitmap.ScanLine[y + alpha];

          OldPx := Bmp.ScanLine[y];

          Inc(OldPx, x);

          Inc(NewPx, x);

          NewPx^ := OldPx^;

        end;

      end;

    end;

  finally

    Bmp.Free;

  end;

end;

procedure FlipBmp(Bitmap: TBitmap; FlipHor: Boolean = True);
var

  x, y, W, H: Integer;

  Pixel_1, Pixel_2: PRGBTriple;

  MemPixel: TRGBTriple;

begin

  Bitmap.PixelFormat := pf24Bit;

  W := Bitmap.Width - 1;

  H := Bitmap.Height - 1;

  if FlipHor then { отражение по горизонтали }

    for y := 0 to H do

    begin

      { помещаем оба указател€ на строку H: }

      Pixel_1 := Bitmap.ScanLine[y];

      Pixel_2 := Bitmap.ScanLine[y];

      { помещаем второй указатель в конец строки: }

      Inc(Pixel_2, W);

      { цикл идЄт только до середины строки: }

      for x := 0 to W div 2 do

      begin

        { симметричные точки обмениваютс€ цветами: }

        MemPixel := Pixel_1^;

        Pixel_1^ := Pixel_2^;

        Pixel_2^ := MemPixel;

        Inc(Pixel_1); { смещаем указатель вправо }

        Dec(Pixel_2); { смещаем указатель влево }

      end;

    end

  else { отражение по вертикали }

    { цикл идЄт только до средней строки: }

    for y := 0 to H div 2 do

    begin

      { помещаем первый указатель на строку H,

        а второй на строку симметричную H: }

      Pixel_1 := Bitmap.ScanLine[y];

      Pixel_2 := Bitmap.ScanLine[H - y];

      for x := 0 to W do

      begin

        { симметричные точки обмениваютс€ цветами: }

        MemPixel := Pixel_1^;

        Pixel_1^ := Pixel_2^;

        Pixel_2^ := MemPixel;

        Inc(Pixel_1); { смещаем указатель вправо }

        Inc(Pixel_2); { смещаем указатель вправо }

      end;

    end;

end;

procedure Gamma(Bitmap: TBitmap; L: Double);

  function Power(Base, Exponent: Extended): Extended;
  begin
    Result := Exp(Exponent * Ln(Base));
  end;

type
  TRGB = record
    B, G, R: Byte;
  end;

  pRGB = ^TRGB;

var
  Dest: pRGB;
  x, y: Word;
  GT: array [0 .. 255] of Byte;

begin
  Bitmap.PixelFormat := pf24Bit;
  GT[0] := 0;
  if L = 0 then
    L := 0.01;
  for x := 1 to 255 do
    GT[x] := Round(255 * Power(x / 255, 1 / L));
  for y := 0 to Bitmap.Height - 1 do
  begin
    Dest := Bitmap.ScanLine[y];
    for x := 0 to Bitmap.Width - 1 do
    begin
      with Dest^ do
      begin
        R := GT[R];
        G := GT[G];
        B := GT[B];
      end;
      Inc(Dest);
    end;
  end;
end;

procedure ModColors(Bitmap: TBitmap; Color: TColor);

  function GetR(const Color: TColor): Byte;
  begin
    Result := Lo(Color);
  end;

  function GetG(const Color: TColor): Byte;
  begin
    Result := Lo(Color shr 8);
  end;

  function GetB(const Color: TColor): Byte;
  begin
    Result := Lo((Color shr 8) shr 8);
  end;

  function BLimit(B: Integer): Byte;
  begin
    if B < 0 then
      Result := 0
    else if B > 255 then
      Result := 255
    else
      Result := B;
  end;

type
  TRGB = record
    B, G, R: Byte;
  end;

  pRGB = ^TRGB;

var
  r1, g1, b1: Byte;
  x, y: Integer;
  Dest: pRGB;
  A: Double;

begin
  Bitmap.PixelFormat := pf24Bit;
  r1 := Round(255 / 100 * GetR(Color));
  g1 := Round(255 / 100 * GetG(Color));
  b1 := Round(255 / 100 * GetB(Color));
  for y := 0 to Bitmap.Height - 1 do
  begin
    Dest := Bitmap.ScanLine[y];
    for x := 0 to Bitmap.Width - 1 do
    begin
      with Dest^ do
      begin
        A := (R + B + G) / 300;
        with Dest^ do
        begin
          R := BLimit(Round(r1 * A));
          G := BLimit(Round(g1 * A));
          B := BLimit(Round(b1 * A));
        end;
      end;
      Inc(Dest);
    end;
  end;
end;

procedure ScaleBmp(Bitmap: TBitmap; CX, CY: Integer);
var
  TmpBmp: TBitmap;
  ARect: TRect;
begin
  TmpBmp := TBitmap.Create;
  try
    TmpBmp.Width := CX;
    TmpBmp.Height := CY;
    ARect := Rect(0, 0, CX, CY);
    TmpBmp.Canvas.StretchDraw(ARect, Bitmap);
    Bitmap.Assign(TmpBmp);
  finally
    TmpBmp.Free;
  end;
end;

procedure SplitImage(var Images: array of TBitmap; FileName: string;
  IsScale: Boolean; L: Integer = 0);
var
  B: TBitmap;
  I, J, CS: Integer;
begin
  if not IsScale then
    CS := CellSize
  else
    CS := 16;
  B := TBitmap.Create;
  try
    B.LoadFromFile(FileName);
    for J := 0 to (B.Height div CS) - 1 do
      for I := 0 to (B.Width div CS) - 1 do
        with Images[L] do
        begin
          Width := CS;
          Height := CS;
          PixelFormat := pf24Bit;
          Transparent := False;
          Canvas.CopyRect(Bounds(0, 0, CS, CS), B.Canvas,
            Bounds(I * CS, J * CS, CS, CS));
          if IsScale then
            ScaleBmp(Images[L], CellSize, CellSize);
          case L of
            bLeaves:
              ModColors(Images[L], clGreen);
          end;
          Inc(L);
        end;
  finally
    B.Free;
  end;
end;

end.
