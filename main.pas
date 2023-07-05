unit main;


interface
{$mode objfpc}
{$H+}
uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
	Buttons, DBGrids, ComCtrls, sqlite3conn, sqldb, IBConnection, db, windows,
	Grids, StdCtrls, Menus, ActnList, DateUtils, StrUtils, DateTimePicker, tlib,
	tdb, tstr, tparams, tlog, tini, tapp, tmsg, archivators, taskedit;

type

  TTaskInfo = record

    miID : Integer;
    msName : String;
    miPeriod,
    miMinute,
    miDayOfWeek,
    miDayOfMonth : Integer;
    mdtDate : TDate;
    mtTime  : TTime;
    msPackPath : String[255];
    msPackOptions : String[128];
    msArchivatorOptions : String;
    msTargetFile : String;
    msTargetFolder : String;
    msExtension : String[8];
    msSourceFile : String;
    msSourceFolder : String;
    msRunBeforeBackup : String;
    msRunAfterBackup : String;
  end;

  { TfmMain }

  TfmMain = class(TForm)
		actCreateTask: TAction;
		actEditTask: TAction;
		actActivateTask: TAction;
		actDeleteTask: TAction;
		actQuit: TAction;
		actRunTask: TAction;
		actStart: TAction;
		ActionList: TActionList;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Button1: TButton;
    dbgTasks: TDBGrid;
    dsTasks: TDataSource;
		IBC: TIBConnection;
		ImageList: TImageList;
    miDeactivate: TMenuItem;
    miActivate: TMenuItem;
    Panel1: TPanel;
    pmState: TPopupMenu;
    sbArchivers: TSpeedButton;
    sbCreateTask: TSpeedButton;
    sbChange: TSpeedButton;
    sbRunTask: TSpeedButton;
    sbActivate: TSpeedButton;
    sbStart: TSpeedButton;
    sbDelete: TSpeedButton;
    sbClose: TSpeedButton;
    qrTasks: TSQLQuery;
    qrTaskEx: TSQLQuery;
		scrCreate: TSQLScript;
		qrTaskExecute: TSQLQuery;
		trTaskExecute: TSQLTransaction;
		trCreate: TSQLTransaction;
		trTaskEx: TSQLTransaction;
		trTasks: TSQLTransaction;
    StatusBar1: TStatusBar;
    Timer: TTimer;
    TrayIcon: TTrayIcon;
		procedure actActivateTaskExecute(Sender: TObject);
    procedure actCreateTaskExecute(Sender: TObject);
	  procedure actDeleteTaskExecute(Sender: TObject);
		procedure actEditTaskExecute(Sender: TObject);
	  procedure actQuitExecute(Sender: TObject);
		procedure actRunTaskExecute(Sender: TObject);
    procedure actStartExecute(Sender: TObject);
    procedure dbgTasksDblClick(Sender: TObject);
    procedure dbgTasksPrepareCanvas({%H-}sender: TObject; {%H-}DataCol: Integer;
      {%H-}Column: TColumn; {%H-}AState: TGridDrawState);
    procedure FormClose(Sender: TObject; var {%H-}CloseAction: TCloseAction);
		procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure FormWindowStateChange(Sender: TObject);
    procedure qrTasksAfterScroll({%H-}DataSet: TDataSet);
    procedure sbArchiversClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
  private

    moLog : TEasyLog;
    procedure createDatabaseIfNeeded();
    procedure analizeCmdLine();
    procedure processTask();
    procedure refreshRunningFile();
  public

    procedure reopenTables();
    function RusDayOfWeek(pdtDate : TDateTime = NullDate) : Integer;
    procedure processError(psDesc, psDetail : String);
    procedure processException(psDetail : String; poException : Exception);
  end;


  TTaskInfoArray = array of TTaskInfo;

