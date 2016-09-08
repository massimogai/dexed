unit ce_projinspect;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, TreeFilterEdit, Forms, Controls, Graphics, actnlist,
  Dialogs, ExtCtrls, ComCtrls, Menus, Buttons, lcltype, ce_nativeproject, ce_interfaces,
  ce_common, ce_widget, ce_observer, ce_dialogs, ce_sharedres, ce_dsgncontrols;

type

  { TCEProjectInspectWidget }

  TCEProjectInspectWidget = class(TCEWidget, ICEProjectObserver)
    btnAddFile: TCEToolButton;
    btnAddFold: TCEToolButton;
    btnRemFile: TCEToolButton;
    btnRemFold: TCEToolButton;
    imgList: TImageList;
    Tree: TTreeView;
    TreeFilterEdit1: TTreeFilterEdit;
    procedure btnAddFileClick(Sender: TObject);
    procedure btnAddFoldClick(Sender: TObject);
    procedure btnRemFileClick(Sender: TObject);
    procedure btnRemFoldClick(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const fnames: array of String);
    procedure TreeClick(Sender: TObject);
    procedure TreeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TreeSelectionChanged(Sender: TObject);
  protected
    procedure updateImperative; override;
    procedure updateDelayed; override;
    procedure SetVisible(value: boolean); override;
    procedure setToolBarFlat(value: boolean); override;
  private
    fActOpenFile: TAction;
    fActSelConf: TAction;
    fActBuildConf: TAction;
    fProject: TCENativeProject;
    fFileNode, fConfNode: TTreeNode;
    fImpsNode, fInclNode: TTreeNode;
    fXtraNode: TTreeNode;
    fLastFileOrFolder: string;
    fSymStringExpander: ICESymStringExpander;
    procedure actUpdate(sender: TObject);
    procedure TreeDblClick(sender: TObject);
    procedure actOpenFileExecute(sender: TObject);
    procedure actBuildExecute(sender: TObject);
    //
    procedure projNew(project: ICECommonProject);
    procedure projClosing(project: ICECommonProject);
    procedure projFocused(project: ICECommonProject);
    procedure projChanged(project: ICECommonProject);
    procedure projCompiling(project: ICECommonProject);
    procedure projCompiled(project: ICECommonProject; success: boolean);
  protected
    function contextName: string; override;
    function contextActionCount: integer; override;
    function contextAction(index: integer): TAction; override;
  public
    constructor create(aOwner: TComponent); override;
    destructor destroy; override;
  end;

implementation
{$R *.lfm}

{$REGION Standard Comp/Obj------------------------------------------------------}
constructor TCEProjectInspectWidget.create(aOwner: TComponent);
begin
  fSymStringExpander:= getSymStringExpander;
  //
  fActOpenFile := TAction.Create(self);
  fActOpenFile.Caption := 'Open file in editor';
  fActOpenFile.OnExecute := @actOpenFileExecute;
  fActSelConf := TAction.Create(self);
  fActSelConf.Caption := 'Select configuration';
  fActSelConf.OnExecute := @actOpenFileExecute;
  fActSelConf.OnUpdate := @actUpdate;
  fActBuildConf:= TAction.Create(self);
  fActBuildConf.Caption := 'Build configuration';
  fActBuildConf.OnExecute := @actBuildExecute;
  fActBuildConf.OnUpdate := @actUpdate;
  //
  inherited;
  //
  Tree.OnDblClick := @TreeDblClick;
  fFileNode := Tree.Items[0];
  fConfNode := Tree.Items[1];
  fImpsNode := Tree.Items[2];
  fInclNode := Tree.Items[3];
  fXtraNode := Tree.Items[4];
  //
  Tree.PopupMenu := contextMenu;
  //
  EntitiesConnector.addObserver(self);
end;

destructor TCEProjectInspectWidget.destroy;
begin
  EntitiesConnector.removeObserver(self);
  inherited;
end;

procedure TCEProjectInspectWidget.SetVisible(value: boolean);
begin
  inherited;
  if value then updateImperative;
end;

