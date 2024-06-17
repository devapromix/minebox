unit uMain;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  ExtCtrls;

type
  TfMain = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fMain: TfMain;

implementation

uses
  Stages,
  uVars,
  uGame,
  uRegions,
  Utils,
  uCraft;

{$R *.dfm}

procedure TfMain.FormCreate(Sender: TObject);
begin
  ClientWidth := ScreenWidth * CellSize;
  ClientHeight := ScreenHeight * CellSize;
  Game := TGame.Create;
  Game.Stages.SetStage(stGame);
end;

procedure TfMain.FormPaint(Sender: TObject);
begin
  Game.Stages.Render;
  Canvas.Draw(0, 0, Game.Graphic.BG);
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  Game.Free;
end;

procedure TfMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Game.Stages.Update(Key);
  FormPaint(Sender);
end;

procedure TfMain.FormMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  Game.MousePos := Point(X, Y);
  FormPaint(Sender);
end;

procedure TfMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Game.Stages.MouseDown(Button, X, Y);
  FormPaint(Sender);
end;

procedure TfMain.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  Game.Stages.MouseWheelDown;
  FormPaint(Sender);
end;

procedure TfMain.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  Game.Stages.MouseWheelUp;
  FormPaint(Sender);
end;

procedure TfMain.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Game.Stages.MouseUp;
  FormPaint(Sender);
end;

procedure TfMain.Timer1Timer(Sender: TObject);
begin
  Game.Stages.Timer;
  FormPaint(Sender);
end;

end.
