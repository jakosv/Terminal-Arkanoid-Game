unit pasgame;
interface
type
    ShapeColors = (SBlack, SBlue, SGreen, SCyan, SRed, SMagenta, SBrown,
        SLightGray, SDarkGray, SLightBlue, SLightGreen, SLightCyan, SLightRed,
        SLightMagenta, SYellow, SWhite);
    ShapePtr = ^Shape;
    Shape = record
        x, y, height, width: integer;
        Color, BgColor: ShapeColors;
        symbol: char;
    end;


function CreateShape(height, width, x, y: integer; 
    color, BgColor: ShapeColors; symbol: char): ShapePtr;
procedure SetShapePos(TempShapePtr: ShapePtr; NewX, NewY: integer);
procedure SetShapeSize(TempShapePtr: ShapePtr; NewHeight, NewWidth: integer);
procedure SetShapeColor(TempShapePtr: ShapePtr; NewColor: ShapeColors);
procedure SetShapeBgColor(TempShapePtr: ShapePtr; NewBgColor: ShapeColors);
procedure SetShapeSymbol(TempShapePtr: ShapePtr; NewSymbol: char);
procedure MoveShape(TempShapePtr: ShapePtr; dx, dy: integer);
function CheckCollision(TempShapePtr: ShapePtr): boolean;
function GetCollision(TempShapePtr: ShapePtr): ShapePtr;
procedure AddShape(NewShapePtr: ShapePtr);
procedure RemoveShape(TempShapePtr: ShapePtr);
procedure InitPasGame(NewFieldHeight, NewFieldWidth: integer);
procedure SetFrameRate(NewFrameRate: integer);
procedure Draw();
function GetFieldHeight(): integer;
function GetFieldWidth(): integer;
procedure ClearScreen();
procedure GetKey(var code: integer);
function CheckEvent(): boolean;


implementation
uses crt;
const
    FieldColor = SLightGray;
    FieldBgColor = SBlack;
type
    ShapeItemPtr = ^ShapeItem; 
    ShapeItem = record
        data: ShapePtr;
        next: ShapeItemPtr; 
    end;
var
    FieldWidth, FieldHeight, StartX, StartY: integer;
    FieldSymbol: char;
    ListOfShapes: ShapeItemPtr;
    FrameRate, DelayValue: integer;

procedure LOSInit(var list: ShapeItemPtr);
begin
    list := nil;
end;

procedure LOSAdd(NewShapePtr: ShapePtr);
var
    tmp: ShapeItemPtr;
begin
    new(tmp);
    tmp^.data := NewShapePtr;
    tmp^.next := ListOfShapes;
    ListOfShapes := tmp;
end;

procedure LOSRemove(TempShapePtr: ShapePtr);
var
    PtrToItem: ^ShapeItemPtr;
    tmp: ShapeItemPtr;
begin
    PtrToItem := @ListOfShapes;
    while PtrToItem <> nil do 
    begin
        if PtrToItem^^.data = TempShapePtr then
        begin
            tmp := PtrToItem^;
            PtrToItem^ := PtrToItem^^.next;
            dispose(tmp);
            exit;
        end
        else
            PtrToItem := @(PtrToItem^^.next);
    end
end;

function CreateShape(height, width, x, y: integer; color, BgColor: 
    ShapeColors; symbol: char): ShapePtr;
var
    NewShapePtr: ShapePtr;
begin
    new(NewShapePtr);
    NewShapePtr^.x := x;
    NewShapePtr^.y := y;
    NewShapePtr^.height := height;
    NewShapePtr^.width := width;
    NewShapePtr^.color := color;
    NewShapePtr^.BgColor := BgColor;
    NewShapePtr^.symbol := symbol;
    CreateShape := NewShapePtr;
end;

procedure SetShapePos(TempShapePtr: ShapePtr; NewX, NewY: integer);
begin
    TempShapePtr^.x := NewX;
    TempShapePtr^.y := NewY;
end;

procedure SetShapeSize(TempShapePtr: ShapePtr; NewHeight, NewWidth: integer);
begin
    TempShapePtr^.height := NewHeight;
    TempShapePtr^.width := NewWidth;
end;

procedure SetShapeColor(TempShapePtr: ShapePtr; NewColor: ShapeColors);
begin
    TempShapePtr^.color := NewColor;
end;

procedure SetShapeBgColor(TempShapePtr: ShapePtr; NewBgColor: ShapeColors);
begin
    TempShapePtr^.BgColor := NewBgColor;
end;

procedure SetShapeSymbol(TempShapePtr: ShapePtr; NewSymbol: char);
begin
    TempShapePtr^.symbol := NewSymbol;
end;

procedure MoveShape(TempShapePtr: ShapePtr; dx, dy: integer);
begin
    TempShapePtr^.x := TempShapePtr^.x + dx;
    TempShapePtr^.y := TempShapePtr^.y + dy;
end;

function CheckShapesCollision(first, second: ShapePtr): boolean;
var
    TempX, TempY: integer; 
