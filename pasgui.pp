unit pasgui;
interface

type
    AlignType = (CenterAlign, RightAlign);
    MenuItemPtr = ^MenuItem;
    MenuItem = record
        data: string;
        next: MenuItemPtr;
        prev: MenuItemPtr;
    end;
    TMenuPtr = ^TMenu;
    TMenu = record
        FirstItem: MenuItemPtr;  
        LastItem: MenuItemPtr;  
        SelectedItem: MenuItemPtr;
        ItemsCount, MaxItemSize: integer;
    end;

procedure ShowMessage(var str: string);
function CreateMenu: TMenuPtr;
procedure AddMenuItem(str: string; menu: TMenuPtr);
procedure ShowMenu(menu: TMenuPtr);
function GetSelectedItem(menu: TMenuPtr): string;

implementation
uses crt;

const
    WindowVerticalPadding = 1;
    WindowHorizontalPadding = 4;
    WindowMaxRowSize = 50;
    WindowBackgroundColor = Blue;
    WindowTextColor = Yellow;
    SelectionBackgroundColor = Yellow;
    SelectionColor = Black;
    MaxRowSize = 30;

type
    TWindowPtr = ^TWindow;
    TWindow = record
        width, height, RowsCount, RowSize, x, y: integer;
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

function CreateWindow(RowsCount, RowSize: integer): TWindowPtr;
var
    NewWindow: TWindowPtr;
begin
    new(NewWindow);
    NewWindow^.width := RowSize + 2 * WindowHorizontalPadding;
    NewWindow^.height := RowsCount + 2 * WindowVerticalPadding;
    NewWindow^.RowsCount := RowsCount;
    NewWindow^.RowSize := RowSize;
    NewWindow^.x := (ScreenWidth - NewWindow^.width) div 2;
    NewWindow^.y := (ScreenHeight - NewWindow^.height) div 2;
    CreateWindow := NewWindow;
end;

procedure DrawWindow(window: TWindowPtr);
var
    i, j: integer;
begin
    TextColor(WindowTextColor);
    TextBackground(WindowBackgroundColor);
    GotoXY(window^.x, window^.y);
    for i:=1 to window^.height do
    begin
        for j:=1 to window^.width do
            write(' ');
        GotoXY(window^.x, window^.y + i);
    end;
end;

procedure DrawRow(str: string; RowNumber: integer; color, BgColor: word; 
    align: AlignType; window: TWindowPtr);
var
    x, y, StrLength: integer;
begin
    StrLength := length(str);
    if StrLength > MaxRowSize then
        StrLength := MaxRowSize;
    case align of
        CenterAlign:
            x := window^.x + (window^.width - StrLength) div 2; 
        RightAlign:
            x := window^.x + WindowHorizontalPadding;
    end;
    y := window^.y + WindowVerticalPadding + RowNumber - 1;
    GotoXY(x, y);
    TextColor(color);
    TextBackground(BgColor);
    write(str);
    GotoXY(1, 1);
    write(#27'[0m');
end;

procedure ShowMessage(var str: string);
var
    i, RowsCount, RowSize, KeyNumber: integer;
    window: ^TWindow;
begin
    RowsCount := length(str) div MaxRowSize + 1;
    RowSize := length(str);
    if RowSize > MaxRowSize then
        RowSize := MaxRowSize;
    window := CreateWindow(RowsCount, RowSize);   
    DrawWindow(window);
    for i:=1 to RowsCount do
        DrawRow(copy(str, (i-1) * RowSize + 1, RowSize), i, WindowTextColor,
            WindowBackgroundColor, RightAlign, window);
    GotoXY(1, 1);
    repeat
    begin
        GetKey(KeyNumber);
    end until KeyNumber = 13;
    dispose(window);
    write(#27'[0m');
end;

function CreateMenu: TMenuPtr;
var
    NewMenu: TMenuPtr;
begin
    new(NewMenu);
    NewMenu^.FirstItem := nil;
    NewMenu^.LastItem := nil;
    NewMenu^.SelectedItem := nil;
    NewMenu^.ItemsCount := 0;
    NewMenu^.MaxItemSize := 0;
    CreateMenu := NewMenu;
end;

procedure AddMenuItem(str: string; menu: TMenuPtr);
var
    tmp: MenuItemPtr;
begin
    new(tmp);
    if menu^.FirstItem = nil then
        menu^.FirstItem := tmp
    else
        menu^.LastItem^.next := tmp;
    tmp^.data := str;
    tmp^.next := nil;
    tmp^.prev := menu^.LastItem;
    menu^.LastItem := tmp;
    if menu^.SelectedItem = nil then
        menu^.SelectedItem := menu^.FirstItem;
    menu^.ItemsCount := menu^.ItemsCount + 1;
    if length(str) > menu^.MaxItemSize then
        menu^.MaxItemSize := length(str);
end;

procedure DrawMenu(menu: TMenuPtr; window: TWindowPtr);
var
    RowNumber: integer;
    tmp: MenuItemPtr;
begin
    RowNumber := 1;
    tmp := menu^.FirstItem;
    while tmp <> nil do
    begin
        if tmp = menu^.SelectedItem then
            DrawRow(tmp^.data, RowNumber, SelectionColor, 
                SelectionBackgroundColor, CenterAlign, window)
        else
            DrawRow(tmp^.data, RowNumber, WindowTextColor, 
                WindowBackGroundColor, CenterAlign, window);
        tmp := tmp^.next;
        RowNumber := RowNumber + 1;
    end;
end;

procedure SelectNextItem(menu: TMenuPtr);
begin
    menu^.SelectedItem := menu^.SelectedItem^.next;
    if menu^.SelectedItem = nil then
        menu^.SelectedItem := menu^.FirstItem;
end;

procedure SelectPrevItem(menu: TMenuPtr);
begin
    menu^.SelectedItem := menu^.SelectedItem^.prev;
    if menu^.SelectedItem = nil then
        menu^.SelectedItem := menu^.LastItem;
end;

function GetSelectedItem(menu: TMenuPtr): string;
begin
    GetSelectedItem := menu^.SelectedItem^.data;
end;

procedure ShowMenu(menu: TMenuPtr);
var
    window: TWindowPtr;
    KeyCode: integer;
begin
    window := CreateWindow(menu^.ItemsCount, menu^.MaxItemSize);
    DrawWindow(window);
    while true do
    begin
        DrawMenu(menu, window);
        GetKey(KeyCode);
        case KeyCode of
            -72:
                SelectPrevItem(menu);
            -80:
                SelectNextItem(menu);
            13:
                break
        end
    end;
end;

end.
