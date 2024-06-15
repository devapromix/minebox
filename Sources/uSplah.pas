unit uSplah;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls;

type
  TfSplash = class(TForm)
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fSplash: TfSplash;

implementation

{$R *.dfm}

procedure TfSplash.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := false;
end;

end.
