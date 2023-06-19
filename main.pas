unit main;


interface
{$mode objfpc}
{$H+}
uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, DBGrids, ComCtrls, sqlite3conn, sqldb, db, windows, Grids, StdCtrls,
  Menus, ActnList, DateUtils, StrUtils, DateTimePicker,
  tlib, tdb, tstr, tparams, tlog, tini, tapp, tmsg, tsqlite,
  archivators, taskedit;

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
    SQLite: TSQLite3Connection;
    qrTasks: TSQLQuery;
    qrTaskExt: TSQLQuery;
		qrTaskUpdate: TSQLQuery;
		SQLTransaction1: TSQLTransaction;
    StatusBar1: TStatusBar;
    Timer: TTimer;
    Transact: TSQLTransaction;
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
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var {%H-}CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure FormWindowStateChange(Sender: TObject);
    procedure qrTasksAfterScroll({%H-}DataSet: TDataSet);
    procedure sbArchiversClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
  private

    moLog : TEasyLog;
    //miLastID : Integer;
    moTaskExecuteQuery : TEasySQLite;
    moTasks : TEasySQLite;
    procedure createDatabaseIfNeeded();
    procedure analizeCmdLine();
    procedure processTask();
    procedure refreshRunningFile();
    procedure AfterScroll();
  public

    procedure reopenTables();
    function RusDayOfWeek(pdtDate : TDateTime = NullDate) : Integer;
  end;


  TTaskInfoArray = array of TTaskInfo;

const
    {$region 'SQL'}
      csSQLSelectTasks =
        'select TASK."id" as "ataskid",'#13+
        '               TASK."fname",'#13+
        '               TASK."fsourcefolder",'#13+
        '               TASK."ftargetfolder",'#13+
        '               TASK."ftargetfile",'#13+
        '               TASK."farchivator",'#13+
        '               TASK."farchivatoroptions",'#13+
        '               TASK."fperiod",'#13+
        '               TASK."ftime",'#13+
        '               TASK."fdayofweek",'#13+
        '               TASK."fdate",'#13+
        '               TASK."frunbeforebackup",'#13+
        '               TASK."frunafterbackup",'#13+
        '               TASK."flastrundate",'#13+
        '               TASK."flastrunresult",'#13+
        '               TASK."fstatus",'#13+
        '               ARC."fname",'#13+
        '               ARC."fextension",'#13+
        '               ARC."fpackpath",'#13+
        '               ARC."fpackoptions",'#13+
        '               case TASK."fstatus" when 2 then ''Активна'' else ''Неактивна'' end as astatus'#13+
        '          from tbltasks TASK'#13+
        '          inner join tblarchivators ARC'#13+
        '            on ARC."id"=TASK."farchivator"'#13+
        '          where (TASK."fstatus">=:pstatus) and'#13+
        '                (ARC."fstatus">0)';

      {$endregion}

      csDatabaseFileName         = 'lfriendlybackup.db';
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

      csTimeStampMask  = 'yyyy/mm/dd hh:mm';
      csControlChar    = '.';
      csQuitFile       = csControlChar+'quit';
      csRunningFile    = csControlChar+'iamrunning';
      csIniFile        = 'lfriendlybackup.ini';
      csVersion        = 'ver. 2.0.1';
      ciIconStart      = 6;
      ciIconStop       = 7;
      ciIconDeactivate = 9;
      ciIconActivate   = 10;
      {$define __DEBUG__}
var
  fmMain   : TfmMain;
  MainForm : TfmMain;

implementation

{$R *.lfm}

{ TfmMain }

procedure TfmMain.FormActivate(Sender: TObject);
var lsLogName : String;
    loIniMgr : TEasyIniManager;