begin
    for TempX:=first^.x to (first^.x + first^.width - 1) do
        for TempY:=first^.y to (first^.y + first^.height - 1) do
        begin
            if ((TempX >= second^.x) and 
                (TempX <= (second^.x + second^.width - 1)))
                and 
                ((TempY >= second^.Y) and 
                (TempY <= (second^.y + second^.height - 1))) then
            begin
                CheckShapesCollision := true;
                exit;
            end;
        end;
    CheckShapesCollision := false;
end;

function CheckCollision(TempShapePtr: ShapePtr): boolean;
var
    tmp: ShapeItemPtr;
begin
    tmp := ListOfShapes;
    while tmp <> nil do
    begin
        if TempShapePtr = tmp^.data then
        begin
            tmp := tmp^.next;
            continue;
        end;
        if CheckShapesCollision(TempShapePtr, tmp^.data) then
        begin
            CheckCollision := true;
            exit;
        end;
        tmp := tmp^.next;
    end;
    CheckCollision := false;
end;

function GetCollision(TempShapePtr: ShapePtr): ShapePtr;
var
    tmp: ShapeItemPtr;
begin
    tmp := ListOfShapes;
    while tmp <> nil do
    begin
        if TempShapePtr = tmp^.data then
        begin
            tmp := tmp^.next;
            continue;
        end;
        if CheckShapesCollision(TempShapePtr, tmp^.data) then
        begin
            GetCollision := tmp^.data;
            exit;
        end;
        tmp := tmp^.next;
    end;
    GetCollision := nil; 
end;

procedure AddShape(NewShapePtr: ShapePtr);
begin
    LOSAdd(NewShapePtr);
end;

procedure RemoveShape(TempShapePtr: ShapePtr);
begin
    LOSRemove(TempShapePtr); 
end;

procedure InitPasGame(NewFieldHeight, NewFieldWidth: integer);
begin
    FieldHeight := NewFieldHeight;
    FieldWidth := NewFieldWidth;
    StartY := (ScreenHeight - (FieldHeight)) div 2;
    StartX := (ScreenWidth - (FieldWidth)) div 2;
    LOSInit(ListOfShapes);
    SetFrameRate(20);
end;

function GetCRTColor(color: ShapeColors): byte;
begin
    GetCRTColor := byte(color);
end;

procedure DrawSymbol(x, y: integer; color, BgColor: ShapeColors; symbol: char);
begin
    GotoXY(x, y);
    TextColor(GetCRTColor(color));
    TextBackground(GetCRTColor(BgColor));
    write(symbol);
end;

procedure DrawLine(size, x, y: integer; color, BgColor: ShapeColors; 
    symbol: char);
var
    i: integer;
begin
    GotoXY(x, y);
    TextColor(GetCRTColor(color));
    TextBackground(GetCrtColor(BgColor));
    for i:=1 to size do
        write(symbol); 
end;

procedure DrawShape(var TempShape: Shape);
var
    i, NormalHeight, NormalWidth, NormalX, NormalY: integer;
begin
    NormalHeight := TempShape.height;
    NormalWidth := TempShape.width;
    NormalX := TempShape.x + StartX - 1;
    NormalY := TempShape.y + StartY - 1;
    for i:=1 to NormalHeight do
        DrawLine(NormalWidth, NormalX, NormalY + i - 1, 
            TempShape.color, TempShape.BgColor, TempShape.symbol);
end;

procedure DrawShapes();
var
    tmp: ShapeItemPtr;
begin
    tmp := ListOfShapes; 
    while tmp <> nil do
    begin
        DrawShape(tmp^.data^);
        tmp := tmp^.next;
    end;
end;

procedure SetFrameRate(NewFrameRate: integer);
begin
    FrameRate := NewFrameRate;
    DelayValue := 1000 div FrameRate;
end;

procedure Draw();
var
    i: integer;
begin
    clrscr;
    {
    DrawLine(FieldWidth, StartX, StartY, FieldColor, FieldBgColor, 
        FieldSymbol);
    for i:=1 to FieldHeight-2 do
    begin
        DrawSymbol(StartX, StartY + i, FieldColor, FieldBgColor, FieldSymbol);
        DrawSymbol(StartX + FieldWidth - 1, StartY + i, FieldColor, 
            FieldBgColor, FieldSymbol);
    end;
    DrawLine(FieldWidth, StartX, StartY + FieldHeight - 1, FieldColor,
        FieldBgColor, FieldSymbol);
    }
    DrawShapes();
    write(#27'[0m'); {reset terminal}
    GotoXY(1, 1);
    delay(DelayValue);
end;

function GetFieldHeight(): integer;
begin
    GetFieldHeight := FieldHeight;
end;

function GetFieldWidth(): integer;
begin
    GetFieldWidth := FieldWidth;
end;

procedure GetKey(var code: integer);
var
    c: char;
begin
    c := ReadKey;
    if c = #0 then
    begin
        c := ReadKey;
        code := -ord(c);
    end
    else
    begin
        code := ord(c);
    end
end;

function CheckEvent(): boolean;
begin
    CheckEvent := keypressed;
end;

procedure ClearScreen();
begin
    clrscr;
end;

end.
