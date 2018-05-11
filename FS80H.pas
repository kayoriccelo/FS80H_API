unit FS80H;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.JSON,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdContext, IdCustomHTTPServer,
  Vcl.ExtCtrls, IdBaseComponent, IdComponent, IdCustomTCPServer, IdHTTPServer,
  Vcl.AppEvnts;

type
  TForm1 = class(TForm)
    IdHTTPServer1: TIdHTTPServer;
    TrayIcon1: TTrayIcon;
    procedure IdHTTPServer1CommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TByteArraySize668 = array [0 .. 668] of Byte;

type
  TLeitura = class
  private
    FDigital: String;

  public
    property Digital: String read FDigital write FDigital;
    
    function ByteToString(const Value: TByteArraySize668): String;
    procedure Execute;
  end;

  { Cabeçalho das Funções }
function CIS_SDK_Biometrico_Iniciar: integer; stdcall; external 'CIS_SDK.dll';
function CIS_SDK_Biometrico_Finalizar: integer; stdcall; external 'CIS_SDK.dll';
function CIS_SDK_Biometrico_LerDigital(pTemplate: Pointer): integer; stdcall; external 'CIS_SDK.dll';
function CIS_SDK_Biometrico_LerWSQ(var iRetorno, iSize: integer): Pointer; stdcall; external 'CIS_SDK.dll';
function CIS_SDK_Biometrico_LerDigitalComImagem(pTemplate: Pointer; var sTemplate: integer; pImagem: Pointer; var sImagem: integer;
  intFundoBranco: integer; intTipoImagem: integer): integer; stdcall; external 'CIS_SDK.dll';
function CIS_SDK_Biometrico_CancelarLeitura: integer; stdcall; external 'CIS_SDK.dll';
function CIS_SDK_Biometrico_CompararDigital(pAmostra1, pAmostra2: Pointer): integer; stdcall; external 'CIS_SDK.dll';

function CIS_SDK_Versao: PAnsiChar; stdcall; external 'CIS_SDK.dll';
function CIS_SDK_Retorno(intRetorno: integer): PAnsiChar; stdcall; external 'CIS_SDK.dll';

var
  Form1: TForm1;
  CriticalSection: TRTLCriticalSection;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Ativar API
  IdHTTPServer1.Active := True;

  self.Hide();
  self.WindowState := wsMinimized;
  TrayIcon1.Visible := True;
  TrayIcon1.Animate := True;
  TrayIcon1.ShowBalloonHint;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  // Desativar API
  IdHTTPServer1.Active := False;
end;

procedure TForm1.IdHTTPServer1CommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
Var
  Cmd: String;
  JSONStr: string;
  Leitura: TLeitura;
  loJSONObject: TJsonObject;
begin
  Cmd := ARequestInfo.RawHTTPCommand;

  try

    loJSONObject := TJsonObject.Create();

    if Cmd = 'GET / HTTP/1.1' then
    begin
      Leitura := TLeitura.Create();
      Leitura.Execute;

      loJSONObject.AddPair(TJSONPair.Create('Digital', Leitura.Digital));

      AResponseInfo.ContentText := loJSONObject.ToString;
      AResponseInfo.WriteContent;
    end;

  finally
    loJSONObject.Free;
  end;
end;

{ TLeitura }

function TLeitura.ByteToString(const Value: TByteArraySize668): String;
var

  I: integer;

  S: String;

  Letra: char;

begin

  S := '';

  for I := 0 to Length(Value) - 1 do
  begin
    if i = (Length(Value) - 1) then
      S := S + VarToStr(Byte(Value[I]))
    else
      S := S + IntToStr(Value[I]) + ',';
  end;

  Result := S;

end;

procedure TLeitura.Execute;
var
  intResposta: integer;
  bAmostra: TByteArraySize668;
  MS: TMemoryStream;
  strDiretorio: string;
begin
  intResposta := CIS_SDK_Biometrico_Iniciar;
  if (intResposta <> 1) then
  begin
    // ShowMessage('Retorno: ' + IntToStr(intResposta) + #13#10 + CIS_SDK_Retorno(intResposta));
    Exit;
  end;

  intResposta := CIS_SDK_Biometrico_LerDigital(@bAmostra);
  if (intResposta <> 1) then
  begin
    CIS_SDK_Biometrico_Finalizar;

    // ShowMessage('Retorno: ' + IntToStr(intResposta) + #13#10 + CIS_SDK_Retorno(intResposta));
    Exit;
  end
  else
  begin
    FDigital :=  ByteToString(bAmostra)
    
    // ShowMessage('Retorno: ' + IntToStr(intResposta) + #13#10 + CIS_SDK_Retorno(intResposta));
  end;

  intResposta := CIS_SDK_Biometrico_Finalizar;
  // if (intResposta <> 1) then
  // ShowMessage('Retorno: ' + IntToStr(intResposta) + #13#10 + CIS_SDK_Retorno(intResposta));
end;

initialization

InitializeCriticalSection(CriticalSection);

finalization

DeleteCriticalSection(CriticalSection);

end.
