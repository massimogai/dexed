unit ce_new;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  StdCtrls, ExtCtrls, Buttons, Menus, ComCtrls, ce_widget, ce_common,
  ce_sharedres, ce_interfaces, ce_dsgncontrols, ce_synmemo, ce_ceproject;

type

  TToolInfoKind = (tikRunning, tikFindable, tikOptional, tikCompiler);



  { TCENewWidget }

  TCENewWidget = class(TCEWidget)
    CreateButton: TButton;
    CancelButton: TButton;
    AddProjectCheckBox: TCheckBox;
    ClassNameEditBox: TEdit;
    PakageEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    FileNameLabel: TLabel;
    ClassNameLabel: TLabel;
    PackageLabel: TLabel;
    TypeListBox: TListBox;
    fDoc: TCESynMemo;
    fNativeProject: TCENativeProject;

    procedure ClassNameEditBoxChange(Sender: TObject);
    procedure CreateButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure ContentClick(Sender: TObject);
    procedure PakageEditChange(Sender: TObject);
    procedure TypeListBoxClick(Sender: TObject);

  private
    selectedType: integer;
    filePath: string;
    fullFileName: string;
    procedure RefreshAllStatus;
    function findCriticalyMissingTool: boolean;
    procedure newFile;
    procedure createClass;
    procedure updateFields;
    function compileClass(currentClassName: string): string;
    function compileInterface(currentInterfaceName: string): string;
    function compileEnum(currentEnumName: string): string;
    function compileMain(currentEnumName: string): string;

  protected
    procedure SetVisible(Value: boolean); override;
  public
    constructor Create(aOwner: TComponent); override;

    property hasMissingTools: boolean read findCriticalyMissingTool;
    procedure setDoc(afDoc: TCESynMemo; afNativeProject: TCENativeProject);
  end;

implementation

{$R *.lfm}

constructor TCENewWidget.Create(aOwner: TComponent);

begin
  inherited;
  toolbarVisible := False;
  fIsModal := True;
  fIsDockable := False;



  TypeListBox.Items.Clear;             //Delete all existing strings
  TypeListBox.Items.Add('D class.');
  TypeListBox.Items.Add('D interface.');
  TypeListBox.Items.Add('D enum.');
  TypeListBox.Items.Add('D Main unit.');
  Realign;
end;

procedure TCENewWidget.setDoc(afDoc: TCESynMemo; afNativeProject: TCENativeProject);
var
  basePath: string;
  defaultClassName: string;
begin
  defaultClassName := 'newClass';
  self.fDoc := afDoc;
  self.fNativeProject := afNativeProject;
  basePath := fNativeProject.basePath + 'src/';
  self.ClassNameEditBox.Text := defaultClassName;
  FileNameLabel.Caption := basePath + defaultClassName + '.d';
end;


function TCENewWidget.findCriticalyMissingTool: boolean;

begin
  Result := False;

end;

procedure TCENewWidget.CreateButtonClick(Sender: TObject);
begin
  createClass();
end;

procedure TCENewWidget.ClassNameEditBoxChange(Sender: TObject);

begin
  updateFields();

end;

procedure TCENewWidget.updateFields;
var

  packagePath: string;
  packageName: string;
  srcBasePath: string;
  currentClassName: string;

begin
  packageName := PakageEdit.Text;
  packagePath := packageName.Replace('.', '/');
  if (packagePath.length > 0) then
  begin
    packagePath := packagePath + '/';
  end;
  currentClassName := ClassNameEditBox.Text;
  srcBasePath := fNativeProject.basePath + 'src/';
  filePath := srcBasePath + packagePath;
  fullFIleName := filePath + currentClassName + '.d';
  FileNameLabel.Caption := fullFIleName;
end;


procedure TCENewWidget.newFile;
begin
  TCESynMemo.Create(nil);
end;

function TCENewWidget.compileClass(currentClassName: string): string;
var
  classDef: string;
begin

  classDef :=
    'module ' + currentClassName + ';' + LineEnding + LineEnding +
    'import std.stdio;' + LineEnding + LineEnding + 'class ' +
    currentClassName + LineEnding + '{' + LineEnding + '}';
  Result := classDef;
end;
function TCENewWidget.compileInterface(currentInterfaceName: string): string;
var
  classDef: string;
begin

  classDef :=
    'module ' + currentInterfaceName + ';' + LineEnding + LineEnding +
    'import std.stdio;' + LineEnding + LineEnding + 'interface ' +
    currentInterfaceName + LineEnding + '{' + LineEnding + '}';
  Result := classDef;
end;
function TCENewWidget.compileEnum(currentEnumName: string): string;
var
  classDef: string;
begin

  classDef :=
    'module ' + currentEnumName + ';' + LineEnding + LineEnding +
    'import std.stdio;' + LineEnding + LineEnding + 'enum ' +
    currentEnumName + LineEnding + '{' + LineEnding + '}';
  Result := classDef;
end;
function TCENewWidget.compileMain(currentEnumName: string): string;
var
  classDef: string;
begin

  classDef :=
    'module ' + currentEnumName + ';' + LineEnding + LineEnding +
    'import std.stdio;' + LineEnding + LineEnding + 'void main(string[] args) ' +
     LineEnding + '{' + LineEnding + '}';
  Result := classDef;
end;

procedure TCENewWidget.createClass();

var

  currentClassName: string;
begin
  currentClassName := ClassNameEditBox.Text;
  ForceDirectories(self.filePath);

  case selectedType of
    0: fDoc.Text := compileClass(currentClassName);
    1: fDoc.Text := compileInterface(currentClassName);
    2: fDoc.Text := compileEnum(currentClassName);
    3: fDoc.Text := compileMain(currentClassName);

  end;

  fDoc.SetFocus;
  fDoc.saveToFile(self.fullFileName);

  fNativeProject.addSource(self.fullFileName  );
  Close();
end;

procedure TCENewWidget.CancelButtonClick(Sender: TObject);
begin
  Close();
end;

procedure TCENewWidget.ContentClick(Sender: TObject);
begin

end;

procedure TCENewWidget.PakageEditChange(Sender: TObject);
begin
  updateFields();
end;

procedure TCENewWidget.TypeListBoxClick(Sender: TObject);
var
  index: integer;
begin

  index := TypeListBox.ItemIndex;
  selectedType := index;
  case index of
    0: Label3.Caption := 'Create a D empty Class';
    1: Label3.Caption := 'Create a D empty Interface';
    2: Label3.Caption := 'Create a D empty Enum';
    3: Label3.Caption := 'Create a D main Unit';

  end;
  RefreshAllStatus;
end;

procedure TCENewWidget.RefreshAllStatus;
var

  s: string = '';

begin

  if s.isNotEmpty then
    getMessageDisplay.message('Some tools cannot be found:' + s, nil, amcApp, amkWarn);
end;

procedure TCENewWidget.SetVisible(Value: boolean);
begin
  inherited;
  if Visible then
    RefreshAllStatus;
end;

end.
