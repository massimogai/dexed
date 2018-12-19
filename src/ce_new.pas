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
    ObjectNameEditBox: TEdit;
    PackageNameEdit: TEdit;
    PackageNameLabel: TLabel;
    ModuleNameEdit: TEdit;
    FileNameLabel1: TLabel;
    DescriptionLabel: TLabel;
    FileNameLabel: TLabel;
    ObjectNameLabel: TLabel;
    ModuleNameLabel: TLabel;
    TypeListBox: TListBox;
    fDoc: TCESynMemo;
    fNativeProject: TCENativeProject;

    procedure ObjectNameEditBoxChange(Sender: TObject);
    procedure CreateButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure ContentClick(Sender: TObject);
    procedure PackageNameEditChange(Sender: TObject);
    procedure ModuleNameEditChange(Sender: TObject);
    procedure TypeListBoxClick(Sender: TObject);

  private
    selectedType: integer;
    procedure newFile;
    procedure createClass;
    procedure updateFields;
    function compileClass(currentPackageName: string; currentClassName: string): string;
    function compileInterface(currentPackageName: string;
      currentInterfaceName: string): string;
    function compileEnum(currentPackageName: string; currentEnumName: string): string;
    function compileMain(currentPackageName: string; currentEnumName: string): string;

  protected

  public
    constructor Create(aOwner: TComponent); override;
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
  AddProjectCheckBox.Checked := True;
  TypeListBox.Items.Clear;             //Delete all existing strings
  TypeListBox.Items.Add('D class.');
  TypeListBox.Items.Add('D interface.');
  TypeListBox.Items.Add('D enum.');
  TypeListBox.Items.Add('D Main unit.');
  TypeListBox.Items.Add('D empty unit.');
  TypeListBox.Items.Add('D runnable unit.');
  Realign;
end;

procedure TCENewWidget.setDoc(afDoc: TCESynMemo; afNativeProject: TCENativeProject);
var
  defaultClassName: string;
begin
  defaultClassName := 'newClass';
  self.fDoc := afDoc;
  self.fNativeProject := afNativeProject;
  TypeListBox.ItemIndex := 0;
  DescriptionLabel.Caption := 'Create a D empty Class';
  ObjectNameLabel.Caption := 'Class Name';
  self.ObjectNameEditBox.Text := defaultClassName;

  updateFields();

end;

procedure TCENewWidget.CreateButtonClick(Sender: TObject);
begin
  createClass();
end;

procedure TCENewWidget.ObjectNameEditBoxChange(Sender: TObject);

begin
  updateFields();
end;

procedure TCENewWidget.updateFields;
var

  packagePath: string;
  packageName: string;
  srcBasePath: string;
  fullFileName: string;
  moduleName: string;
  nameCondition: boolean;
  objectName: string;
begin
  moduleName := ModuleNameEdit.Text;
  packageName := PackageNameEdit.Text;
  packagePath := packageName.Replace('.', '/');

  if (packagePath.length > 0) then
  begin
    packagePath := packagePath + '/';
  end;

  srcBasePath := fNativeProject.basePath + 'src/';
  fullFileName := srcBasePath + packagePath + moduleName + '.d';
  objectName := ObjectNameEditBox.Text;
  nameCondition := (TypeListBox.ItemIndex = 3) or (objectName.length <> 0);
  CreateButton.Enabled := (moduleName.length <> 0) and nameCondition;

  FileNameLabel.Caption := fullFileName;
end;


procedure TCENewWidget.newFile;
begin
  TCESynMemo.Create(nil);
end;

function TCENewWidget.compileClass(currentPackageName: string;
  currentClassName: string): string;
var
  classDef: string;
begin

  classDef :=
    'module ' + currentPackageName + ';' + LineEnding + LineEnding +
    'import std.stdio;' + LineEnding + LineEnding + 'class ' +
    currentClassName + LineEnding + '{' + LineEnding + '}';
  Result := classDef;
end;

function TCENewWidget.compileInterface(currentPackageName: string;
  currentInterfaceName: string): string;
var
  classDef: string;
begin

  classDef :=
    'module ' + currentPackageName + ';' + LineEnding + LineEnding +
    'import std.stdio;' + LineEnding + LineEnding + 'interface ' +
    currentInterfaceName + LineEnding + '{' + LineEnding + '}';
  Result := classDef;
end;

function TCENewWidget.compileEnum(currentPackageName: string;
  currentEnumName: string): string;