const
      {$region 'SQL'}
      csSQLSelectTasks =
        'select TASK.id as ataskid,'#13+
        '               TASK.fname,'#13+
        '               TASK.fsourcefolder,'#13+
        '               TASK.ftargetfolder,'#13+
        '               TASK.ftargetfile,'#13+
        '               TASK.farchivator,'#13+
        '               TASK.farchivatoroptions,'#13+
        '               TASK.fperiod,'#13+
        '               TASK.ftime,'#13+
        '               TASK.fdayofweek,'#13+
        '               TASK.fdate,'#13+
        '               TASK.frunbeforebackup,'#13+
        '               TASK.frunafterbackup,'#13+
        '               TASK.flastrundate,'#13+
        '               TASK.flastrunresult,'#13+
        '               TASK.fstatus,'#13+
        '               ARC.fname,'#13+
        '               ARC.fextension,'#13+
        '               ARC.fpackpath,'#13+
        '               ARC.fpackoptions,'#13+
        '               case TASK.fstatus when 2 then cast(''Активна'' as varchar(12)) else cast(''Неактивна'' as varchar(16)) end as astatus'#13+
        '          from tbltasks TASK'#13+
        '          inner join tblarchivators ARC'#13+
        '            on ARC.id=TASK.farchivator'#13+
        '          where (TASK.fstatus >= :pstatus) and'#13+
        '                (ARC.fstatus > 0)';
        {$endregion}

      csDatabaseFileName         = 'lfriendlybackup.fdb';
      csMainFormCaption          = 'Your friendly backup maker %s %s';
      csRunCmd                   = 'r';

      ciStatusDeleted            = 0;
      ciStatusInactive           = 1;
      ciStatusActive             = 2;

      clColorTaskActiveBkg       = clWindow;
      clColorTaskInActiveBkg     = $00D0D8E0;

      ciLastRunUnSuccessful      = 0;
      ciLastRunSuccessful        = 1;

      clColorLastRunUnSuccessful = $8F305B; // красный
      clColorLastRunSuccessful   = $224F15; //7DA035; // зеленый

      ciPeriodEachMinute         = 0;
      ciPeriodEachHour           = 1;
      ciPeriodEachDay            = 2;
      ciPeriodEachWeek           = 3;
      ciPeriodEachMonth          = 4;
      ciPeriodEachYear           = 5;

      {$Region 'Format'}
      MyOwnFormatSettings : TFormatSettings = (
        CurrencyFormat    : 1;
        NegCurrFormat     : 5;
        ThousandSeparator : ',';
        DecimalSeparator  : '.';
        CurrencyDecimals  : 2;
        DateSeparator     : '-';
        TimeSeparator     : ':';
        ListSeparator     : ',';
        CurrencyString    : '$';
        ShortDateFormat   : 'd/m/y';
        LongDateFormat    : 'dd" "mmmm" "yyyy';
        TimeAMString      : 'AM';
        TimePMString      : 'PM';
        ShortTimeFormat   : 'hh:nn';
        LongTimeFormat    : 'hh:nn:ss';
        ShortMonthNames   : ('Jan','Feb','Mar','Apr','May','Jun',
                             'Jul','Aug','Sep','Oct','Nov','Dec');
        LongMonthNames    : ('January','February','March','April','May','June',
                             'July','August','September','October','November','December');
        ShortDayNames     : ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
        LongDayNames      : ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
        TwoDigitYearCenturyWindow: 50;
      );
      {$Endregion}
      csTimeStampMask    = 'yyyy/mm/dd hh:mm';
      csControlChar      = '.';
      csQuitFile         = csControlChar+'quit';
      csRunningFile      = csControlChar+'iamrunning';
      csIniFile          = 'lfriendlybackup.ini';
      csVersion          = 'ver. 2.0.1';
      ciIconStart        = 6;
      ciIconStop         = 7;
      ciIconDeactivate   = 9;
      ciIconActivate     = 10;
      csLogsFolder       = 'logs/';
      csDLLFolder        = 'DLL/';
      csFireBirdUser     = 'SYSDBA';
      csFireBirdPassword = 'masterkey';
      csFireBirdCharSet  = 'utf8';
      ciFireBirdDialect  = 3;
      csFireBirdPageSize = '16384';
      {$define __DEBUG__}
