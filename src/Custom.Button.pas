unit Custom.Button;

interface

uses FMX.Objects, System.Classes, FMX.Graphics, System.UITypes, FMX.Types,
  FMX.Controls, Custom.Button.Image, System.Types, FMX.MultiView, FMX.ListBox,
  FMX.Ani;

type
  TTypeEffect = (Border, Text, ColorButton);
  TButtonStyle = (Buttom, DropDown);

  TButtonDropDownItem = class(TCollectionItem)
  private
    FName   : String;
    FOnClick: TNotifyEvent;
    FText   : String;
    FVisible: Boolean;
    function GetName: String;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;

  published
    property Index;
    property Name: String read GetName write FName;
    property Text: String read FText write FText;
    property Visible: Boolean read FVisible write FVisible;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

  TButtonDropDown = class(TCollection)

  end;

  TButtonOnDropDownChange = procedure(const ASender: TObject; const AItemSelected: TListBoxItem) of object;
  TButtonOnBeforeDropDownItem = procedure(const AItem: TListBoxItem) of object;

  TButtonEffect = class(TRectangle)
  private
    FText, FTextOriginal : String;
    FTextSettingsInfo    : TTextSettingsInfo;
    FTypeEffect          : TTypeEffect;
    FEffectTextColor     : TAlphaColor;
    FFontColorDefault    : TAlphaColor;
    FButtonColorDefault  : TAlphaColor;
    FEffectButtonColor   : TAlphaColor;
    FAutoSize            : Boolean;
    FStyle               : TButtonStyle;
    FDropDown            : TButtonDropDown;
    FOnDropDownChange    : TButtonOnDropDownChange;
    FIconDropDown        : TBitmap;
    FMultiView           : TMultiView;
    FShowMaster          : Boolean;
    FList                : TListBox;
    FOnBeforeDropDownItem: TButtonOnBeforeDropDownItem;
    FShowTextItemSelected: Boolean;
    FFloatAnimation      : TFloatAnimation;
    FColorAnimation      : TColorAnimation;

    procedure SetTextSettings(const Value: TTextSettings);
    procedure ActiveEffect;
    procedure DeactiveEffect;
    procedure NewSize;
    procedure SetStyledSettings(const Value: TStyledSettings);
    procedure LoadIconDropDown;
    procedure OnItemClick(const ASender: TCustomListBox; const AItem: TListBoxItem);
    procedure OnStartShowing(ASender: TObject);

    function GetStyledSettings: TStyledSettings;
    function StyledSettingsStored: Boolean;
    function GetTextSettings: TTextSettings;

  protected
    procedure DoPaint; override;
    procedure DoEnter; override;
    procedure DoMouseEnter; override;
    procedure DoExit; override;
    procedure DoMouseLeave; override;
    procedure FillChanged(Sender: TObject); override;
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState; X: Single; Y: Single); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ForceColor;
    procedure BeforeDestruction; override;

  published
    property Text                : String read FText write FText;
    property TextSettings        : TTextSettings read GetTextSettings write SetTextSettings;
    property TypeEffect          : TTypeEffect read FTypeEffect write FTypeEffect;
    property EffectTextColor     : TAlphaColor read FEffectTextColor write FEffectTextColor;
    property EffectButtonColor   : TAlphaColor read FEffectButtonColor write FEffectButtonColor;
    property AutoSize            : Boolean read FAutoSize write FAutoSize default False;
    property StyledSettings      : TStyledSettings read GetStyledSettings write SetStyledSettings stored StyledSettingsStored nodefault;
    property Style               : TButtonStyle read FStyle write FStyle;
    property DropDown            : TButtonDropDown read FDropDown write FDropDown;
    property OnDropDownChange    : TButtonOnDropDownChange read FOnDropDownChange write FOnDropDownChange;
    property OnBeforeDropDownItem: TButtonOnBeforeDropDownItem read FOnBeforeDropDownItem write FOnBeforeDropDownItem;
    property ShowTextItemSelected: Boolean read FShowTextItemSelected write FShowTextItemSelected;
  end;

  TButtonEffectList = TArray<TButtonEffect>;

  procedure Register;

implementation

uses
  FMX.StdCtrls, System.SysUtils, FMX.Consts, FMX.TextLayout,
  System.Threading, System.NetEncoding;