begin

  OnActivate:=Nil;
  dbgTasks.FocusColor:=clNavy; // * Синяя рамка выбранной ячейки
  MainForm:=fmMain;
  MainForm.Caption:=Format(csMainFormCaption,[csVersion, 'остановлен']);
  createDatabaseIfNeeded(); // * Создаем БД, если ее нет.
  moTasks := TEasySQLite.Create();
  moTasks.setup(SQLite, dsTasks);
  //dbgTasks.DataSource := dsTasks;
  reopenTables();
  //if dbgTasks.DataSource.DataSet.State <> dsBrowse then

  //Caption := 'FAIL!!!!!!';
  // *** Прочитаем конфиг
  loIniMgr := TEasyIniManager.Create(getAppFolder + csIniFile);
  loIniMgr.read(fmMain);
  loIniMgr.read(fmMain.dbgTasks);
  FreeAndNil(loIniMgr);
  // *** Что там в командной строке?
  analizeCmdLine();
  // *** Заводим пару объектов для выборок
  moTaskExecuteQuery := TEasySQLite.Create();
  moTaskExecuteQuery.setup(SQLite);
  // *** Заведем лог
  lsLogName := getAppFolder() + 'logs/' + FormatDateTime('yyyymmdd',Now) + '.log';
  if FileExists(lsLogName) then
  begin

    moLog:=TEasyLog.Load(lsLogName)
	end
	else begin

    moLog:=TEasyLog.Create(lsLogName);
	end;
	moLog.WriteTimeStamp(csTimeStampMask);
  moLog.WriteLN(' started');
  moLog.Save;
  {$ifdef __DEBUG__}
  MainForm.Caption:=MainForm.Caption+' [отладка]';
  moLog.WriteLN('debug mode on');
  {$endif}
  // *** Обновим файл флага работы
  refreshRunningFile();
  {$ifndef __DEBUG__}
  Hide;
  {$endif}
end;


procedure TfmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var loIniMgr : TEasyIniManager;
begin

  // *** Грохнем файл флага работы
  Windows.DeleteFileW(PWidechar(UnicodeString(getAppFolder + csRunningFile)));
  // *** Закроем лог
  moLog.WriteTimeStamp(csTimeStampMask);
  moLog.WriteLN(' closed.');
  moLog.Save();
  // *** Сохраним настройки в инишке
  loIniMgr := TEasyIniManager.Create(getAppFolder + csIniFile);
  loIniMgr.write(fmMain);
  loIniMgr.write(fmMain.dbgTasks);
  FreeAndNil(loIniMgr);
  // *** Закроем соединение с базой
  //qrTasks.Close;
  qrTaskExt.Close;
  FreeAndNil(moTaskExecuteQuery);
  FreeAndNil(moTasks);
  SQLite.Close();
end;


procedure TfmMain.dbgTasksPrepareCanvas(sender: TObject; DataCol: Integer;
  Column: TColumn; AState: TGridDrawState);
begin

  // !!!!
  // *** Если последний запуск был успешен, отрисуем надпись другим цветом
  dbgTasks.Canvas.Font.Color:=iif(moTasks.integerField('flastrunresult')>0,
  clColorLastRunSuccessful, clColorLastRunUnSuccessful);
  dbgTasks.Canvas.Brush.Color:=iif(moTasks.integerField('fstatus')=2,
    clColorTaskActiveBkg, clColorTaskInActiveBkg)
//
//  dbgTasks.Canvas.Font.Color:=iif(qrTasks.FieldByName('flastrunresult').AsInteger>0,
//    clColorLastRunSuccessful, clColorLastRunUnSuccessful);
  // *** Если задача активна, фон зальем белым, иначе сереньким
  //dbgTasks.Canvas.Brush.Color:=iif(qrTasks.FieldByName('fstatus').AsInteger=2,
  //  clColorTaskActiveBkg, clColorTaskInActiveBkg)
end;


procedure TfmMain.dbgTasksDblClick(Sender: TObject);
begin

  moTasks.store();
  //miLastID:=qrTasks.FieldByName('ataskid').AsInteger;
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
    Timer.Enabled:=False;
    // *** Выставим на кнопку значок старта
    actStart.ImageIndex:=ciIconStart;
    // *** Выведем в заголовке состояние программы
    MainForm.Caption:=Format(csMainFormCaption,[csVersion, 'остановлен']);
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
    Timer.Enabled:=True;
    // *** Выставим на кнопку значок старта
    actStart.ImageIndex:=ciIconStop;
    // *** Выведем в заголовке состояние программы
    MainForm.Caption:=Format(csMainFormCaption,[csVersion, 'работает.']);
	end;
end;