var
  classDef: string;
begin

  classDef :=
    'module ' + currentPackageName + ';' + LineEnding + LineEnding +
    'import std.stdio;' + LineEnding + LineEnding + 'enum ' +
    currentEnumName + LineEnding + '{' + LineEnding + '}';
  Result := classDef;
end;

function TCENewWidget.compileMain(currentPackageName: string;
  currentEnumName: string): string;
var
  classDef: string;
begin

  classDef :=
    'module ' + currentPackageName + ';' + LineEnding + LineEnding +
    'import std.stdio;' + LineEnding + LineEnding + 'void main(string[] args) ' +
    LineEnding + '{' + LineEnding + '}';
  Result := classDef;
end;

procedure TCENewWidget.createClass();

var
  moduleName: string;
  packageName: string;
  currentClassName: string;
  fullyQualifiedName: string;
  filePath: string;
  packagePath: string;
  srcBasePath: string;
  fullFileName: string;
begin
  moduleName := ModuleNameEdit.Text;
  packageName := PackageNameEdit.Text;
  currentClassName := ObjectNameEditBox.Text;

  if (packageName.length > 0) then
  begin
    fullyQualifiedName := packageName + '.' + moduleName;
  end
  else
  begin
    fullyQualifiedName := moduleName;
  end;

  packagePath := packageName.Replace('.', '/');
  if (packagePath.length > 0) then
  begin
    packagePath := packagePath + '/';
  end;
  srcBasePath := fNativeProject.basePath + 'src/';
  filePath := srcBasePath + packagePath;

  fullFileName := filePath + moduleName + '.d';
  ForceDirectories(filePath);

  case selectedType of
    0: fDoc.Text := compileClass(fullyQualifiedName, currentClassName);
    1: fDoc.Text := compileInterface(fullyQualifiedName, currentClassName);
    2: fDoc.Text := compileEnum(fullyQualifiedName, currentClassName);
    3: fDoc.Text := compileMain(fullyQualifiedName, currentClassName);

  end;

  fDoc.SetFocus;
  fDoc.saveToFile(fullFileName);
  if (AddProjectCheckBox.Checked) then
  begin
    fNativeProject.addSource(fullFileName);
  end;
  Close();
end;

procedure TCENewWidget.CancelButtonClick(Sender: TObject);
begin
  Close();
end;

procedure TCENewWidget.ContentClick(Sender: TObject);
begin
  updateFields();
end;

procedure TCENewWidget.PackageNameEditChange(Sender: TObject);
begin
  updateFields();
end;




procedure TCENewWidget.ModuleNameEditChange(Sender: TObject);
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
    0:
    begin
      DescriptionLabel.Caption := 'Create a D empty Class';
      ObjectNameLabel.Caption := 'Class Name';
      ObjectNameLabel.Visible := True;
      ObjectNameEditBox.Visible := True;
      ObjectNameEditBox.Text := 'NewClassName';
      ModuleNameEdit.Text:='';

    end;
    1:
    begin
      DescriptionLabel.Caption := 'Create a D empty Interface';
      ObjectNameLabel.Caption := 'Interface Name';
      ObjectNameLabel.Visible := True;
      ObjectNameEditBox.Visible := True;
      ObjectNameEditBox.Text := 'NewInterfaceName';
      ModuleNameEdit.Text:='';
    end;

    2:
    begin
      DescriptionLabel.Caption := 'Create a D empty Enum';
      ObjectNameLabel.Caption := 'Enum Name';
      ObjectNameLabel.Visible := True;
      ObjectNameEditBox.Visible := True;
      ObjectNameEditBox.Text := 'NewEnumName';
      ModuleNameEdit.Text:='';
    end;
    3:
    begin
      DescriptionLabel.Caption := 'Create a D main Unit';
      ObjectNameLabel.Visible := False;
      ObjectNameEditBox.Visible := False;
      ModuleNameEdit.Text:='';
    end;
    4:
    begin
      DescriptionLabel.Caption := 'Create a D empty Unit';
      ObjectNameLabel.Visible := False;
      ObjectNameEditBox.Visible := False;
      ModuleNameEdit.Text:='';
    end;
    5:
    begin
      DescriptionLabel.Caption := 'Create a D runnable Unit';
      ObjectNameLabel.Visible := False;
      ObjectNameEditBox.Visible := False;
      ModuleNameEdit.Text:='runnable';

    end;

  end;

end;

end.