var
  fmMain   : TfmMain;
  MainForm : TfmMain;

implementation

{$R *.lfm}

{ TfmMain }
procedure TfmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var loIniMgr : TEasyIniManager;
begin

  // *** Сохраним настройки в инишке
  loIniMgr := TEasyIniManager.Create(getAppFolder + csIniFile);
  loIniMgr.write(fmMain);
  loIniMgr.write(fmMain.dbgTasks);
  FreeAndNil(loIniMgr);
  // *** Закроем соединение с базой
  qrTasks.Close;
  IBC.Close();
  // *** Закроем лог
  moLog.WriteTimeStamp(csTimeStampMask);
  moLog.WriteLN(' closed.');
  moLog.Save();
  // *** Грохнем файл флага работы
  Windows.DeleteFileW(PWidechar(UnicodeString(getAppFolder + csRunningFile)));
end;


procedure TfmMain.FormCreate(Sender: TObject);
var lsLogName : String;
    loIniMgr : TEasyIniManager;
begin

  inherited;
  MainForm := fmMain;
  MainForm.Caption := Format(csMainFormCaption,[csVersion, 'остановлен']);
  dbgTasks.FocusColor := clNavy; // * Синяя рамка выбранной ячейки

  // *** Прочитаем конфиг
  loIniMgr := TEasyIniManager.Create(getAppFolder() + csIniFile);
  loIniMgr.read(fmMain);
  loIniMgr.read(fmMain.dbgTasks);
  FreeAndNil(loIniMgr);

  // *** Что там в командной строке?
  analizeCmdLine();
  // *** Заведем лог
  lsLogName := getAppFolder() + csLogsFolder + FormatDateTime('yyyymmdd', Now) + '.log';
  if FileExists(lsLogName) then
  begin

    moLog := TEasyLog.Load(lsLogName)
	end
	else begin

    moLog := TEasyLog.Create(lsLogName);
	end;
	moLog.WriteTimeStamp(csTimeStampMask);
  moLog.WriteLN(' started');
  moLog.Save;

  {$ifdef __DEBUG__}
  // *** Если включён режим отладки - выведем сообщение в заголовок и в лог
  MainForm.Caption := MainForm.Caption+' [отладка]';
  moLog.WriteLN('debug mode on');
  {$endif}

  // *** Так как у нас DLLки лежат в папке DLL, мы должны туда перейти
  ChDir(csDLLFolder);
  createDatabaseIfNeeded(); // * Создаем БД, если ее нет.
  reopenTables();
  // *** Обновим файл флага работы
  refreshRunningFile();
end;


procedure TfmMain.dbgTasksPrepareCanvas(sender: TObject; DataCol: Integer;
  Column: TColumn; AState: TGridDrawState);
//var s : string;
begin

  //s:=dbgTasks.Columns[0].Field.AsString;
  // *** Если последний запуск был успешен, отрисуем надпись другим цветом
  dbgTasks.Canvas.Font.Color:=iif(qrTasks.FieldByName('flastrunresult').AsInteger>0,
  clColorLastRunSuccessful, clColorLastRunUnSuccessful);
  // *** Если задача активна, фон зальем белым, иначе сереньким
  dbgTasks.Canvas.Brush.Color:=iif(qrTasks.FieldByName('fstatus').AsInteger=2,
    clColorTaskActiveBkg, clColorTaskInActiveBkg)
end;


procedure TfmMain.dbgTasksDblClick(Sender: TObject);
begin

  fmTaskEdit.viewRecord();
  reopenTables();
end;


