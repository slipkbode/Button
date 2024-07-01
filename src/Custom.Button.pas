unit Custom.Button;

interface

uses FMX.Objects, System.Classes, FMX.Graphics, System.UITypes, FMX.Types,
  FMX.Controls;

type
  TTypeEffect = (Border, Text, ColorButton);

  TButtonEffect = class(TRectangle)
  private
    FText              : String;
    FTextSettingsInfo  : TTextSettingsInfo;
    FTypeEffect        : TTypeEffect;
    FEffectTextColor   : TAlphaColor;
    FFontColorDefault  : TAlphaColor;
    FButtonColorDefault: TAlphaColor;
    FEffectButtonColor : TAlphaColor;
    FAutoSize          : Boolean;

    function GetTextSettings: TTextSettings;

    procedure SetTextSettings(const Value: TTextSettings);
    procedure ActiveEffect;
    procedure DeactiveEffect;
    procedure NewSize;
    function GetStyledSettings: TStyledSettings;
    procedure SetStyledSettings(const Value: TStyledSettings);
    function StyledSettingsStored: Boolean;

  protected
    procedure DoPaint; override;
    procedure DoEnter; override;
    procedure DoMouseEnter; override;
    procedure DoExit; override;
    procedure DoMouseLeave; override;
    procedure FillChanged(Sender: TObject); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ForceColor;

  published
    property Text             : String read FText write FText;
    property TextSettings     : TTextSettings read GetTextSettings write SetTextSettings;
    property TypeEffect       : TTypeEffect read FTypeEffect write FTypeEffect;
    property EffectTextColor  : TAlphaColor read FEffectTextColor write FEffectTextColor;
    property EffectButtonColor: TAlphaColor read FEffectButtonColor write FEffectButtonColor;
    property AutoSize         : Boolean read FAutoSize write FAutoSize default False;
    property StyledSettings   : TStyledSettings read GetStyledSettings write SetStyledSettings stored StyledSettingsStored nodefault;
  end;

  TButtonEffectList = TArray<TButtonEffect>;

  procedure Register;

implementation

uses
  FMX.StdCtrls, System.SysUtils, FMX.Consts, FMX.Ani, FMX.TextLayout,
  System.Threading, System.Types;

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
  TTask.Run(
    procedure
    begin
      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          case TypeEffect of
            Border:
              begin
                TAnimator.AnimateFloat(Self, 'Stroke.Thickness', 2.5);
              end;
            TTypeEffect.Text:
              begin
                TAnimator.AnimateColor(Self, 'TextSettings.FontColor', Self.EffectTextColor);
              end;
            ColorButton:
              begin
                TAnimator.AnimateColor(Self, 'Fill.Color', Self.EffectButtonColor);
                TAnimator.AnimateFloat(Self, 'Stroke.Thickness', 2.5);
              end;
          end;
        end
      )
    end
  )
end;

constructor TButtonEffect.Create(AOwner: TComponent);
begin
  inherited;
  Self.XRadius                := 3.5;
  Self.YRadius                := 3.5;
  Self.Stroke.Thickness       := 0;
  Self.Fill.Color             := $FF219EBC;
  Self.Stroke.Color           := $FF023047;
  Self.FEffectButtonColor     := $FF023047;
  Self.Cursor                 := crHandPoint;
  Self.Height                 := 55;
  Self.Width                  := 55;
  Self.Text                   := 'Button';
  FTextSettingsInfo           := TTextControlSettingsInfo.Create(Self, TTextControlTextSettings);
  Self.TextSettings.FontColor := TAlphaColorRec.White;
  Self.TextSettings.Font.Size := 13.5;
  Self.TextSettings.VertAlign := TTextAlign.Center;
  Self.TextSettings.HorzAlign := TTextAlign.Center;
  Self.CanFocus               := True;
  FFontColorDefault           := TAlphaColorRec.Null;
  FButtonColorDefault         := TAlphaColorRec.Null;
end;

procedure TButtonEffect.DeactiveEffect;
begin
  TTask.Run(
    procedure
    begin
      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          case TypeEffect of
            Border:
              begin
                TAnimator.AnimateFloat(Self, 'Stroke.Thickness', 0);
              end;
            TTypeEffect.Text:
              begin
                TAnimator.AnimateColor(Self, 'TextSettings.FontColor', FFontColorDefault);
              end;
            ColorButton:
              begin
                TAnimator.AnimateColor(Self, 'Fill.Color', FButtonColorDefault);
                if not Self.IsFocused then
                  TAnimator.AnimateFloat(Self, 'Stroke.Thickness', 0);
              end;
          end;
        end
      )
    end
  )
end;

destructor TButtonEffect.Destroy;
begin
  FreeAndNil(FTextSettingsInfo);
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

  Self.Canvas.FillText(Self.GetShapeRect, Self.Text, Self.TextSettings.WordWrap, Self.Opacity, [TFillTextFlag.RightToLeft], Self.TextSettings.HorzAlign,
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

end.