procedure TfmMain.actCreateTaskExecute(Sender: TObject);
var liCount : Integer;
begin

  try

    // *** Запомним текущую запись
    moTasks.Store();
    //miLastID:=qrTasks.FieldByName('ataskid').AsInteger;
    // *** Получим количество зарегистрированных архиваторов.
    initializeQuery(qrTaskExt,'select count(*) as acount from tblarchivators where fstatus>0', False);
    qrTaskExt.Open;
    liCount:=qrTaskExt.FieldByName('acount').AsInteger;
    qrTaskExt.Close;
  except

    FatalError('Error!','Database request failed!');
  end;

  // *** Если определен хоть один архиватор...
  if liCount>0 then
  begin

    // *** Добавляем задачу.
    fmTaskEdit.appendRecord()
	end else
  begin

    FatalError('Ошибка!','Добавьте сначала хоть один архиватор!');
	end;
  reopenTables();
end;


procedure TfmMain.actDeleteTaskExecute(Sender: TObject);
//var liID : Integer;
begin

  if askYesOrNo('Задача будет удалена! Вы уверены?') then
  begin

    try

      //moTasks.store();
      //liID:=qrTasks.FieldByName('ataskid').AsInteger;
      initializeQuery(qrTaskExt,'delete from tbltasks where id=:pid', False);
      qrTaskExt.ParamByName('pid').AsInteger:=moTasks.integerField('ataskid');
      qrTaskExt.ExecSQL;
      Transact.Commit;
      //moTasks.open();
      //miLastID:=0;
      reopenTables();
    except

      Transact.Rollback;
      moLog.WriteLN('Error! Database request failed!');
      moLog.Save;
      FatalError('Error!','Database request failed!');
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

    // *** Запомним текущую запись
    moTasks.store();
    //miLastID:=qrTasks.FieldByName('ataskid').AsInteger;
    // *** Запишем статус активности
    initializeQuery(qrTaskExt,'update tbltasks set "fstatus"=:pstatus where "id"=:pid', False);
    if moTasks.integerField('fstatus') = ciStatusInactive then
    begin

      qrTaskExt.ParamByName('pstatus').AsInteger:=ciStatusActive;
    end else
    begin

      qrTaskExt.ParamByName('pstatus').AsInteger:=ciStatusInActive;
		end;

  //  if qrTasks.FieldByName('fstatus').AsInteger=ciStatusInactive then
  //  begin
  //
  //    qrTaskExt.ParamByName('pstatus').AsInteger:=ciStatusActive;
  //  end else
  //  begin
  //
  //    qrTaskExt.ParamByName('pstatus').AsInteger:=ciStatusInActive;
		//end;
		qrTaskExt.ParamByName('pid').AsInteger:=moTasks.integerField('ataskid');
    qrTaskExt.ExecSQL;
    Transact.Commit;
    reopenTables();
  except

    Transact.Rollback;
    FatalError('Error!','Database request failed!');
  end;
end;


procedure TfmMain.actRunTaskExecute(Sender: TObject);
begin

  processTask();
end;