procedure TfmMain.actStartExecute(Sender: TObject);
begin

  // *** Если программа активна...
  if Timer.Enabled then
  begin

    // *** Запишем в лог, что прогу стопанули.
	  if moLog<>Nil then
	  begin

      moLog.WriteTimeStamp(csTimeStampMask);
		  moLog.WriteLN(' stopped.');
		  moLog.Save;
	  end;
    // *** Остановим таймер
    Timer.Enabled := False;
    // *** Выставим на кнопку значок старта
    actStart.ImageIndex := ciIconStart;
    // *** Выведем в заголовке состояние программы
    MainForm.Caption := Format(csMainFormCaption,[csVersion, 'остановлен']);
  end else
  begin

    // *** Запишем в лог, что прогу стартовали
	  if moLog<>Nil then
	  begin

	    moLog.WriteTimeStamp(csTimeStampMask);
	    moLog.WriteLN(' runned.');
	    moLog.Save;
	  end;
    // *** Запустим таймер
    Timer.Enabled := True;
    // *** Выставим на кнопку значок старта
    actStart.ImageIndex := ciIconStop;
    // *** Выведем в заголовке состояние программы
    MainForm.Caption := Format(csMainFormCaption,[csVersion, 'работает.']);
	end;
end;


procedure TfmMain.actCreateTaskExecute(Sender: TObject);
var liCount : Integer;
begin

  try

    // *** Проверим, зарегистрирован ли хоть один архиватор
    initializeQuery(qrTaskEx,'select count(*) as acount from tblarchivators where fstatus>0', False);
    qrTaskEx.Open;
    liCount := qrTaskEx.FieldByName('acount').AsInteger;
    qrTaskEx.Close;
  except

    on E : Exception do
    begin

      processException('Создание задачи привело к возникновению исключительной ситуации: ', E);
		end;
	end;

  // *** Если определен хоть один архиватор...
  if liCount > 0 then
  begin

    // *** Добавляем задачу.
    fmTaskEdit.appendRecord();
    reopenTables();
	end else
  begin

    processError('Ошибка!','В БД не определен ни один архиватор!');
	end;
end;


procedure TfmMain.actDeleteTaskExecute(Sender: TObject);
begin

  if askYesOrNo('Задача будет удалена! Вы уверены?') then
  begin

    try

      initializeQuery(qrTaskEx,'delete from tbltasks where id=:pid', False);
      qrTaskEx.ParamByName('pid').AsInteger := qrTasks.FieldByName('ataskid').AsInteger;
      qrTaskEx.ExecSQL;
      trTaskEx.Commit;
      reopenTables();
    except

      on E : Exception do
      begin

        trTaskEx.Rollback;
        processException('Удаление задачи привело к возникновению исключительной ситуации: ', E);
  		end;
    end;
  end;
end;


procedure TfmMain.actEditTaskExecute(Sender: TObject);
begin

  fmTaskEdit.viewRecord();
  reopenTables();
end;


procedure TfmMain.actQuitExecute(Sender: TObject);
begin

  Close;
end;


procedure TfmMain.actActivateTaskExecute(Sender: TObject);
begin

  try

    initializeQuery(qrTaskEx,'update tbltasks set fstatus=:pstatus where id=:pid', False);
    // *** Запишем статус активности
    if qrTasks.FieldByName('fstatus').AsInteger = ciStatusInactive then
    begin

      qrTaskEx.ParamByName('pstatus').AsInteger := ciStatusActive;
    end else
    begin

      qrTaskEx.ParamByName('pstatus').AsInteger := ciStatusInActive;
		end;
		qrTaskEx.ParamByName('pid').AsInteger := qrTasks.FieldByName('ataskid').AsInteger;
    qrTaskEx.ExecSQL;
    trTaskEx.Commit;
    reopenTables();
  except

    on E : Exception do
    begin

      trTaskEx.Rollback;
      processException('Активация задачи привела к возникновению исключительной ситуации: ', E);
		end;
  end;
end;


procedure TfmMain.actRunTaskExecute(Sender: TObject);
begin

  processTask();
end;


procedure TfmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin

  // *** Нажали Escape -
  if Key=VK_ESCAPE then
  begin

    // *** ... спрятали форму
    Hide;
	end;
  // *** Нажали Ctrl-Q -
	if (Key=VK_Q) and (ssCtrl in Shift ) then
  begin

    // *** Good bye.
    Close;
	end;
