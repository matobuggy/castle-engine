{ -*- buffer-read-only: t -*-

  Copyright 2015-2017 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Automatically generated node properties.

  Do not edit this file manually!
  To add new properties, add them to text files in nodes_specification/components/ ,
  and regenerate include files by running
  nodes_specification/generate_x3d_nodes_to_pascal.lpr .

  The documentation for properties should go to x3dnodes_documentation.txt . }

{$ifdef read_interface}

  private
    function GetAxisOfRotation: TVector3Single;
    procedure SetAxisOfRotation(const Value: TVector3Single);
  public
    property AxisOfRotation: TVector3Single read GetAxisOfRotation write SetAxisOfRotation;

{$endif read_interface}

{$ifdef read_implementation}

{ TBillboardNode ----------------------------------------------- }

function TBillboardNode.GetAxisOfRotation: TVector3Single;
begin
  Result := FdAxisOfRotation.Value;
end;

procedure TBillboardNode.SetAxisOfRotation(const Value: TVector3Single);
begin
  FdAxisOfRotation.Send(Value);
end;

{$endif read_implementation}