procedure TfmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
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

  if WindowState=wsMinimized then
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

  //miLastID:=qrTasks.FieldByName('ataskid').AsInteger;
  moTasks.store();
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
  if (HourOf(Now)=0) and (MinuteOf(Now)=0) then
  begin

    // *** Пересоздаем лог
    FreeAndNil(moLog);
    lsLogName:=getAppFolder()+'logs/'+FormatDateTime('yyyymmdd',Now)+'.log';
    moLog:=TEasyLog.Create(lsLogName);
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
    //miLastID:=qrTasks.FieldByName('ataskid').AsInteger;
    moTasks.store();
    moTaskExecuteQuery.initialize(csSelectTask, 'ataskid');
    moTaskExecuteQuery.parameter('pdate', lsDate);
    moTaskExecuteQuery.parameter('ptime', lsTime);
    moTaskExecuteQuery.parameter('pdayofweek', DayOfTheWeek(Now));
    moTaskExecuteQuery.open();
    while not moTaskExecuteQuery.EOF() do
    begin

      moTaskExecuteQuery.store();
      ProcessTask();
      moTaskExecuteQuery.open();
      moTaskExecuteQuery.reStore();

      {$ifdef __DEBUG__}
      moLog.WriteTimeStamp('yyyy.MM.dd hh:mm');
      moLog.Write(moTaskExecuteQuery.StringField('fname'));
      moLog.Writeln('loaded');
      moLog.Save;
      {$endif}
      //qrTaskExec.Next;
      moTaskExecuteQuery.next();
    end;
    reopenTables();

  except

    FatalError('Error!','Database request failed!');
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
const csSQLCreateTableArchivators =
        'create table "tblarchivators" ('#13+
        '    "id" integer primary key asc on conflict abort'+
        '         autoincrement not null on conflict abort '+
        '         unique on conflict abort,'#13+
        '    "fname" nchar(32) not null on conflict abort,'#13+
        '    "fpackpath" nchar(255) not null on conflict abort,'#13+
        '    "fpackoptions" nchar(128) not null on conflict abort,'#13+
        '    "funpackpath" nchar(255) not null on conflict abort,'#13+
        '    "funpackoptions" nchar(128) not null on conflict abort,'#13+
        '    "fextension" nchar(8) not null on conflict abort,'#13+
        '    "fstatus" integer not null on conflict abort default(1)'#13+
        ');';
     csSQLCreateTableTasks =
       'create table "tbltasks"('#13+
       '  "id" integer primary key asc on conflict abort'+
       '       autoincrement not null on conflict abort'+
       '       unique on conflict abort,'#13+
       '  "fname" nchar(128) not null on conflict abort,'#13+
       '  "fsourcefolder" nchar(510) not null on conflict abort,'#13+
       '  "ftargetfolder" nchar(510) not null on conflict abort,'#13+
       '  "ftargetfile" nchar(510) not null on conflict abort,'#13+
       '  "farchivator" integer not null on conflict abort,'#13+
       '  "farchivatoroptions" nchar(510) not null on conflict abort,'#13+
       '  "fperiod" integer not null on conflict abort,'#13+
       '  "ftime" nchar(64),'#13+
       '  "fdayofweek" integer not null on conflict abort,'#13+
       '  "fdate" nchar(64), '#13+
       '  "flastrundate" integer, '#13+
       '  "flastrunresult" integer, '#13+
       '  "frunafterbackup" nchar(510), '#13+
       '  "frunbeforebackup" nchar(510), '#13+
       '  "fstatus" integer not null on conflict abort default(1)'#13+
       '  );';

var lsDatabaseFullName : String;
    lblDabaseExists    : Boolean;
begin

  lsDatabaseFullName:=getAppFolder()+'DB\'+csDatabaseFileName;
  lblDabaseExists:=FileExists(lsDatabaseFullName);
  try

    SQLite.DatabaseName:=lsDatabaseFullName;
    SQLite.Open;
    SQLite.Connected:=True;
    if not lblDabaseExists then
    begin

      Transact.StartTransaction;
      SQLite.ExecuteDirect(csSQLCreateTableArchivators);
      SQLite.ExecuteDirect(csSQLCreateTableTasks);
      Transact.Commit;
    end;
  except

    FatalError('Ошибка открытия БД!', '');
	end;
end;