end;


procedure TfmMain.FormWindowStateChange(Sender: TObject);
begin

  if WindowState = wsMinimized then
  begin

    Hide;
	end;
end;


procedure TfmMain.qrTasksAfterScroll(DataSet: TDataSet);
begin

  if qrTasks.FieldByName('fstatus').AsInteger=ciStatusInactive then
  begin

    actActivateTask.ImageIndex:=ciIconActivate;
    actActivateTask.Hint:='Активировать задачу';
  end else
  begin

    actActivateTask.ImageIndex:=ciIconDeActivate;
    actActivateTask.Hint:='Деактивировать задачу';
  end;
end;


procedure TfmMain.sbArchiversClick(Sender: TObject);
begin

  fmArchivators.ShowModal();
  reopenTables();
end;


procedure TfmMain.TimerTimer(Sender: TObject);
{$region}
const csSelectTask =
                     'select   TASK.id as ataskid'#13+
                     '       , TASK."fname"'#13+
                     '       , TASK."fsourcefolder"'#13+
                     '       , TASK."ftargetfolder"'#13+
                     '       , TASK."ftargetfile"'#13+
                     '       , TASK."farchivator"'#13+
                     '       , TASK."farchivatoroptions"'#13+
                     '       , TASK."fperiod"'#13+
                     '       , TASK."ftime"'#13+
                     '       , TASK."fdayofweek"'#13+
                     '       , TASK."fdate"'#13+
                     '       , TASK."frunbeforebackup"'#13+
                     '       , TASK."frunafterbackup"'#13+
                     '       , ARC."fname"'#13+
                     '       , ARC."fextension"'#13+
                     '       , ARC."fpackpath"'#13+
                     '       , ARC."fpackoptions"'#13+
                     '  from tbltasks TASK'#13+
                     '  inner join tblarchivators ARC'#13+
                     '    on ARC."id"=TASK."farchivator"'#13+
                     '  where     (TASK."fstatus">1)'#13+
                     '        and (ARC."fstatus"=1)'#13+
                     '        and (((TASK."fperiod" = 5)'#13+
                     '            and  (TASK."fdate" = :pdate)'#13+
                     '            and  (TASK."ftime" = :ptime))'#13+
                     '          or ((TASK."fperiod" = 4)'#13+
                     '            and (substr(TASK."fdate",1,2) = substr(:pdate,1,2))'#13+
                     '            and (TASK."ftime" = :ptime))'#13+
                     '          or ((TASK."fperiod" = 3)'#13+
                     '            and (TASK."fdayofweek" = :pdayofweek)'#13+
                     '            and (TASK."ftime" = :ptime))'#13+
                     '          or ((TASK."fperiod" = 2)'#13+
                     '            and (TASK."ftime" = :ptime))'#13+
                     '          or ((TASK."fperiod" = 1)'#13+
                     '            and (substr(TASK."ftime",3,2) = substr(:ptime,3,2)))'#13+
                     '          or (TASK."fperiod" = 0))';
{$endregion}
var lsLogName : String;
    lsDate, lsTime : String;