type
  TTextControlSettingsInfo = class(TTextSettingsInfo)
  private
    [Weak]
    FTextControl: TPresentedTextControl;
  protected
    procedure DoCalculatedTextSettings; override;
  public
    constructor Create(AOwner: TPersistent; ATextSettingsClass: TTextSettingsInfo.TCustomTextSettingsClass); override;
    destructor Destroy; override;

    property TextControl: TPresentedTextControl read FTextControl;
  end;

  TTextControlTextSettings = class(TTextSettingsInfo.TCustomTextSettings)
  published
    property Font;
    property FontColor;
  end;

  { TButtonEffect }

procedure TButtonEffect.ActiveEffect;
begin
  case TypeEffect of
    Border:
      begin
        FFloatAnimation.PropertyName := 'Stroke.Thickness';
        FFloatAnimation.Duration     := 0.1;
        FFloatAnimation.StopValue    := 2.5;
        FFloatAnimation.Start;
      end;
    TTypeEffect.Text:
      begin
        FColorAnimation.PropertyName := 'TextSettings.FontColor';
        FColorAnimation.Duration     := 0.1;
        FColorAnimation.StopValue    := Self.EffectTextColor;
        FColorAnimation.Start;
      end;
    ColorButton:
      begin
        FColorAnimation.PropertyName := 'Fill.Color';
        FColorAnimation.Duration     := 0.1;
        FColorAnimation.StopValue    := Self.EffectButtonColor;
        FColorAnimation.Start;
        FFloatAnimation.PropertyName := 'Stroke.Thickness';
        FFloatAnimation.Duration     := 0.1;
        FFloatAnimation.StopValue    := 2.5;
        FFloatAnimation.Start;
      end;
  end;
end;

procedure TButtonEffect.BeforeDestruction;
begin
  inherited;
  TAnimator.StopPropertyAnimation(Self, 'Stroke.Thickness');
  TAnimator.StopPropertyAnimation(Self, 'Fill.Color');
  TAnimator.StopPropertyAnimation(Self, 'TextSettings.FontColor');
end;

constructor TButtonEffect.Create(AOwner: TComponent);
begin
  inherited;
  Self.XRadius                     := 3.5;
  Self.YRadius                     := 3.5;
  Self.Stroke.Thickness            := 0;
  Self.Fill.Color                  := $FF219EBC;
  Self.Stroke.Color                := $FF023047;
  Self.FEffectButtonColor          := $FF023047;
  Self.Cursor                      := crHandPoint;
  Self.Height                      := 55;
  Self.Width                       := 55;
  Self.Text                        := 'Button';
  FShowTextItemSelected            := True;
  FTextSettingsInfo                := TTextControlSettingsInfo.Create(Self, TTextControlTextSettings);
  Self.TextSettings.FontColor      := TAlphaColorRec.White;
  Self.TextSettings.Font.Size      := 13.5;
  Self.TextSettings.VertAlign      := TTextAlign.Center;
  Self.TextSettings.HorzAlign      := TTextAlign.Center;
  Self.CanFocus                    := True;
  FFontColorDefault                := TAlphaColorRec.Null;
  FButtonColorDefault              := TAlphaColorRec.Null;
  FDropDown                        := TButtonDropDown.Create(TButtonDropDownItem);
  FMultiView                       := TMultiView.Create(nil);
  FMultiView.Mode                  := TMultiViewMode.Popover;
  FMultiView.OnStartShowing        := Self.OnStartShowing;
  FList                            := TListBox.Create(nil);
  FList.Parent                     := FMultiView;
  FList.Align                      := TAlignLayout.Contents;
  FList.StyleLookup                := 'transparentlistboxstyle';
  FList.OnItemClick                := OnItemClick;
  FList.ItemHeight                 := 30;
  FList.Cursor                     := crHandPoint;
  FFloatAnimation                  := TFloatAnimation.Create(Self);
  FFloatAnimation.Parent           := Self;
  FFloatAnimation.StartFromCurrent := True;
  FColorAnimation                  := TColorAnimation.Create(Self);
  FColorAnimation.Parent           := Self;
  FColorAnimation.StartFromCurrent := True;

  FColorAnimation.SetSubComponent(True);
  FFloatAnimation.SetSubComponent(True);
  FList.SetSubComponent(True);
  FMultiView.SetSubComponent(True);
end;

