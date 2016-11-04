{
  Copyright 2004-2016 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Converting fonts (TTextureFontData) to Pascal source code. }
unit CastleFont2Pascal;

{$I castleconf.inc}

interface

uses CastleTextureFontData, Classes;

{ @noAutoLinkHere }
procedure Font2Pascal(const Font: TTextureFontData;
  const UnitName, PrecedingComment, FontFunctionName: string; Stream: TStream);
  overload;

{ @noAutoLinkHere }
procedure Font2Pascal(const Font: TTextureFontData;
  const UnitName, PrecedingComment, FontFunctionName: string;
  const OutURL: string); overload;

implementation

uses SysUtils, CastleUtils, CastleStringUtils, CastleClassUtils, CastleDownload,
  CastleUnicode;

{ WriteUnit* ---------------------------------------------------------- }

procedure WriteUnitBegin(Stream: TStream; const UnitName, PrecedingComment,
  UsesUnitName, FontFunctionName, FontTypeName: string);
begin
  WriteStr(Stream,
    '{ -*- buffer-read-only: t -*- }' +NL+
    NL+
    '{ Unit automatically generated by ' + ApplicationName + ',' +NL+
    '  to embed font data in Pascal source code.' +NL+
    '  @exclude (Exclude this unit from PasDoc documentation.)' +NL+
    NL+
    PrecedingComment+
    '}' +NL+
    'unit ' + UnitName + ';' +NL+
    NL+
    'interface'+NL+
    NL+
    'uses ' + UsesUnitName + ';' +NL+
    NL+
    'function ' + FontFunctionName + ': ' + FontTypeName + ';' +NL+
    NL+
    'implementation' +NL+
    NL+
    'uses SysUtils, CastleImages;' + NL+
    NL+
    'var' +NL+
    '  FFont: ' + FontTypeName + ';' +NL+
    '' +NL+
    'function ' + FontFunctionName + ': ' + FontTypeName + ';' +NL+
    'begin' +NL+
    '  Result := FFont;' +NL+
    'end;' +NL+
    nl
    );
end;

{ Font2Pascal ----------------------------------------------------- }

procedure Font2Pascal(const Font: TTextureFontData;
  const UnitName, PrecedingComment, FontFunctionName: string; Stream: TStream);
var
  C: TUnicodeChar;
  G: TTextureFontData.TGlyph;
  ImageInterface, ImageImplementation, ImageInitialization, ImageFinalization: string;
  LoadedGlyphs: TUnicodeCharList;
begin
  WriteUnitBegin(Stream, UnitName, PrecedingComment,
    'CastleTextureFontData', FontFunctionName, 'TTextureFontData');

  ImageInterface := '';
  ImageImplementation := '';
  ImageInitialization := '';
  ImageFinalization := '';
  Font.Image.SaveToPascalCode('FontImage', true,
    ImageInterface, ImageImplementation, ImageInitialization, ImageFinalization);

  WriteStr(Stream,
    'procedure DoInitialization;' +NL+
    'var' +NL+
    '  Glyphs: TTextureFontData.TGlyphDictionary;' +NL+
    '  G: TTextureFontData.TGlyph;' +NL+
    ImageInterface +
    ImageImplementation +
    'begin' +NL+
    ImageInitialization +
    '  FontImage.TreatAsAlpha := true;' +NL+
    '  FontImage.URL := ''embedded-font:/' + UnitName + ''';' +NL+
    NL+
    '  Glyphs := TTextureFontData.TGlyphDictionary.Create;' +NL+
    NL);

  LoadedGlyphs := Font.LoadedGlyphs;
  try
    for C in LoadedGlyphs do
    begin
      G := Font.Glyph(C);
      if G <> nil then
      begin
        WriteStr(Stream,
          '  G := TTextureFontData.TGlyph.Create;' +NL+
          '  G.X := ' + IntToStr(G.X) + ';' +NL+
          '  G.Y := ' + IntToStr(G.Y) + ';' +NL+
          '  G.AdvanceX := ' + IntToStr(G.AdvanceX) + ';' +NL+
          '  G.AdvanceY := ' + IntToStr(G.AdvanceY) + ';' +NL+
          '  G.Width := ' + IntToStr(G.Width) + ';' +NL+
          '  G.Height := ' + IntToStr(G.Height) + ';' +NL+
          '  G.ImageX := ' + IntToStr(G.ImageX) + ';' +NL+
          '  G.ImageY := ' + IntToStr(G.ImageY) + ';' +NL+
          '  Glyphs[' + IntToStr(Ord(C)) + '] := G;' +NL+
          NL);
      end;
    end;
  finally FreeAndNil(LoadedGlyphs) end;

  WriteStr(Stream,
    '  FFont := TTextureFontData.CreateFromData(Glyphs, FontImage, ' +
      IntToStr(Font.Size) + ', ' +
      LowerCase(BoolToStr(Font.AntiAliased, true)) + ');' +NL+
    'end;' +NL+
    NL+
    'initialization' +NL+
    '  DoInitialization;' +NL+
    'finalization' +NL+
    '  FreeAndNil(FFont);' +NL+
    'end.' + NL);
end;

{ OutURL versions ---------------------------------------------------- }

procedure Font2Pascal(const Font: TTextureFontData;
  const UnitName, PrecedingComment, FontFunctionName: string;
  const OutURL: string); overload;
var
  Stream: TStream;
begin
  Stream := URLSaveStream(OutURL);
  try
    Font2Pascal(Font, UnitName, PrecedingComment, FontFunctionName, Stream);
  finally Stream.Free end;
end;

end.