begin

  //***** Начинается новый день -
  if (HourOf(Now) = 0) and (MinuteOf(Now) = 0) then
  begin

    // *** Пересоздаем лог
    FreeAndNil(moLog);
    lsLogName := getAppFolder() + 'logs/' + FormatDateTime('yyyymmdd',Now) + '.log';
    moLog := TEasyLog.Create(lsLogName);
    moLog.WriteTimeStamp(csTimeStampMask);
    moLog.WriteLN(' started');
    {$ifdef __DEBUG__}
    moLog.WriteLN('debug mode on');
    {$endif}
    moLog.Save;
  end;

  // *** Выбираем процессы, которые должны быть обработаны сейчас.
  try

    {$ifdef __DEBUG__}
    lsTime := '12:45';
    lsDate := '14.06';
    {$else}
    DateTimeToString(lsTime, 'hh:nn', Now());
    DateTimeToString(lsDate, 'dd.mm', Now());
    {$endif}
    initializeQuery(qrTaskExecute, csSelectTask);
    qrTaskExecute.ParamByName('pdate').AsString := lsDate;
    qrTaskExecute.ParamByName('ptime').AsString := lsTime;
    qrTaskExecute.ParamByName('pdayofweek').AsInteger := DayOfTheWeek(Now);
    qrTaskExecute.open();
    while not qrTaskExecute.EOF do
    begin

      ProcessTask();
      {$ifdef __DEBUG__}
      moLog.WriteTimeStamp('yyyy.MM.dd hh:mm');
      moLog.Write(qrTaskExecute.FieldByName('fname').AsString);
      moLog.Writeln('loaded');
      moLog.Save;
      {$endif}
      qrTaskExecute.Next();
    end;
    reopenTables();
  except

    on E : Exception do
    begin

      processException('Выборка задач для выполнения привело к возникновению исключительной ситуации: ', E);
		end;
  end;

  //***** Проверим, не нужно ли завершить работу.
  if FileExists(getAppFolder()+csQuitFile) then
  begin

    if not fmTaskEdit.Visible and not fmArchivators.Visible then
    begin

      Windows.DeleteFileW(PWidechar(UnicodeString(getAppFolder()+csQuitFile)));
      fmMain.Close;
    end;
  end
  else
  begin

    refreshRunningFile();
	end;
end;


procedure TfmMain.TrayIconDblClick(Sender: TObject);
begin

  if fmMain.Visible then
  begin

    fmMain.Hide
	end	else
  begin

    fmMain.Show;
	end;
end;