procedure TButtonEffect.DeactiveEffect;
begin
  if csDestroying in Self.ComponentState then
    Exit;

  case TypeEffect of
    Border:
      begin
        FFloatAnimation.PropertyName := 'Stroke.Thickness';
        FFloatAnimation.Duration     := 0.1;
        FFloatAnimation.StopValue    := 0;
        FFloatAnimation.Start;
      end;
    TTypeEffect.Text:
      begin
        FColorAnimation.PropertyName := 'TextSettings.FontColor';
        FColorAnimation.Duration     := 0.1;
        FColorAnimation.StopValue    := FFontColorDefault;
        FColorAnimation.Start;
      end;
    ColorButton:
      begin
        FColorAnimation.PropertyName := 'Fill.Color';
        FColorAnimation.Duration     := 0.1;
        FColorAnimation.StopValue    := FButtonColorDefault;
        FColorAnimation.Start;
        FFloatAnimation.PropertyName := 'Stroke.Thickness';
        FFloatAnimation.Duration     := 0.1;
        FFloatAnimation.StopValue    := 0;
        FFloatAnimation.Start;
      end;
  end;
end;

destructor TButtonEffect.Destroy;
begin
  FreeAndNil(FTextSettingsInfo);
  FDropDown.Free;
  FIconDropDown.Free;
  FList.Clear;
  FreeAndNil(FList);
  FreeAndNil(FMultiView);
  FFloatAnimation.Free;
  FColorAnimation.Free;
  inherited;
end;

procedure TButtonEffect.DoEnter;
begin
  inherited;
  ActiveEffect;
end;

procedure TButtonEffect.DoExit;
begin
  inherited;
  DeactiveEffect;
end;

procedure TButtonEffect.DoMouseEnter;
begin
  inherited;
  ActiveEffect;
end;

procedure TButtonEffect.DoMouseLeave;
begin
  inherited;
  DeactiveEffect;
end;

procedure TButtonEffect.DoPaint;
begin
  inherited;
  if csDestroying in Self.ComponentState then
    Exit;

  Self.Canvas.Fill.Color    := Self.TextSettings.FontColor;
  Self.Canvas.Font.Family   := Self.TextSettings.Font.Family;
  Self.Canvas.Font.Size     := Self.TextSettings.Font.Size;
  Self.Canvas.Font.Style    := Self.TextSettings.Font.Style;
  Self.Canvas.Font.StyleExt := Self.TextSettings.Font.StyleExt;

  var LRect := Self.GetShapeRect;

  if (Self.Style = TButtonStyle.DropDown) then
  begin
    if FIconDropDown = nil then
      LoadIconDropDown;

    LRect.Right := LRect.Right - 25;

    var LRectImageDrop := TRectF.Create(0, 0, FIconDropDown.Width, FIconDropDown.Height);
    var LRectDest      := TRectF.Create(LRect.Right + 2, (LRect.Height /2) - (LRect.Height/ 4), LRect.Right + 20, ((LRect.Height) / 2) + (LRect.Height) / 4);

    Self.Canvas.BeginScene;
    try
      FIconDropDown.ReplaceOpaqueColor(Self.TextSettings.FontColor);
      Self.Canvas.DrawBitmap(FIconDropDown, LRectImageDrop, LRectDest, Self.Opacity);
    finally
      Self.Canvas.EndScene;
    end;
  end;

  Self.Canvas.FillText(LRect, Self.Text, Self.TextSettings.WordWrap, Self.Opacity, [TFillTextFlag.RightToLeft], Self.TextSettings.HorzAlign,
    Self.TextSettings.VertAlign);

  NewSize;
end;

procedure TButtonEffect.FillChanged(Sender: TObject);
begin
  inherited;
  if (FButtonColorDefault = TAlphaColorRec.Null) then
    FButtonColorDefault := Self.Fill.Color;
end;

procedure TButtonEffect.ForceColor;
begin
  FButtonColorDefault := Self.Fill.Color;
end;

function TButtonEffect.GetStyledSettings: TStyledSettings;
begin
  Result := FTextSettingsInfo.StyledSettings;
end;

function TButtonEffect.GetTextSettings: TTextSettings;
begin
  Result := FTextSettingsInfo.TextSettings;
end;

procedure TButtonEffect.LoadIconDropDown;
begin
  FIconDropDown := TBitmap.Create(20, 20);

  var LBytes  := TBytesStream.Create(TNetEncoding.Base64.DecodeStringToBytes(cImage));
  try
    FIconDropDown.LoadFromStream(LBytes);
  finally
    LBytes.Free;
  end;
end;

