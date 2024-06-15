unit uVars;

interface

const
  BS           = 32;
  ScreenWidth  = 30;
  ScreenHeight = 20;
  CellSize     = 32;

  //
  HalfScreenWidth = ScreenWidth div 2;
  HalfScreenHeight = ScreenHeight div 2;

  // Blocks
  bDirt        = 2;
  bGrass       = 3;
  bSand        = 18;
  bStone       = 1;
  bCStone      = 16;
  bGravel      = 19;
  bWood        = 20;
  bLeaves      = 52;
  bPapirus     = 73;
  bPumpkin     = 119;
  bCactus      = 70;
  bRose        = 12;
  bDandelion   = 13;
  bMushroom1   = 28;
  bMushroom2   = 29;
  bLadder      = 83; 
  bBoard       = 4;
  bCoal        = 34;
  bIronOre     = 33;
  bTorch       = 80;
  bNet         = 11;
  bWaterMelon  = 136;
  bWhiteWool   = 64;
       
  // Door
  bDoor1       = 81;
  bDoor2       = 81 + 16;
  bOpenDoor1   = 222;
  bOpenDoor2   = 223;

  // Special blocks
  bSky         = 0;
  bBase        = 255;

  // Block items
  iRose        = 12;
  iDandelion   = 13;
  iMushroom1   = 28;
  iMushroom2   = 29;
  iStairway    = 83;
  iBoard       = 4;
  iIronOre     = 33;
  iTorch       = 80;
  iNet         = 11;
  iWhiteWool   = 64;

  // Adv items
  iCoal        = 7   + 256;
  iDoor        = 43  + 256;
  iThread      = 264;

  // Food
  iWaterMelon  = 365;
  iRedApple    = 266;
  iSoup        = 328;
  
  // Weapon
  iSwordWood   = 64  + 256;
  iSwordStone  = 65  + 256;
  iSwordIron   = 66  + 256;
  iBow         = 21  + 256;

  // Tools
  iPickaxWood  = 96  + 256;
  iPickaxStone = 97  + 256;
  iPickaxIron  = 98  + 256;
  iShovelWood  = 80  + 256;
  iShovelStone = 81  + 256;
  iShovelIron  = 82  + 256;
  iAxeWood     = 112 + 256;
  iAxeStone    = 113 + 256;
  iAxeIron     = 114 + 256;

type
  TBaseCraft = array [0..8] of Integer;

var
  IsDrawInfo: Boolean = False;
  IsTransparent: Boolean = True;
  IsGameGrid: Boolean = False;
  IsGameSound: Boolean = False;
  TimerBlockID: Integer;
  Path: string = '';
  
var
  PX: Integer = -1;
  PY: Integer = -1;
  PL: Integer = 0;

function DataPath: string;
function SavePath: string;
function SoundPath: string;

implementation

function DataPath: string;
begin
  Result := Path + '\Data\';
end;

function SavePath: string;
begin
  Result := Path + '\Save\';
end;

function SoundPath: string;
begin
  Result := Path + '\Data\Sound\';
end;

initialization
  Randomize;
  GetDir(0, Path);
  Path := Path + '\..\';

end.
