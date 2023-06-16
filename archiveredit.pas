unit archiverEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons, db,
  tdb, tmsg
  ;

type

  { TfmArchivatorEdit }

  TfmArchivatorEdit = class(TForm)
    bbtOk: TBitBtn;
    bbtCancel: TBitBtn;
    edName: TEdit;
    edExtension: TEdit;
    edUnpackOptions: TEdit;
    edPackPath: TEdit;
    edPackOptions: TEdit;
    edUnpackPath: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    OpenDlg: TOpenDialog;
    Panel1: TPanel;
    sbPackPath: TSpeedButton;
    qrArchEx: TSQLQuery;
    sbUnpackPath: TSpeedButton;
    procedure bbtOkClick(Sender: TObject);
    procedure sbPackPathClick(Sender: TObject);
    procedure sbUnpackPathClick(Sender: TObject);
  private

    moMode : TDBMode;
    miID   : Integer;

    procedure initData();
    procedure storeData();
    procedure loadData();
    function  validateData() : Boolean;
  public

    procedure viewRecord();
    procedure appendRecord();
  end;

const csSQLInsertArchivator =
        'insert into tblarchivators ('#13+
        '    fname,'#13+
        '    fextension,'#13+
        '    fpackpath,'#13+
        '    fpackoptions,'#13+
        '    funpackpath,'#13+
        '    funpackoptions,'#13+
        '    fstatus'#13+
        '  ) values ('#13+
        '    :pname,'#13+
        '    :pextension,'#13+
        '    :ppackpath,'#13+
        '    :ppackoptions,'#13+
        '    :punpackpath,'#13+
        '    :punpackoptions,'#13+
        '    1'#13+
        '  );';

      csSQLUpdateArchivator =
         'update tblarchivators '#13+
         '  set fname=:pname,'#13+
         '      fextension=:pextension,'#13+
         '      fpackpath=:ppackpath,'#13+
         '      fpackoptions=:ppackoptions,'#13+
         '      funpackpath=:punpackpath,'#13+
         '      funpackoptions=:punpackoptions'#13+
         '  where id=:pid';

var
  fmArchivatorEdit: TfmArchivatorEdit;

implementation

{$R *.lfm}

uses Main,archivators;

{ TfmArchivatorEdit }

procedure TfmArchivatorEdit.bbtOkClick(Sender: TObject);
begin

  if ValidateData() then
  begin

    try

      MainForm.Transact.EndTransaction;
      MainForm.Transact.StartTransaction;

      //***** Зажигаем! Let's rock!
      if moMode=dmInsert then
      begin

        initializeQuery(qrArchEx,csSQLInsertArchivator,False);
      end
      else
      begin

        initializeQuery(qrArchEx,csSQLUpdateArchivator,False);
      end;
      StoreData();
      qrArchEx.ExecSQL;
      MainForm.Transact.Commit;
    except

      MainForm.Transact.Rollback;
      FatalError('Error!','Database request failed!');
    end;
    ModalResult:=mrOk;
  end
end;


procedure TfmArchivatorEdit.sbPackPathClick(Sender: TObject);
begin

  if OpenDlg.Execute then
  begin

    edPackPath.Text:=OpenDlg.FileName;
	end;
end;


procedure TfmArchivatorEdit.sbUnpackPathClick(Sender: TObject);
begin

  if OpenDlg.Execute then
  begin

    edUnpackPath.Text:=OpenDlg.FileName;
	end;
end;


procedure TfmArchivatorEdit.initData;
begin

  edName.Text:='';
  edExtension.Text:='';
  edPackPath.Text:='';
  edPackOptions.Text:='';
  edUnpackPath.Text:='';
  edUnpackOptions.Text:='';
end;


procedure TfmArchivatorEdit.storeData;
begin

  qrArchEx.ParamByName('pname').AsString:=edName.Text;
  qrArchEx.ParamByName('pextension').AsString:=edExtension.Text;
  if Pos(#32,edPackPath.Text)>0 then
  begin

    qrArchEx.ParamByName('ppackpath').AsString:='"'+edPackPath.Text+'"'
	end else
  begin

    qrArchEx.ParamByName('ppackpath').AsString:=edPackPath.Text;
	end;
	qrArchEx.ParamByName('ppackoptions').AsString:=edPackOptions.Text;
  qrArchEx.ParamByName('punpackpath').AsString:=edUnpackPath.Text;
  qrArchEx.ParamByName('punpackoptions').AsString:=edUnpackOptions.Text;
  if moMode=dmUpdate then
  begin

    qrArchEx.ParamByName('pid').AsInteger:=miID;
	end;
end;


procedure TfmArchivatorEdit.loadData;
begin

  edName.Text:=fmArchivators.qrArch.FieldByName('fname').AsString;
  edExtension.Text:=fmArchivators.qrArch.FieldByName('fextension').AsString;
  edPackPath.Text:=fmArchivators.qrArch.FieldByName('fpackpath').AsString;
  edPackOptions.Text:=fmArchivators.qrArch.FieldByName('fpackoptions').AsString;
  edUnpackPath.Text:=fmArchivators.qrArch.FieldByName('fpackpath').AsString;
  edUnpackOptions.Text:=fmArchivators.qrArch.FieldByName('funpackoptions').AsString;
  miID:=fmArchivators.qrArch.FieldByName('id').AsInteger;
end;


function TfmArchivatorEdit.validateData: Boolean;
begin

  Result:=True;
end;


procedure TfmArchivatorEdit.viewRecord;
begin

  loadData();
  moMode:=dmUpdate;
  ShowModal;
end;


procedure TfmArchivatorEdit.appendRecord;
begin

  initData();
  moMode:=dmInsert;
  ShowModal;
end;


end.

