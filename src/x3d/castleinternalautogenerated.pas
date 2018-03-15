{
  Copyright 2018-2018 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Information about auto-generated resources (TAutoGenerated). }
unit CastleInternalAutoGenerated;

{$I castleconf.inc}

interface

uses Generics.Collections;

type
  { Information about auto-generated resources, right now: auto-generated
    compressed and downscaled textures.
    See https://castle-engine.io/creating_data_auto_generated_textures.php .
    This information is read and written by the CGE build tool.
    It may also be accessed during the game by the engine, automatically
    (e.g. by CastleMaterialProperties). }
  TAutoGenerated = class
  private
    type
      TTexture = class
        Url: string;
        Hash: string;
      end;
      TTextureList = {$ifdef CASTLE_OBJFPC}specialize{$endif} TObjectList<TTexture>;
    var
      Textures: TTextureList;

    function GetLastProcessedHash(const Url: string): string;
    procedure SetLastProcessedHash(const Url, Hash: string);
    { Get existing, or create new, Texture for this Url. }
    function Texture(const Url: string): TTexture;
  public
    const
      FileName = 'castle_engine_auto_generated.xml';
      AutoGeneratedDirName = 'auto_generated';

    constructor Create;
    destructor Destroy; override;
    { Read or write the last_processed_hash associated with each resource URL,
      used to detect whether the auto-generated things need updating. }
    property LastProcessedHash [const Url: string]: string
      read GetLastProcessedHash write SetLastProcessedHash;

    procedure LoadFromFile(const Url: string);
    procedure SaveToFile(const Url: string);

    { Remove the entries for no longer existing input files.
      TODO: In the future, it should also remove the auto-generated output
      for the no-longer-existing input files. }
    procedure CleanNotExisting(const ProjectDataUrl: string; const Verbose: boolean);
  end;

implementation

uses SysUtils, DOM,
  CastleUtils, CastleXMLUtils, CastleURIUtils;

constructor TAutoGenerated.Create;
begin
  inherited;
  Textures := TTextureList.Create;
end;

destructor TAutoGenerated.Destroy;
begin
  FreeAndNil(Textures);
  inherited;
end;

function TAutoGenerated.Texture(const Url: string): TTexture;
begin
  for Result in Textures do
    if Result.Url = Url then
      Exit;

  Result := TTexture.Create;
  Result.Url := Url;
  Textures.Add(Result);
end;

function TAutoGenerated.GetLastProcessedHash(const Url: string): string;
var
  T: TTexture;
begin
  T := Texture(Url);
  Result := T.Hash;
end;

procedure TAutoGenerated.SetLastProcessedHash(const Url, Hash: string);
var
  T: TTexture;
begin
  T := Texture(Url);
  T.Hash := Hash;
end;

procedure TAutoGenerated.SaveToFile(const Url: string);
var
  Doc: TXMLDocument;
  RootElement, TexturesElement, TextureElement: TDOMElement;
  T: TTexture;
  Comment: TDOMComment;
begin
  Doc := TXMLDocument.Create;

  Comment := Doc.CreateComment(
    'DO NOT EDIT THIS FILE MANUALLY.' + NL +
    'It is automatically created/updated.' + NL +
    NL +
    'This file describes the state of files inside auto_generated' + NL +
    'subdirectories of game data.' + NL +
    'This file should be created and updated only by the Castle Game Engine' + NL +
    'build tool, using commands like "castle-engie auto-generate-textures".' + NL +
    'These commands update things inside auto_generated subdirectories,' + NL +
    '*and* they update the ' + FileName + ' file.' + NL +
    NL +
    'If you transfer the auto_generated subdirectories (e.g. if you commit' + NL +
    'them to the version control repository), then you should also' + NL +
    'transfer (commit) the appropriate ' + FileName + ' file along.' + NL +
    'Otherwise (e.g. if you ignore the auto_generated subdirectories' + NL +
    'in version control), then ignore this file too.' + NL +
    NL +
    'Game code may assume that if some aute-generated files are present,' + NL +
    'then the ApplicationData(''' + FileName + ''') file exists,' + NL +
    'describing them.' + NL);
  Doc.AppendChild(Comment);

  RootElement := Doc.CreateElement('auto_generated');
  Doc.AppendChild(RootElement);

  TexturesElement := RootElement.CreateChild('textures');

  for T in Textures do
  begin
    TextureElement := TexturesElement.CreateChild('texture');
    TextureElement.AttributeSet('url', T.Url);
    TextureElement.AttributeSet('last_processed_content_hash', T.Hash);
  end;

  URLWriteXML(Doc, Url);
end;

procedure TAutoGenerated.LoadFromFile(const Url: string);
var
  Doc: TXMLDocument;
  T: TTexture;
  I: TXMLElementIterator;
begin
  Textures.Clear;

  { If the file does not exist yet,
    then we have no information about auto-generated resources
    (all LastProcessedHash is ''), which is OK. }
  if not URIFileExists(Url) then
    Exit;

  Doc := URLReadXML(Url);

  I := Doc.DocumentElement.Child('textures').ChildrenIterator('texture');
  try
    while I.GetNext do
    begin
      T := TTexture.Create;
      Textures.Add(T);
      T.Url := I.Current.AttributeString('url');
      T.Hash := I.Current.AttributeString('last_processed_content_hash');
    end;
  finally FreeAndNil(I) end;
end;

procedure TAutoGenerated.CleanNotExisting(const ProjectDataUrl: string;
  const Verbose: boolean);
var
  I: Integer;
  T: TTexture;
  TextureUrl, AutoGeneratedDirUrl: string;
begin
  I := 0;
  while I < Textures.Count do
  begin
    T := Textures[I];
    TextureUrl := CombineURI(ProjectDataUrl, T.Url);
    if not URIFileExists(TextureUrl) then
    begin
      AutoGeneratedDirUrl := ExtractURIPath(TextureUrl) + AutoGeneratedDirName + '/';
      if Verbose then
        Writeln(Format(
          'Texture "%s" no longer exists, removing the record about it from "%s".' + NL +
          'Be sure to also remove the output for this texture inside the "%s" directory (if exists), as we cannot do it automatically now.',
          [TextureUrl, FileName, AutoGeneratedDirUrl]));
      Textures.Delete(I);
    end else
      Inc(I);
  end;
end;

end.
