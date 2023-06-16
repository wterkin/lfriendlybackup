unit formathelp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfmFormatHelp }

  TfmFormatHelp = class(TForm)
    Memo1: TMemo;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fmFormatHelp: TfmFormatHelp;

implementation

{$R *.lfm}

end.