procedure TCEProjectInspectWidget.setToolBarFlat(value: boolean);
begin
  inherited setToolBarFlat(value);
  TreeFilterEdit1.Flat:=value;
end;
{$ENDREGION}

{$REGION ICEContextualActions---------------------------------------------------}
function TCEProjectInspectWidget.contextName: string;
begin
  exit('Inspector');
end;

function TCEProjectInspectWidget.contextActionCount: integer;
begin
  exit(3);
end;

function TCEProjectInspectWidget.contextAction(index: integer): TAction;
begin
  case index of
    0: exit(fActOpenFile);
    1: exit(fActSelConf);
    2: exit(fActBuildConf);
    else exit(nil);
  end;
end;

procedure TCEProjectInspectWidget.actOpenFileExecute(sender: TObject);
begin
  TreeDblClick(sender);
end;

procedure TCEProjectInspectWidget.actBuildExecute(sender: TObject);
begin
  if fProject.isNotNil then
  begin
    actOpenFileExecute(sender);
    fProject.compile;
  end;
end;
{$ENDREGION}

{$REGION ICEProjectMonitor -----------------------------------------------------}
procedure TCEProjectInspectWidget.projNew(project: ICECommonProject);
begin
  fProject := nil;
  enabled := false;
  fLastFileOrFolder := '';
  if project.getFormat <> pfNative then
    exit;
  enabled := true;
  //
  fProject := TCENativeProject(project.getProject);
  if Visible then updateImperative;
end;

procedure TCEProjectInspectWidget.projClosing(project: ICECommonProject);
begin
  if fProject.isNil then exit;
  if fProject <> project.getProject then
    exit;
  fProject := nil;
  fLastFileOrFolder := '';
  enabled := false;
  updateImperative;
end;

procedure TCEProjectInspectWidget.projFocused(project: ICECommonProject);
begin
  fProject := nil;
  enabled := false;
  fLastFileOrFolder := '';
  if project.getFormat <> pfNative then
  begin
    updateImperative;
    exit;
  end;
  enabled := true;
  //
  fProject := TCENativeProject(project.getProject);
  if Visible then beginDelayedUpdate;
end;

procedure TCEProjectInspectWidget.projChanged(project: ICECommonProject);
begin
  if fProject.isNil then exit;
  if fProject <> project.getProject then
    exit;
  if Visible then beginDelayedUpdate;
end;

procedure TCEProjectInspectWidget.projCompiling(project: ICECommonProject);
begin
end;

procedure TCEProjectInspectWidget.projCompiled(project: ICECommonProject; success: boolean);
begin
end;
{$ENDREGION}

{$REGION Inspector things -------------------------------------------------------}
procedure TCEProjectInspectWidget.TreeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
    TreeDblClick(nil);
end;

procedure TCEProjectInspectWidget.TreeClick(Sender: TObject);
begin
  if Tree.Selected.isNotNil then
  begin
    Tree.MultiSelect := Tree.Selected.Parent = fFileNode;
    if not (Tree.Selected.Parent = fFileNode) then
    begin
      Tree.MultiSelect := false;
      Tree.ClearSelection(true);
      Tree.Selected.MultiSelected:=false;
    end;
  end
  else
  begin
    Tree.MultiSelect := false;
    Tree.ClearSelection(true);
  end;
end;

procedure TCEProjectInspectWidget.TreeSelectionChanged(Sender: TObject);
begin
  actUpdate(sender);
  if fProject.isNil or Tree.Selected.isNil then
    exit;
  if (Tree.Selected.Parent = fFileNode) then
    fLastFileOrFolder := expandFilenameEx(fProject.basePath,tree.Selected.Text)
  else
    fLastFileOrFolder := tree.Selected.Text;
end;

procedure TCEProjectInspectWidget.TreeDblClick(sender: TObject);
var
  fname: string;
  i, j: integer;
