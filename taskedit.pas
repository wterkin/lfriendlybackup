unit taskedit;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, LazUTF8,
	Dialogs, ExtCtrls, StdCtrls, Buttons, ComCtrls, ActnList, DateUtils, StrUtils,
	sqldb, formathelp, tdb, tstr, tlookup, tmsg
  ;

type

  { TfmTaskEdit }
  TfmTaskEdit = class(TForm)
	  actHelpFormat: TAction;
		actTryFormat: TAction;
		actSelectAfterBackup: TAction;
		actSelectBeforeBackup: TAction;
		actSelectTarget: TAction;
		actSelectSource: TAction;
		ActionList: TActionList;
    bbtCancel: TBitBtn;
    bbtOk: TBitBtn;
    cbArchivator: TComboBox;
    cbPeriod: TComboBox;
    cbWeekDay: TComboBox;
		cbSubject: TComboBox;
    edArchivatorOptions: TEdit;
    edMonth: TEdit;
		edDay: TEdit;
    edMinute: TEdit;
		edHour: TEdit;
    edName: TEdit;
		edRunAfterBackup: TEdit;
		edSource: TEdit;
    edTargetFormat: TEdit;
    edTargetFolder: TEdit;
    edRunBeforeBackup: TEdit;
		ImageList: TImageList;
    Label1: TLabel;
		Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
		Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
		Label16: TLabel;
		Label17: TLabel;
		Label18: TLabel;
		lblSource: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    OpenDialog: TOpenDialog;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    dlgSelectDirectory: TSelectDirectoryDialog;
    sbBeforeBackupFile1: TSpeedButton;
    sbBeforeBackupFile: TSpeedButton;
		sbSelectSource: TSpeedButton;
		sbAfterBackupFile: TSpeedButton;
    sbTryFormat: TSpeedButton;
    sbSelectTarget: TSpeedButton;
    sbTargetFileFormatHelp: TSpeedButton;
    qrArchivators: TSQLQuery;
    qrTasksEx: TSQLQuery;
		trArchivators: TSQLTransaction;
		trTaskEx: TSQLTransaction;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    udMonth: TUpDown;
		udDay: TUpDown;
    udMinute: TUpDown;
		udHour: TUpDown;
		procedure actHelpFormatExecute(Sender: TObject);
    procedure actSelectAfterBackupExecute(Sender: TObject);
    procedure actSelectBeforeBackupExecute(Sender: TObject);
    procedure actSelectSourceExecute(Sender: TObject);
		procedure actSelectTargetExecute(Sender: TObject);
		procedure actTryFormatExecute(Sender: TObject);
    procedure bbtOkClick(Sender: TObject);
    procedure cbPeriodChange(Sender: TObject);
		procedure cbSubjectChange(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
  private
    { private declarations }
    moMode : TDBMode;
    miID   : Integer;
    miArchivatorId : Integer;
    moArchLookup       : TEasyLookupCombo;
    procedure initData();
    procedure storeData();
    procedure loadData();
    function  validateData() : Boolean;
  public
    { public declarations }
    procedure viewRecord();
    procedure appendRecord();
  end;

  {$H+}
const csSQLInsertTask =
        'insert into tbltasks ('#13+
        '      id, fname, fsourcefolder, ftargetfolder'#13+
        '    , ftargetfile, farchivator, farchivatoroptions, fperiod'#13+
        '    , ftime, fdayofweek, fdate'#13+
        '    , flastrundate, flastrunresult, frunbeforebackup, frunafterbackup'#13+
        '    , fstatus'#13+
        '  ) values ('#13+
        '      :pid, :pname, :psourcefolder, :ptargetfolder'#13+
        '    , :ptargetfile, :parchivator, :parchivatoroptions, :pperiod'#13+
        '    , :ptime, :pdayofweek, :pdate'#13+
        '    , :plastrundate, :plastrunresult, :prunbeforebackup, :prunafterbackup, 1'#13+
        '  );';

      csSQLUpdateTask =
        'update tbltasks'#13+
        '   set fname=:pname,'#13+
        '       fsourcefolder=:psourcefolder,'#13+
        '       ftargetfolder=:ptargetfolder,'#13+
        '       ftargetfile=:ptargetfile,'#13+
        '       farchivator=:parchivator,'#13+
        '       farchivatoroptions=:parchivatoroptions,'#13+
        '       fperiod=:pperiod,'#13+
        '       ftime=:ptime,'#13+
        '       fdayofweek=:pdayofweek,'#13+
        '       fdate=:pdate,'#13+
        '       frunbeforebackup=:prunbeforebackup,'#13+
        '       frunafterbackup=:prunafterbackup'#13+
        ' where id=:pid';



var
  fmTaskEdit: TfmTaskEdit;

implementation

uses main;

{$R *.lfm}

{ TfmTaskEdit }

procedure TfmTaskEdit.cbPeriodChange(Sender: TObject);
begin

  case cbPeriod.ItemIndex of

    // *** Каждую минуту
    ciPeriodEachMinute: begin

      edMinute.Enabled := False;
      edHour.Enabled := False;
      cbWeekDay.Enabled := False;
      edDay.Enabled := False;
      edMonth.Enabled := False;
    end;

    // *** Каждый час
    ciPeriodEachHour: begin

      edMinute.Enabled := True;
      edHour.Enabled := False;
      cbWeekDay.Enabled := False;
      edDay.Enabled := False;
      edMonth.Enabled := False;
    end;

    //***** Ежедневно
    ciPeriodEachDay: begin

      edMinute.Enabled := True;
      edHour.Enabled := True;
      cbWeekDay.Enabled := False;
      edDay.Enabled := False;
      edMonth.Enabled := False;
    end;

    //***** Еженедельно
    ciPeriodEachWeek: begin

      edMinute.Enabled := True;
      edHour.Enabled := True;
      cbWeekDay.Enabled := True;
      edDay.Enabled := False;
      edMonth.Enabled := False;
    end;

    //***** Ежемесячно
    ciPeriodEachMonth: begin

      edMinute.Enabled := True;
      edHour.Enabled := True;
      cbWeekDay.Enabled := False;
      edDay.Enabled := True;
      edMonth.Enabled := False;
    end;

    //***** Ежегодно
    ciPeriodEachYear: begin

      edMinute.Enabled := True;
      edHour.Enabled := True;
      cbWeekDay.Enabled := False;
      edDay.Enabled := True;
      edMonth.Enabled := True;
    end;
  end;
end;


procedure TfmTaskEdit.cbSubjectChange(Sender: TObject);
begin

  // *** В зависимости от выбора
  if cbSubject.ItemIndex = 0 then
  begin

    lblSource.Caption := 'Исходный каталог:';
  end else
  begin

    lblSource.Caption := 'Исходный файл:';
	end;
end;


procedure TfmTaskEdit.FormCreate(Sender: TObject);
begin

  inherited;
  moArchLookup := TEasyLookupCombo.Create();
  moArchLookup.setComboBox(cbArchivator);
  moArchLookup.setQuery(qrArchivators);
  moArchLookup.setSQL('select * from tblarchivators where fstatus>0');
  moArchLookup.setKeyField('id');
  moArchLookup.setListField('fname');
  qrTasksEx.Transaction := trTaskEx;
  qrArchivators.Transaction := trArchivators;
end;


procedure TfmTaskEdit.FormDestroy(Sender: TObject);
begin

  FreeAndNil(moArchLookup);
end;


procedure TfmTaskEdit.bbtOkClick(Sender: TObject);
var lsMessage : String;
begin

  if ValidateData() then
  begin

    try

      //***** Зажигаем! Let's rock!
      if moMode = dmInsert then
      begin

        lsMessage := 'Создание';
        initializeQuery(qrTasksEx, csSQLInsertTask, False);
      end
      else
      begin

        lsMessage := 'Изменение';
        initializeQuery(qrTasksEx, csSQLUpdateTask, False);
      end;
      StoreData();
      qrTasksEx.ExecSQL();
      trTaskEx.Commit();
    except
      on E : Exception do
      begin

        trTaskEx.Rollback;
        MainForm.processException(lsMessage + ' задачи привело к исключительной ситуации: ', E);
		  end;
    end;
    ModalResult := mrOk;
  end
end;


procedure TfmTaskEdit.actSelectSourceExecute(Sender: TObject);
begin

  if cbSubject.ItemIndex = 0 then
  begin

    if dlgSelectDirectory.Execute then
    begin

      edSource.Text := addSeparator(dlgSelectDirectory.FileName);
		end;
	end else
  begin

    if OpenDialog.Execute then
    begin

      edSource.Text := OpenDialog.FileName;
		end;
	end;
end;


procedure TfmTaskEdit.actSelectBeforeBackupExecute(Sender: TObject);
begin

  if OpenDialog.Execute then
  begin

    edRunBeforeBackup.Text := OpenDialog.FileName;
	end;
end;


procedure TfmTaskEdit.actSelectAfterBackupExecute(Sender: TObject);
begin

  if OpenDialog.Execute then
  begin

    edRunAfterBackup.Text := OpenDialog.FileName;
	end;
end;


procedure TfmTaskEdit.actHelpFormatExecute(Sender: TObject);
begin

  fmFormatHelp.Show;
end;


procedure TfmTaskEdit.actSelectTargetExecute(Sender: TObject);
begin

  if dlgSelectDirectory.Execute then
  begin

    edTargetFolder.Text := dlgSelectDirectory.FileName;
	end;
end;


procedure TfmTaskEdit.actTryFormatExecute(Sender: TObject);
var s : string;
begin

  s := edTargetFormat.Text;
  s := ReplaceStr(s, '`', '"');
  s := FormatDateTime(s, Now, MyOwnFormatSettings);
  Notify('', FormatDateTime(ReplaceStr( edTargetFormat.Text, '`', '"'), Now, MyOwnFormatSettings));
end;


procedure TfmTaskEdit.initData();
begin

  edName.Text := '';
  edSource.Text := '';
  edTargetFolder.Text := '';
  edTargetFormat.Text := '`Name-`yyyy-mm-dd_hh-nn-ss';
  edArchivatorOptions.Text := '';
  cbPeriod.ItemIndex := 0;
  udMinute.Position := MinuteOf(Now);
  udHour.Position := HourOf(Now);
  cbWeekDay.ItemIndex := fmMain.RusDayOfWeek(Now)-1;
  udDay.Position := DayOf(Now);
  udMonth.Position := MonthOf(Now);
  edRunBeforeBackup.Text := '';
  edRunAfterBackup.Text := '';
  moArchLookup.fill();
end;


procedure TfmTaskEdit.storeData();
var lsTime, lsDate : String;
begin

  lsTime := '';
  lsDate := '';
  qrTasksEx.ParamByName('pname').AsString := edName.Text;
	qrTasksEx.ParamByName('psourcefolder').AsString := edSource.Text;
  // Вот тут проверить, что edSource не пустой. а вообще в Validate проверять всё.
  if (cbSubject.ItemIndex = 0) and (edSource.Text[UTF8Length(edSource.Text)] <> DirectorySeparator) then
  begin

  	qrTasksEx.ParamByName('psourcefolder').AsString := addSeparator(edSource.Text);
	end;
  qrTasksEx.ParamByName('ptargetfolder').AsString := edTargetFolder.Text;
  qrTasksEx.ParamByName('ptargetfile').AsString := edTargetFormat.Text;
  qrTasksEx.ParamByName('parchivator').AsInteger := moArchLookup.getIntKey();
  qrTasksEx.ParamByName('parchivatoroptions').AsString := edArchivatorOptions.Text;
  qrTasksEx.ParamByName('pperiod').AsInteger := cbPeriod.ItemIndex;
  if edHour.Enabled then
  begin

    lsTime := AlignRight(IntToStr(udHour.Position), 2, '0');
  end else
  begin

    lsTime := '00';
	end;
  if edMinute.Enabled then
  begin

    lsTime := lsTime + ':' + AlignRight(IntToStr(udMinute.Position), 2, '0');
  end else
  begin

    lsTime := lsTime+ ':00';
	end;
  if edDay.Enabled then
  begin

    lsDate := AlignRight(IntToStr(udDay.Position), 2, '0');
  end else
  begin

    lsDate := '00';
	end;
  if edMonth.Enabled then
  begin

    lsDate := lsDate + '.' + AlignRight(IntToStr(udMonth.Position), 2, '0');
  end else
  begin

    lsDate := lsDate + '.00'
	end;
  qrTasksEx.ParamByName('ptime').AsString := lsTime;
  qrTasksEx.ParamByName('pdate').AsString := lsDate;
  if cbWeekDay.Enabled then
  begin

    qrTasksEx.ParamByName('pdayofweek').AsInteger := cbWeekDay.ItemIndex+1;
  end else
  begin

    qrTasksEx.ParamByName('pdayofweek').AsInteger := 0;
	end;
  qrTasksEx.ParamByName('prunbeforebackup').AsString := edRunBeforeBackup.Text;
  qrTasksEx.ParamByName('prunafterbackup').AsString := edRunBeforeBackup.Text;
  if moMode = dmUpdate then
  begin

    qrTasksEx.ParamByName('pid').AsInteger := miID;
  end;
end;


procedure TfmTaskEdit.loadData();
begin
  {
  edName.Text := MainForm.moTasks.StringField('fname');
  edSource.Text := MainForm.moTasks.StringField('fsourcefolder');

  cbSubject.ItemIndex:=0;
  if (Length(edSource.Text) > 0) and
     (edSource.Text[UTF8Length(edSource.Text)] <> DirectorySeparator) then
  begin

    cbSubject.ItemIndex := 1;
  end
  else
  begin

    cbSubject.ItemIndex := 0;
  end;
  edTargetFolder.Text := MainForm.moTasks.StringField('ftargetfolder');
  edTargetFormat.Text := MainForm.moTasks.StringField('ftargetfile');
  edArchivatorOptions.Text := MainForm.moTasks.StringField('farchivatoroptions');
  cbPeriod.ItemIndex := MainForm.moTasks.IntegerField('fperiod');

  edMinute.Enabled := False;
  edHour.Enabled := False;
  cbWeekDay.Enabled := False;
  edDay.Enabled := False;
  edMonth.Enabled := False;
  case cbPeriod.ItemIndex of

    ciPeriodEachMinute: begin

    end;
    ciPeriodEachHour: begin

      edMinute.Enabled := True;
      udMinute.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('ftime'), 4, 2), 0);
    end;
    ciPeriodEachDay: begin

      edMinute.Enabled := True;
      udMinute.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('ftime'), 4, 2), 0);
      edHour.Enabled := True;
      udHour.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('ftime'), 1, 2), 0);
    end;
    ciPeriodEachWeek: begin

      edMinute.Enabled := True;
      udMinute.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('ftime'), 4, 2), 0);
      edHour.Enabled:=True;
      udHour.Position:=StrToIntDef(Copy(MainForm.moTasks.StringField('ftime'), 1, 2), 0);
      cbWeekDay.ItemIndex:=MainForm.moTasks.IntegerField('fdayofweek')-1;
    end;
    ciPeriodEachMonth:begin

      edMinute.Enabled := True;
      udMinute.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('ftime'), 4, 2), 0);
      edHour.Enabled := True;
      udHour.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('ftime'), 1, 2), 0);
      edDay.Enabled := True;
      udDay.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('fdate'), 1, 2), 0);
    end;
    ciPeriodEachYear:begin

      edMinute.Enabled := True;
      udMinute.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('ftime'), 4, 2), 0);
      edHour.Enabled := True;
      udHour.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('ftime'), 1, 2), 0);
      edDay.Enabled := True;
      udDay.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('fdate'), 1, 2), 0);
      edMonth.Enabled := True;
      udMonth.Position := StrToIntDef(Copy(MainForm.moTasks.StringField('fdate'), 4, 2), 0);
    end;
  end;
  edRunBeforeBackup.Text := MainForm.moTasks.StringField('frunafterbackup');

  MainForm.moTasks.store();
  moArchLookup.fill();
  moArchLookup.setKey(miArchivatorId);
  MainForm.moTasks.Refresh();
  }
end;


function TfmTaskEdit.validateData(): Boolean;
begin

  Result := not isEmpty(edName.Text) and
            not isEmpty(edSource.Text) and
            not isEmpty(edSource.Text) and
            (cbArchivator.ItemIndex >= 0);
  if not Result then
  begin

    notify('Необходимо заполнить поле "Наименование задачи", ',
           ' исходный и целевой каталог и выбрать архиватор.');
	end;
end;


procedure TfmTaskEdit.viewRecord();
begin

  moMode := dmUpdate;
  // !!! miID:=MainForm.moTasks.IntegerField('ataskid');
  // !!! miArchivatorID:=MainForm.moTasks.IntegerField('farchivator');
  loadData();
  cbPeriodChange(nil);
  ShowModal;
end;


procedure TfmTaskEdit.appendRecord();
begin

  moMode := dmInsert;
  initData();
  cbPeriodChange(nil);
  ShowModal;
end;


end.

