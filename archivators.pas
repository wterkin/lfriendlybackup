unit archivators;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, Buttons, DBGrids, Windows,
  tdb, tmsg,
  archiverEdit;

type

  { TfmArchivators }

  TfmArchivators = class(TForm)
    dbgArch: TDBGrid;
    dsArch: TDataSource;
    Panel1: TPanel;
    sbAppend: TSpeedButton;
    sbChange: TSpeedButton;
    sbClose: TSpeedButton;
    sbDelete: TSpeedButton;
    qrArch: TSQLQuery;
    qrArchEx: TSQLQuery;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var {%H-}CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure qrArchAfterScroll({%H-}DataSet: TDataSet);
    procedure sbAppendClick(Sender: TObject);
    procedure sbChangeClick(Sender: TObject);
    procedure sbCloseClick(Sender: TObject);
    procedure sbDeleteClick(Sender: TObject);
  private
    procedure reopenTables();
  public

  end;

const csSQLSelectArchivers =
        'select "id", "fname", "fextension", "fpackpath", "fpackoptions"'#13+
        '       , "funpackpath", "funpackoptions"'#13+
        '  from "tblarchivators"'#13+
        '  where "fstatus">0';

var
  fmArchivators: TfmArchivators;

implementation

uses main;

{$R *.lfm}


{ TfmArchivators }

procedure TfmArchivators.sbAppendClick(Sender: TObject);
begin

  fmArchivatorEdit.appendRecord();
  reopenTables();
end;


procedure TfmArchivators.qrArchAfterScroll(DataSet: TDataSet);
begin

  sbChange.Enabled:=qrArch.RecordCount>0;
  sbDelete.Enabled:=qrArch.RecordCount>0;
end;


procedure TfmArchivators.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin

  qrArch.Close;
end;


procedure TfmArchivators.FormActivate(Sender: TObject);
begin

  dbgArch.Update();
end;


procedure TfmArchivators.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

  if Key=vk_ESCAPE then
  begin

    Close;
	end;
end;


procedure TfmArchivators.FormShow(Sender: TObject);
begin

  reopenTables();
end;


procedure TfmArchivators.sbChangeClick(Sender: TObject);
begin

  fmArchivatorEdit.viewRecord();
  reopenTables();
end;


procedure TfmArchivators.sbCloseClick(Sender: TObject);
begin

  Close;
end;


procedure TfmArchivators.sbDeleteClick(Sender: TObject);
const csChkArchiverInUse = 'select count(*) as acount from tblprojects where (farchivator=:pid) and (fstatus>0)';
      csDeleteArchiver = 'update tblarchivators set fstatus=0 where id=:pid';
var liID    : Integer;
    liCount : Integer;
begin

  if askYesOrNo('Внимание! Вы действительно хотите удалить этот архиватор?') then
  begin

    try

      liID:=qrArch.FieldByName('id').AsInteger;
      initializeQuery(qrArchEx, csChkArchiverInUse);
      qrArchEx.ParamByName('pid').AsInteger:=liID;
      qrArchEx.Open;
      liCount:=qrArchEx.FieldByName('acount').AsInteger;
      qrArchEx.Close;

      if liCount=0 then
      begin

        initializeQuery(qrArchEx, csDeleteArchiver);
        qrArchEx.ParamByName('pid').AsInteger:=liID;
        qrArchEx.ExecSQL;
        fmMain.Transact.Commit;
      end else
      begin

        FatalError('Ошибка!','Невозможно удалить архиватор, пока он используется в задаче.');
      end;
    except

      fmMain.Transact.Rollback;
      FatalError('Error!','Database request failed!');
    end;
  end;
  reopenTables();
end;


procedure TfmArchivators.reopenTables;
begin

  try

    if qrArch.State<>dsInactive then
    begin

      qrArch.Close;
		end;
		initializeQuery(qrArch,csSQLSelectArchivers);
    qrArch.Open;
    qrArchAfterScroll(Nil);
  except

    FatalError('Error!','Database request failed!');
  end;
end;


end.