begin
  if fProject.isNil or Tree.Selected.isNil then
    exit;
  //
  if (Tree.Selected.Parent = fFileNode) or (Tree.Selected.Parent = fXtraNode) then
  begin
    for j:= 0 to Tree.SelectionCount-1 do
    begin
      fname := Tree.Selections[j].Text;
      i := fProject.Sources.IndexOf(fname);
      if i > -1 then
        fname := fProject.sourceAbsolute(i);
      if isEditable(fname.extractFileExt) and fname.fileExists then
        getMultiDocHandler.openDocument(fname);
    end;
  end
  else if Tree.Selected.Parent = fConfNode then
  begin
    i := Tree.Selected.Index;
    fProject.ConfigurationIndex := i;
    beginDelayedUpdate;
  end;
end;

procedure TCEProjectInspectWidget.actUpdate(sender: TObject);
begin
  fActSelConf.Enabled := false;
  fActOpenFile.Enabled := false;
  fActBuildConf.Enabled:= false;
  if Tree.Selected.isNil then exit;
  fActSelConf.Enabled := Tree.Selected.Parent = fConfNode;
  fActBuildConf.Enabled := Tree.Selected.Parent = fConfNode;
  fActOpenFile.Enabled := Tree.Selected.Parent = fFileNode;
end;

procedure TCEProjectInspectWidget.btnAddFileClick(Sender: TObject);
var
  fname: string;
begin
  if fProject.isNil then exit;
  //
  with TOpenDialog.Create(nil) do
  try
    options := options + [ofAllowMultiSelect];
    if fLastFileOrFolder.fileExists then
      InitialDir := fLastFileOrFolder.extractFilePath
    else if fLastFileOrFolder.dirExists then
      InitialDir := fLastFileOrFolder;
    filter := DdiagFilter;
    if execute then
    begin
      fProject.beginUpdate;
      for fname in Files do
        fProject.addSource(fname);
      fProject.endUpdate;
    end;
  finally
    free;
  end;
end;

procedure TCEProjectInspectWidget.btnAddFoldClick(Sender: TObject);
var
  dir, fname: string;
  lst: TStringList;
  i: NativeInt;
begin
  if fProject.isNil then exit;
  //
  dir := '';
  if fLastFileOrFolder.fileExists then
    dir := fLastFileOrFolder.extractFilePath
  else if fLastFileOrFolder.dirExists then
    dir := fLastFileOrFolder
  else if fProject.fileName.fileExists then
    dir := fProject.fileName.extractFilePath;
  if selectDirectory('sources', dir, dir, true, 0) then
  begin
    fProject.beginUpdate;
    lst := TStringList.Create;
    try
      listFiles(lst, dir, true);
      for i := 0 to lst.Count-1 do
      begin
        fname := lst[i];
        if isDlangCompilable(fname.extractFileExt) then
          fProject.addSource(fname);
      end;
    finally
      lst.Free;
      fProject.endUpdate;
    end;
  end;
end;

procedure TCEProjectInspectWidget.btnRemFoldClick(Sender: TObject);
var
  dir, fname: string;
  i: Integer;
begin
  if fProject.isNil or Tree.Selected.isNil then
    exit;
  if Tree.Selected.Parent <> fFileNode then exit;
  //
  fname := Tree.Selected.Text;
  i := fProject.Sources.IndexOf(fname);
  if i = -1 then exit;
  fname := fProject.sourceAbsolute(i);
  dir := fname.extractFilePath;
  if not dir.dirExists then exit;
  //
  fProject.beginUpdate;
  for i:= fProject.Sources.Count-1 downto 0 do
    if fProject.sourceAbsolute(i).extractFilePath = dir then
      fProject.Sources.Delete(i);
  fProject.endUpdate;
end;

procedure TCEProjectInspectWidget.btnRemFileClick(Sender: TObject);
var
  fname: string;
  i, j: integer;
begin
  if fProject.isNil or Tree.Selected.isNil then
    exit;
  //
  if Tree.Selected.Parent = fFileNode then
  begin
    fProject.beginUpdate;
    for j:= 0 to Tree.SelectionCount-1 do
    begin
      fname := Tree.Selections[j].Text;
      i := fProject.Sources.IndexOf(fname);
      if i <> -1 then
        fProject.Sources.Delete(i);
    end;
    fProject.endUpdate;
  end;
