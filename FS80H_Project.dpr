program FS80H_Project;

uses
  Vcl.Forms,
  FS80H in 'FS80H.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
