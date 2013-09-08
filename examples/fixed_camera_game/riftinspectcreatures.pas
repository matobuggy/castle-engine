{
  Copyright 2007-2013 Michalis Kamburelis.

  This file is part of "the rift".

  "the rift" is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  "the rift" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with "the rift"; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  ----------------------------------------------------------------------------
}

{ }
unit RiftInspectCreatures;

interface

procedure InspectCreatures;

implementation

uses CastleWindowModes, CastleCameras, CastleGLUtils, CastleWindow, GL, CastleVectors, SysUtils,
  CastleBitmapFont_BVSansMono_Bold_m15, CastleGLBitmapFonts,
  Classes, CastleStringUtils, CastleMessages, CastleFilesUtils,
  RiftVideoOptions, RiftGame, RiftWindow, RiftCreatures, CastleControlsImages,
  CastleUIControls, RiftSceneManager, CastleColors, CastleKeysMouse, CastleControls;

var
  Creature: TCreature;
  UserQuit: boolean;
  SceneManager: TRiftSceneManager;

{ TStatusText ---------------------------------------------------------------- }

type
  TStatusText = class(TCastleLabel)
    procedure Draw; override;
  end;

procedure TStatusText.Draw;
var
  Pos, Dir, Up: TVector3Single;
begin
  if not GetExists then Exit;

  { regenerate Text contents at every Draw call }
  Text.Clear;
  SceneManager.Camera.GetView(Pos, Dir, Up);
  Text.Append(Format('Camera: pos %s, dir %s, up %s',
    [ VectorToNiceStr(Pos), VectorToNiceStr(Dir), VectorToNiceStr(Up) ]));
  Text.Append(Format('World time : %f', [WorldTime]));
  Text.Append(Format('Creature state : %s', [CreatureStateName[Creature.State]]));

  inherited;
end;

var
  StatusText: TStatusText;

procedure Press(Sender: TCastleWindowBase; const Event: TInputPressRelease);

  procedure ChangeState(NewState: TCreatureState);
  begin
    try
      Creature.State := NewState;
    except
      on E: ECreatureStateChangeNotPossible do
        MessageOk(Window, E.Message);
    end;
  end;

begin
  if Event.EventType = itKey then
    case Event.KeyCharacter of
      CharEscape: UserQuit := true;
      'h': (SceneManager.Camera as TWalkCamera).GoToInitial;
      's': ChangeState(csStand);
      'w': ChangeState(csWalk);
      'b': ChangeState(csBored);
      else
        case Event.Key of
          K_F5: Window.SaveScreen(FileNameAutoInc('rift_screen_%d.png'));
        end;
    end;
end;

procedure Update(Window: TCastleWindowBase);
begin
  WorldTime += Window.Fps.UpdateSecondsPassed;
end;

procedure InspectCreatures;
var
  SavedMode: TGLMode;
begin
  WorldTime := 0;

  SavedMode := TGLMode.CreateReset(Window, 0, nil, nil, @NoClose);
  try
    Window.FpsShowOnCaption := DebugMenuFps;
    Window.AutoRedisplay := true;

    SceneManager := TRiftSceneManager.Create(nil);
    Window.Controls.Add(SceneManager);

    SceneManager.Camera := TWalkCamera.Create(SceneManager);
    (SceneManager.Camera as TWalkCamera).Init(
      Vector3Single(3, 3, 4),
      Vector3Single(-1, -1, -1),
      Vector3Single(0, 0, 1) { this will be corrected for ortho to dir, don't worry },
      Vector3Single(0, 0, 1),
      0, 0.1);
    (SceneManager.Camera as TWalkCamera).MoveSpeed := 2.5;

    CreaturesKinds.Load(SceneManager.BaseLights);
    { TODO: allow to choose creature }
    Creature := TCreature.Create(PlayerKind);
    try
      Creature.Direction := Vector3Single(1, 0, 0);
      Creature.Up := Vector3Single(0, 0, 1);
      SceneManager.Items.Add(Creature);

      StatusText := TStatusText.Create(Window);
      StatusText.Padding := 5;
      StatusText.Left := 5;
      StatusText.Bottom := 5;
      StatusText.Color := Vector3Byte(255, 255, 0);
      Window.Controls.InsertFront(StatusText);

      Window.OnPress := @Press;
      Window.OnUpdate := @Update;

      Window.EventResize;

      UserQuit := false;
      repeat
        Application.ProcessMessage(true, true);
      until UserQuit;

    finally FreeAndNil(SavedMode); end;
  finally
    FreeAndNil(SceneManager);
    FreeAndNil(Creature);
  end;
end;

initialization
  Theme.Images[tiLabel] := FrameYellowBlack;
  Theme.Corners[tiLabel] := Vector4Integer(1, 1, 1, 1);
end.