end;

procedure TCEProjectInspectWidget.FormDropFiles(Sender: TObject; const fnames: array of String);
procedure addFile(const value: string);
var
  ext: string;
begin
  ext := value.extractFileExt;
  if not isDlangCompilable(ext) then
    exit;
  fProject.addSource(value);
  if isEditable(ext) then
    getMultiDocHandler.openDocument(value);
end;
var
  fname, direntry: string;
  lst: TStringList;
begin
  if fProject.isNil then exit;
  lst := TStringList.Create;
  fProject.beginUpdate;
  try for fname in fnames do
    if fname.fileExists then
      addFile(fname)
    else if fname.dirExists then
    begin
      lst.Clear;
      listFiles(lst, fname, true);
      for direntry in lst do
        addFile(dirEntry);
    end;
  finally
    fProject.endUpdate;
    lst.Free;
  end;
end;

procedure TCEProjectInspectWidget.updateDelayed;
begin
  updateImperative;
end;

procedure TCEProjectInspectWidget.updateImperative;
var
  src, fold, conf, str: string;
  lst: TStringList;
  itm: TTreeNode;
  i: NativeInt;
begin
  fConfNode.DeleteChildren;
  fFileNode.DeleteChildren;
  fImpsNode.DeleteChildren;
  fInclNode.DeleteChildren;
  fXtraNode.DeleteChildren;
  //
  if fProject.isNil then
    exit;
  //
  Tree.BeginUpdate;
  // display main sources
  for src in fProject.Sources do
  begin
    itm := Tree.Items.AddChild(fFileNode, src);
    itm.ImageIndex := 2;
    itm.SelectedIndex := 2;
  end;
  // display configurations
  for i := 0 to fProject.OptionsCollection.Count-1 do
  begin
    conf := fProject.configuration[i].name;
    if i = fProject.ConfigurationIndex then conf += ' (active)';
    itm := Tree.Items.AddChild(fConfNode, conf);
    if i = fProject.ConfigurationIndex then
    begin
      itm.ImageIndex := 7;
      itm.SelectedIndex:= 7;
    end
    else
    begin
      itm.ImageIndex := 3;
      itm.SelectedIndex:= 3;
    end;
  end;
  // display Imports (-J)
  for str in FProject.currentConfiguration.pathsOptions.importStringPaths do
  begin
    if str.isEmpty then
      continue;
    fold := expandFilenameEx(fProject.basePath, str);
    fold := fSymStringExpander.expand(fold);
    itm := Tree.Items.AddChild(fImpsNode, fold);
    itm.ImageIndex := 5;
    itm.SelectedIndex := 5;
  end;
  fImpsNode.Collapse(false);
  // display Includes (-I)
  for str in FProject.currentConfiguration.pathsOptions.importModulePaths do
  begin
    if str.isEmpty then
      continue;
    fold := expandFilenameEx(fProject.basePath, str);
    fold := fSymStringExpander.expand(fold);
    itm := Tree.Items.AddChild(fInclNode, fold);
    itm.ImageIndex := 5;
    itm.SelectedIndex := 5;
  end;
  fInclNode.Collapse(false);
  // display extra sources (external .lib, *.a, *.d)
  for str in FProject.currentConfiguration.pathsOptions.extraSources do
  begin
    if str.isEmpty then
      continue;
    src := expandFilenameEx(fProject.basePath, str);
    src := fSymStringExpander.expand(src);
    lst := TStringList.Create;
    try
      if listAsteriskPath(src, lst) then for src in lst do
      begin
        itm := Tree.Items.AddChild(fXtraNode, src);
        itm.ImageIndex := 2;
        itm.SelectedIndex := 2;
      end else
      begin
        itm := Tree.Items.AddChild(fXtraNode, src);
        itm.ImageIndex := 2;
        itm.SelectedIndex := 2;
      end;
    finally
      lst.Free;
    end;
  end;
  fXtraNode.Collapse(false);
  Tree.EndUpdate;
end;
{$ENDREGION --------------------------------------------------------------------}

end.