procedure TButtonEffect.MouseClick(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single);
begin
  inherited;
  if (Self.Style = TButtonStyle.DropDown) and ((X >= (Self.Width - 25)) and (X <= Self.Width)) then
  begin
    if FShowMaster then
    begin
      FMultiView.HideMaster;
      FMultiView.MasterButton := nil;
    end
    else
    begin
      FMultiView.MasterButton := Self;
      FMultiView.ShowMaster;
    end;

    FShowMaster := not FShowMaster;
  end;
end;

procedure TButtonEffect.NewSize;
var
  LText: TTextLayout;
begin
  if not AutoSize and not (csDestroying in Self.ComponentState) then
    Exit;

  LText               := TTextLayoutManager.DefaultTextLayout.Create;
  try
    LText.Font     := Self.TextSettings.Font;
    LText.TopLeft  := TPointF.Create(0, 0);
    LText.text     := Self.text;
    LText.WordWrap := Self.TextSettings.WordWrap;

    if (LText.Width + 16 > Self.Width) then
      Self.Width := LText.Width + 16;
  finally
    LText.Free;
  end;
end;

procedure TButtonEffect.OnItemClick(const ASender: TCustomListBox;
  const AItem: TListBoxItem);
begin
  if AItem.Index <= Self.DropDown.Count - 1 then
  begin
    var LItem := Self.DropDown.Items[AItem.Index] as TButtonDropDownItem;

    if Assigned(LItem.OnClick) then
      LItem.OnClick(Self);
  end;

  if Assigned(FOnDropDownChange) then
    FOnDropDownChange(Self, AItem);

  if ShowTextItemSelected then
  begin
    if FTextOriginal.Trim.IsEmpty then
      FTextOriginal := FText;

    Self.Text := FTextOriginal;
    if not AItem.Text.Trim.IsEmpty then
      Self.Text := AItem.Text;
  end;

  FMultiView.HideMaster;
  FMultiView.MasterButton := nil;
  FShowMaster             := False;
  Self.Repaint;
end;

procedure TButtonEffect.OnStartShowing(ASender: TObject);
begin
  FList.Clear;

  var LAssigned := Assigned(FOnBeforeDropDownItem);

  for var LItem in Self.DropDown do
  begin
    FList.Items.Add(TButtonDropDownItem(LItem).Text);
    FList.ListItems[LItem.Index].Font.Size      := 13.5;
    FList.ListItems[LItem.Index].Font.Family    := 'Quicksand';
    FList.ListItems[LItem.Index].StyledSettings := [TStyledSetting.Style, TStyledSetting.FontColor];
    FList.ListItems[LItem.Index].Visible        := TButtonDropDownItem(LItem).Visible;

    if LAssigned then
      FOnBeforeDropDownItem(FList.ListItems[LItem.Index]);
  end;

  FList.Items.Add('');
end;

procedure Register;
begin
  RegisterComponents('Custom Components', [TButtonEffect]);
end;

procedure TButtonEffect.SetStyledSettings(const Value: TStyledSettings);
begin
  FTextSettingsInfo.StyledSettings := Value;
end;

procedure TButtonEffect.SetTextSettings(const Value: TTextSettings);
begin
  FTextSettingsInfo.TextSettings.Assign(Value);

  if FFontColorDefault = TAlphaColorRec.Null then
    FFontColorDefault := Value.FontColor;
end;

function TButtonEffect.StyledSettingsStored: Boolean;
begin
  Result := StyledSettings <> DefaultStyledSettings;
end;

{ TTextControlSettingsInfo }

constructor TTextControlSettingsInfo.Create(AOwner: TPersistent; ATextSettingsClass: TTextSettingsInfo.TCustomTextSettingsClass);
begin
  inherited;
  FTextControl := TPresentedTextControl.Create(nil);
end;

destructor TTextControlSettingsInfo.Destroy;
begin
  FTextControl.Free;
  inherited;
end;

procedure TTextControlSettingsInfo.DoCalculatedTextSettings;
begin
  inherited;
  FTextControl.Change;
end;

{ TButtonDropDownItem }

constructor TButtonDropDownItem.Create(Collection: TCollection);
begin
  inherited;
  FVisible := True;
  FText    := GetDisplayName;
end;

function TButtonDropDownItem.GetDisplayName: string;
begin
  Result := Name;
end;

function TButtonDropDownItem.GetName: String;
begin
  Result := FName;

  if FName.Trim.IsEmpty then
    Result := Self.ClassName + Self.Index.ToString;
end;

end.