procedure TfmMain.analizeCmdLine;
var loParams : TEasyParameters;
begin

  loParams:=TEasyParameters.Create();
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
  lsCmdLine := '/C ' + moTaskExecuteQuery.stringField('fpackpath') + ' ' +
                       moTaskExecuteQuery.stringField('fpackoptions') + ' '+
                       moTaskExecuteQuery.stringField('farchivatoroptions') + ' ';
  //***** Сгенерим имя файла архива в зависимости от периода
  lsBackupName := moTaskExecuteQuery.stringField('ftargetfile');
  lsBackupName := ReplaceStr(lsBackupName, '`', '"');
  lsBackupName := FormatDateTime(lsBackupName,Now,MyOwnFormatSettings);
  lsTargetFolder := addSeparator(moTaskExecuteQuery.stringField('ftargetfolder'));
  lsBackupName := lsTargetFolder + lsBackupName + '.' + moTaskExecuteQuery.stringField('fextension');

  //***** Добавим имя архива в командную строку
  lsCmdLine := lsCmdLine + lsBackupName + ' ';

  //***** Папка или файл?
  lsCmdLine:=lsCmdLine + moTaskExecuteQuery.stringField('fsourcefolder');

  if not isEmpty(moTaskExecuteQuery.stringField('frunbeforebackup')) then
  begin

    lsBeforeCmdLine := '/C ' + moTaskExecuteQuery.stringField('frunbeforebackup') + ' "' + lsBackupName + '"';
    EasyExec('cmd.exe',lsBeforeCmdLine, True,True);
  end;

  //***** Запускаем
  fmMain.Cursor:=crHourGlass;
  EasyExec('cmd.exe',lsCmdLine,True,True);
  fmMain.Cursor:=crDefault;
  // *** Отпишем в лог
  moLog.WriteTimeStamp(csTimeStampMask);
  moLog.WriteLN('task '+ moTaskExecuteQuery.stringField('fname') + ' executed');
  moLog.WriteLN(lsCmdLine);
  if FileExists(lsBackupName) then
  begin

    moLog.WriteLN('successfully =)');

    //***** Запускаем "после резервирования"
    if not isEmpty(moTaskExecuteQuery.stringField('frunafterbackup')) then
    begin

      lsCmdLine := '/C ' + moTaskExecuteQuery.stringField('frunafterbackup') + ' "' + lsBackupName + '"';
      EasyExec('cmd.exe',lsCmdLine,True,True);
    end;
  end else
  begin

    moLog.WriteLN('unsuccessfully =(');
    moLog.WriteLN(lsCmdLine);
  end;
  moLog.Save;
  //***** Занесем в базу результат
  //miLastID:=qrTasks.FieldByName('ataskid').AsInteger;
  moTasks.store();
  liProcessedTaskID := moTaskExecuteQuery.integerField('ataskid');
  // **** К чему бы тут это?
  Transact.EndTransaction;
  Transact.StartTransaction;
  try

    initializeQuery(qrTaskUpdate,csSQLUpdate, False);
    qrTaskUpdate.ParamByName('pid').AsInteger:=liProcessedTaskID;
    qrTaskUpdate.ParamByName('plastrunresult').AsInteger:=
      iif(FileExists(lsBackupName),ciLastRunSuccessful,ciLastRunUnSuccessful);
    qrTaskUpdate.ParamByName('plastrundate').AsDate:=DateOf(Now);
    qrTaskUpdate.ExecSQL;
    Transact.Commit;
  except

    Transact.Rollback;
    moLog.WriteLN('Error! Database request failed!');
    moLog.Save;
    FatalError('Error!','Database request failed!');
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


procedure TfmMain.AfterScroll;
begin

  if moTasks.integerField('fstatus') = ciStatusInactive then
  begin

    actActivateTask.ImageIndex:=ciIconActivate;
    actActivateTask.Hint:='Активировать задачу';
  end else
  begin

    actActivateTask.ImageIndex:=ciIconDeActivate;
    actActivateTask.Hint:='Деактивировать задачу';
  end;
end;


procedure TfmMain.reopenTables;
begin

  try

    if not moTasks.isClosed() then
    begin

      moTasks.close();
		end;

		//if qrTasks.State<>dsInactive then
  //  begin
  //
  //    qrTasks.Close;
		//end;
    moTasks.initialize(csSQLSelectTasks, 'ataskid');
    moTasks.parameter('pstatus', ciStatusDeleted);
    moTasks.open();
    moTasks.reStore();
    AfterScroll();
		//initializeQuery(qrTasks,csSQLSelectTasks);
  //  qrTasks.ParamByName('pstatus').AsInteger:=ciStatusDeleted;
  //  qrTasks.Open;
  //  qrTasks.Locate('ataskid',miLastID{%H-}, []);
  //  qrTasks.AfterScroll(qrTasks);
    // *** Разрешим / запретим кнопки в зависимости от состояния выборки
    actEditTask.Enabled:=moTasks.Count()>0;
    actDeleteTask.Enabled:=actEditTask.Enabled;
    actRunTask.Enabled:=actEditTask.Enabled;
    actActivateTask.Enabled:=actEditTask.Enabled;
  except

    FatalError('Error!','Database request failed!');
  end;
end;


function TfmMain.RusDayOfWeek(pdtDate: TDateTime): Integer;
var loDay : Integer;
begin

  if pdtDate=NullDate then
  begin

    pdtDate:=Now;
	end;
	loDay:=DayOfTheWeek(pdtDate);
  if loDay=1 then
  begin

    Result:=7
	end else
  begin

    Result:=loDay-1;
	end;
end;


end.

