program lfriendlybackup;

{$mode objfpc}{$H+}

uses
      {$IFDEF UNIX}
      cthreads,
      {$ENDIF}
      {$IFDEF HASAMIGA}
      athreads,
      {$ENDIF}
      Interfaces, // this includes the LCL widgetset
      Forms, datetimectrls, archivators, archiverEdit, formathelp, main,
			taskedit, tsqlite;

{$R *.res}

begin
      RequireDerivedFormResource:=True;
			Application.Scaled:=True;
      Application.Initialize;
			Application.CreateForm(TfmMain, fmMain);
			Application.CreateForm(TfmArchivators, fmArchivators);
			Application.CreateForm(TfmArchivatorEdit, fmArchivatorEdit);
			Application.CreateForm(TfmFormatHelp, fmFormatHelp);
			Application.CreateForm(TfmTaskEdit, fmTaskEdit);
      Application.Run;
end.

