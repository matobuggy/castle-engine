{
  Copyright 2021 Trung Le (Kagamma).

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Example how to use TGLSLProgram.SetTransformFeedbackVaryings }

program transform_feedback;

{$macro on}
{$define nl:=+ LineEnding +}

uses
  GL, GLExt,
  CastleVectors, X3DNodes, CastleWindow, CastleLog,
  CastleUtils, SysUtils, CastleApplicationProperties,
  CastleViewport, CastleTimeUtils, CastleGLShaders;

const
  VertexArray: packed array[0..2] of TVector2 = (
    (Data: (-1, 0)), (Data: (1, 0)), (Data: (0, 1))
  );
  TransformFeedbackVertexShaderSource: String =
'#version 330'nl
'layout(location = 0) in vec2 inVertex;'nl
'out vec2 outVertex;'nl
'float atan2(vec2 v) {'nl
'  return v.x == 0.0 ? sign(v.y) * 3.1415 / 2.0 : atan(v.y, v.x);'nl
'}'nl
'void main() {'nl
'  float a = atan2(inVertex) + 0.01;'nl
'  outVertex = vec2(cos(a), sin(a));'nl
'}';

  RenderVertexShaderSource: String =
'#version 330'nl
'layout(location = 0) in vec2 inVertex;'nl
'void main() {'nl
'  gl_Position = vec4(inVertex, 0.0, 1.0);'nl
'}';

  RenderFragmentShaderSource: String =
'#version 330'nl
'out vec4 outColor;'nl
'void main() {'nl
'  outColor = vec4(1.0);'nl
'}';

var
  Window: TCastleWindowBase;
  Viewport: TCastleViewport;
  VAOs,
  VBOs: array[0..1] of GLint;
  RenderProgram,
  TransformFeedbackProgram: TGLSLProgram;
  PingPong: Integer = 0;

procedure Update(Container: TUIContainer);
var
  I: Integer;
begin
  if TransformFeedbackProgram = nil then
  begin
    glGenVertexArrays(2, @VAOs[0]);
    glGenBuffers(2, @VBOs[0]);
    for I := 0 to 1 do
    begin
      glBindVertexArray(VAOs[I]);
      glBindBuffer(GL_ARRAY_BUFFER, VBOs[I]);
      glBufferData(GL_ARRAY_BUFFER, SizeOf(TVector2) * Length(VertexArray), @VertexArray[0], GL_STATIC_DRAW);
      glEnableVertexAttribArray(0);
      glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, SizeOf(TVector2), Pointer(0));
    end;

    RenderProgram := TGLSLProgram.Create;
    RenderProgram.AttachVertexShader(RenderVertexShaderSource);
    RenderProgram.AttachFragmentShader(RenderFragmentShaderSource);
    RenderProgram.Link;

    TransformFeedbackProgram := TGLSLProgram.Create;
    TransformFeedbackProgram.AttachVertexShader(TransformFeedbackVertexShaderSource);
    // Tell OpenGL 'outVertex' is our feedback varying
    TransformFeedbackProgram.SetTransformFeedbackVaryings(['outVertex']);
    TransformFeedbackProgram.Link;
  end;
end;

procedure Render(Container: TUIContainer);
begin
  // Update vertices
  { Some drivers may complain about program not having fragment shader if we
    don't disable rasterizer first before switch to transform & feedback program }
  glEnable(GL_RASTERIZER_DISCARD);
  TransformFeedbackProgram.Enable;
  glBindVertexArray(VAOs[(PingPong + 1) mod 2]);
  glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, VBOs[PingPong]);
  glBeginTransformFeedback(GL_TRIANGLES);
  glDrawArrays(GL_TRIANGLES, 0, 3);
  glEndTransformFeedback();
  glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, 0);
  glDisable(GL_RASTERIZER_DISCARD);

  // Render triangle
  RenderProgram.Enable;
  glBindVertexArray(VAOs[PingPong]);
  glDrawArrays(GL_TRIANGLES, 0, 3);

  // Ping-pong between the 2 buffers
  PingPong := (PingPong + 1) mod 2;
end;

begin
  InitializeLog;

  Window := TCastleWindowBase.Create(Application);
  Window.Open;

  Viewport := TCastleViewport.Create(Application);
  Viewport.FullSize := True;
  Window.Controls.InsertFront(Viewport);

  Window.OnUpdate := @Update;
  Window.OnRender := @Render;
  Application.Run;
end.
