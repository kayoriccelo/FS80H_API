unit FS80H;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.JSON,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdContext, IdCustomHTTPServer,
  Vcl.ExtCtrls, IdBaseComponent, IdComponent, IdCustomTCPServer, IdHTTPServer,
  Vcl.AppEvnts, IdServerIOHandler, IdSSL, IdSSLOpenSSL, Vcl.Menus, Comobj;

type
  TForm1 = class(TForm)
    IdHTTPServer1: TIdHTTPServer;
    TrayIcon1: TTrayIcon;
    IdServerIOHandlerSSLOpenSSL1: TIdServerIOHandlerSSLOpenSSL;
    PopupMenu1: TPopupMenu;
    Sair1: TMenuItem;
    ApplicationEvents1: TApplicationEvents;
    procedure IdHTTPServer1CommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure GetPassword(var Password: string);
    procedure Sair1Click(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure ApplicationEvents1Minimize(Sender: TObject);
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
    procedure HamsterDx_enroll;
    procedure HamsterDx_captura;
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

const
  NBioAPIERROR_NONE = 0;
  NBioAPI_FIR_PURPOSE_VERIFY = 1;
  // Constant for DeviceID
  NBioAPI_DEVICE_ID_NONE = 0;
  NBioAPI_DEVICE_ID_FDP02_0 = 1;
  NBioAPI_DEVICE_ID_FDU01_0 = 2;
  NBioAPI_DEVICE_ID_AUTO_DETECT = 255;

var
  Form1: TForm1;
  CriticalSection: TRTLCriticalSection;
  objNBioBSP: variant;
  objDevice: variant;
  objExtraction: variant;

implementation

{$R *.dfm}

procedure TForm1.GetPassword(var Password: string);
begin
  Password := '1234';
end;

procedure TForm1.ApplicationEvents1Minimize(Sender: TObject);
begin
  Self.Hide();
  Self.WindowState := wsMinimized;
  TrayIcon1.Visible := True;
  TrayIcon1.Animate := True;
  TrayIcon1.ShowBalloonHint;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  objNBioBSP := CreateOleObject('NBioBSPCOM.NBioBSP');
  objDevice := objNBioBSP.Device;
  objExtraction := objNBioBSP.Extraction;
  objNBioBSP.SetSkinResource('C:\Projetos\FS80H_API');

  IdServerIOHandlerSSLOpenSSL1.SSLOptions.CertFile := 'certificate.crt';
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.KeyFile := 'private.key';
  // IdServerIOHandlerSSLOpenSSL1.SSLOptions.RootCertFile := 'ca.cert.pem';
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.Mode := sslmServer;
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.VerifyMode := [];
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.VerifyDepth := 0;
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.SSLVersions := [sslvTLSv1_2]; // Avoid using SSL
  IdServerIOHandlerSSLOpenSSL1.OnGetPassword := GetPassword;
  // Ativar API
  IdHTTPServer1.Active := True;

  Self.Hide();
  Self.WindowState := wsMinimized;
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
  Cmd := ARequestInfo.URI;

//  http://localhost:9000/api/public/v1/captura/Enroll/1
//  api/public/v1/captura/Capturar/1

  try

    loJSONObject := TJsonObject.Create();

    if Cmd = '/' then
    begin
      Leitura := TLeitura.Create();
      Leitura.Execute;

      loJSONObject.AddPair(TJSONPair.Create('Digital', Leitura.Digital));

      AResponseInfo.ContentText := loJSONObject.ToString;
      AResponseInfo.WriteContent;
    end;

    if Cmd = '/api/public/v1/captura/Enroll/1' then
    begin
      Leitura := TLeitura.Create();
      Leitura.HamsterDx_enroll;

      loJSONObject.AddPair(TJSONPair.Create('Digital', Leitura.Digital));

      AResponseInfo.ContentText := loJSONObject.ToString;
      AResponseInfo.WriteContent;
    end;

    if Cmd = '/api/public/v1/captura/Capturar/1' then
    begin
      Leitura := TLeitura.Create();
      Leitura.HamsterDx_captura;

      loJSONObject.AddPair(TJSONPair.Create('Digital', Leitura.Digital));

      AResponseInfo.ContentText := loJSONObject.ToString;
      AResponseInfo.WriteContent;
    end;

  finally
    loJSONObject.Free;
  end;
end;

procedure TForm1.Sair1Click(Sender: TObject);
begin
  IdHTTPServer1.Active := False;
  Application.Terminate;
end;

procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
  TrayIcon1.Visible := False;
  Show();
  WindowState := wsNormal;
  Application.BringToFront();
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
    if I = (Length(Value) - 1) then
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
  if (intResposta = 1) then
    begin
      intResposta := CIS_SDK_Biometrico_LerDigital(@bAmostra);
      if (intResposta <> 1) then
      begin
        CIS_SDK_Biometrico_Finalizar;
        Exit;
      end
      else
      begin
        FDigital := ByteToString(bAmostra)
      end;

      intResposta := CIS_SDK_Biometrico_Finalizar;
    end;
end;

procedure TLeitura.HamsterDx_enroll;
var
  nUserID: integer;
begin
  // Get FIR data
  objDevice.Open(NBioAPI_DEVICE_ID_AUTO_DETECT);
  objNBioBSP.SetSkinResource ('.\NBSP2Por.dll');

  if objDevice.ErrorCode <> 0 Then
    ShowMessage('Falha ao abrir o sensor biom�trico !');

  // Registra um novo TEMPLATE
  objExtraction.Enroll(nUserID, 0);
  FDigital := objExtraction.TextEncodeFIR;
  if objExtraction.ErrorCode <> NBioAPIERROR_NONE Then
    ShowMessage('Registro falhou!');
  objDevice.Close(NBioAPI_DEVICE_ID_AUTO_DETECT);
end;

procedure TLeitura.HamsterDx_captura;
var
   str      : wideString;
begin
  // Abre o sensor
  objDevice.Open(NBioAPI_DEVICE_ID_AUTO_DETECT);
  if objDevice.ErrorCode <> NBioAPIERROR_NONE then
  begin
    str := objDevice.ErrorDescription;
    ShowMessage('Falha ao fazer a captura!');
    Exit;
  end;
  // Faz a captura
  objExtraction.Capture(NBioAPI_FIR_PURPOSE_VERIFY);
  if objExtraction.ErrorCode = NBioAPIERROR_NONE then
  begin
    // Fecha o sensor
    objDevice.Close(NBioAPI_DEVICE_ID_AUTO_DETECT);
    // szFir recebe o TEMPLATE
    self.FDigital := objExtraction.TextEncodeFIR;

  end
  else
    ShowMessage('Extraction failed !');
  // Fecha o sensor
  objDevice.Close(NBioAPI_DEVICE_ID_AUTO_DETECT);

end;

initialization

InitializeCriticalSection(CriticalSection);

finalization

DeleteCriticalSection(CriticalSection);

end.