procedure TfmMain.createDatabaseIfNeeded;
{$region 'SQL'}
const csSQLCreateScript = 'create domain tid as integer not null;'#13+
                          'create domain tshortstr as varchar(64);'#13+
                          'create domain tnormalstr as varchar(128);'#13+
                          'create domain tlongstr as varchar(256);'#13+
                          'create domain thugestr as varchar(512);'#13+
                          'create domain tinteger as integer;'#13+
                          'set term !!;'#13+
                          'create table tblarchivators ('#13+
                          '    id tid,'#13+
                          '    fname tshortstr not null,'#13+
                          '    fpackpath tlongstr not null,'#13+
                          '    fpackoptions tnormalstr,'#13+
                          '    funpackpath tlongstr,'#13+
                          '    funpackoptions tnormalstr,'#13+
                          '    fextension tshortstr not null,'#13+
                          '    fstatus tinteger not null'#13+
                          ')!!'#13+
                          'create generator genarchivators!!'#13+
                          'create trigger trgarchivators for tblarchivators'#13+
                          '  active before insert position 1 as begin'#13+
                          '  if ((new.id is null) or (new.id = 0)) then'#13+
                          '    new.id=gen_id(genarchivators,1);'#13+
                          'end!!'#13+
                          'create ascending index idxarchivators on tblarchivators(fname)!!'#13+
                          'create table tbltasks('#13+
                          '  id tid,'#13+
                          '  fname tnormalstr not null,'#13+
                          '  fsourcefolder thugestr not null,'#13+
                          '  ftargetfolder thugestr not null,'#13+
                          '  ftargetfile thugestr not null,'#13+
                          '  farchivator tinteger not null,'#13+
                          '  farchivatoroptions thugestr not null,'#13+
                          '  fperiod tinteger not null,'#13+
                          '  ftime tshortstr,'#13+
                          '  fdayofweek tinteger not null,'#13+
                          '  fdate tshortstr, '#13+
                          '  flastrundate tinteger,'#13+
                          '  flastrunresult tinteger,'#13+
                          '  frunafterbackup thugestr, '#13+
                          '  frunbeforebackup thugestr, '#13+
                          '  fstatus tinteger not null'#13+
                          '  )!!'#13+
                          'create generator gentasks!!'#13+
                          'create trigger trgtasks for tbltasks'#13+
                          '  active before insert position 1 as begin'#13+
                          '  if ((new.id is null) or (new.id = 0)) then'#13+
                          '    new.id=gen_id(gentasks,1);'#13+
                          'end!!'#13+
                          'create ascending index idxtasks on tbltasks(fname)!!'#13+
                          'commit;';
{$endregion}
var lsMessage : String;
begin

  IBC.DatabaseName := getAppFolder()+'DB\'+csDatabaseFileName;
  IBC.Username := csFireBirdUser;
  IBC.Password := csFireBirdPassword;
  IBC.Charset := csFireBirdCharSet;
  IBC.Dialect := ciFireBirdDialect;
  IBC.Params.Add(csFireBirdPageSize);
  try

    if FileExists(IBC.DatabaseName) then
    begin

      lsMessage := 'При соединении с базой данных';
      IBC.Open;
    end else
    begin

      lsMessage := 'При создании базы данных';
      IBC.CreateDB();
      IBC.Open();
      trCreate.EndTransaction;
      trCreate.StartTransaction;
      scrCreate.Script.Clear;
      scrCreate.Script.AddDelimitedText(csSQLCreateScript, #13, True);
      scrCreate.Execute;
    end;
  except

    on E : Exception do
    begin

      processException(lsMessage + ' возникла исключительная ситуация: ', E);
 		end;
 	end;
  qrTasks.Transaction := trTasks;
  qrTaskEx.Transaction := trTaskEx;
  qrTaskExecute.Transaction := trTaskExecute;
  scrCreate.Transaction := trCreate;
end;


procedure TfmMain.analizeCmdLine;
var loParams : TEasyParameters;
begin

  loParams := TEasyParameters.Create();
  if loParams.isParam(csRunCmd) then
  begin

    actStartExecute(Nil);
  end;
  FreeAndNil(loParams);
end;


procedure TfmMain.processTask();
const csSQLUpdate =
        'update tbltasks'+
        '  set flastrunresult=:plastrunresult,'+
        '      flastrundate=:plastrundate'+
        ' where id=:pid';

var lsCmdLine,
    lsBackupName : String;
    lsBeforeCmdLine : String;
    lsTargetFolder : String;
    liProcessedTaskID : Integer;
begin
  //***** Соберем строку параметров упаковщика
  lsCmdLine := '/C ' + qrTaskExecute.FieldByName('fpackpath').AsString + ' ' +
                       qrTaskExecute.FieldByName('fpackoptions').AsString + ' '+
                       qrTaskExecute.FieldByName('farchivatoroptions').AsString + ' ';
  //***** Сгенерим имя файла архива в зависимости от периода
  lsBackupName := qrTaskExecute.FieldByName('ftargetfile').AsString;
  lsBackupName := ReplaceStr(lsBackupName, '`', '"');
  lsBackupName := FormatDateTime(lsBackupName,Now,MyOwnFormatSettings);
  lsTargetFolder := addSeparator(qrTaskExecute.FieldByName('ftargetfolder').AsString);
  lsBackupName := lsTargetFolder + lsBackupName + '.' + qrTaskExecute.FieldByName('fextension').AsString;

  //***** Добавим имя архива в командную строку
  lsCmdLine := lsCmdLine + lsBackupName + ' ';

  //***** Папка или файл?
  lsCmdLine := lsCmdLine + qrTaskExecute.FieldByName('fsourcefolder').AsString;

  if not isEmpty(qrTaskExecute.FieldByName('frunbeforebackup').AsString) then
  begin

    lsBeforeCmdLine := '/C ' + qrTaskExecute.FieldByName('frunbeforebackup').AsString + ' "' + lsBackupName + '"';
    EasyExec('cmd.exe',lsBeforeCmdLine, True,True);
  end;

  //***** Запускаем
  fmMain.Cursor := crHourGlass;
  EasyExec('cmd.exe',lsCmdLine,True,True);
  fmMain.Cursor := crDefault;
  // *** Отпишем в лог
  moLog.WriteTimeStamp(csTimeStampMask);
  moLog.WriteLN('task '+ qrTaskExecute.FieldByName('fname').AsString + ' executed');
  moLog.WriteLN(lsCmdLine);
  if FileExists(lsBackupName) then
  begin

    moLog.WriteLN('successfully =)');

    //***** Запускаем "после резервирования"
    if not isEmpty(qrTaskExecute.FieldByName('frunafterbackup').AsString) then
    begin

      lsCmdLine := '/C ' + qrTaskExecute.FieldByName('frunafterbackup').AsString + ' "' + lsBackupName + '"';
      EasyExec('cmd.exe',lsCmdLine,True,True);
    end;
  end else
  begin

    moLog.WriteLN('unsuccessfully =(');
    moLog.WriteLN(lsCmdLine);
  end;
  moLog.Save;
  //***** Занесем в базу результат
  liProcessedTaskID := qrTaskExecute.FieldByName('ataskid').AsInteger;
  try

    initializeQuery(qrTaskEx,csSQLUpdate, False);
    qrTaskEx.ParamByName('pid').AsInteger := liProcessedTaskID;
    qrTaskEx.ParamByName('plastrunresult').AsInteger :=
      iif(FileExists(lsBackupName), ciLastRunSuccessful, ciLastRunUnSuccessful);
    qrTaskEx.ParamByName('plastrundate').AsDate := DateOf(Now);
    qrTaskEx.ExecSQL;
    trTaskEx.Commit;
  except
    on E : Exception do
    begin

      trTaskEx.Rollback;
      processException('Выполнение задачи привело к возникновению исключительной ситуации: ', E);
		end;
  end;
  reopenTables();
end;


procedure TfmMain.refreshRunningFile;
var T : Text;
begin

  AssignFile(T, getAppFolder()+csRunningFile);
  Rewrite(T);
  writeln(T,FormatDateTime('yyyy.MM.dd hh:mm:ss',Now));
  CloseFile(T);
end;


procedure TfmMain.reopenTables;
var liID : Integer;
    s : String;
begin
  liID := -1;
  try

    if qrTasks.State = dsBrowse then
    begin

      liID := qrTasks.FieldByName('ataskid').AsInteger;
		end;
		initializeQuery(qrTasks, csSQLSelectTasks);
    // qrTasks.SQL.SaveToFile('../111.sql');
    qrTasks.ParamByName('pstatus').AsInteger:=ciStatusInActive;
    qrTasks.Open;
    qrTasks.First;
    qrTasks.Locate('ataskid', liID, []);
    //s:=qrTasks.FieldByName('astatus').AsString;
    // *** Разрешим / запретим кнопки в зависимости от состояния выборки
    actEditTask.Enabled := qrTasks.RecordCount > 0;
    actDeleteTask.Enabled := actEditTask.Enabled;
    actRunTask.Enabled := actEditTask.Enabled;
    actActivateTask.Enabled := actEditTask.Enabled;
  except

    on E : Exception do
    begin

      processException('(пере)Открытие БД привело к возникновению исключительной ситуации: ', E);
		end;
  end;
end;


function TfmMain.RusDayOfWeek(pdtDate : TDateTime): Integer;
var loDay : Integer;
begin

  if pdtDate = NullDate then
  begin

    pdtDate := Now;
	end;
	loDay := DayOfTheWeek(pdtDate);
  if loDay = 1 then
  begin

    Result := 7;
	end else
  begin

    Result := loDay - 1;
	end;
end;


procedure TfmMain.processError(psDesc, psDetail: String);
begin

  moLog.WriteLN(psDesc + ' ' + psDetail);
  moLog.Save;
  FatalError(psDesc, psDetail);
end;


procedure TfmMain.processException(psDetail: String; poException: Exception);
begin

  moLog.WriteLN(poException.Message + ' ' + psDetail);
  moLog.Save;
  FatalError(poException.Message, psDetail);
end;


end.

