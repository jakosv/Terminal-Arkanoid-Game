program arkanoid;
uses pasgame, pasgui, Unix;
const
    FramesPerSecond = 60;
    DefaultBallSpeed = 12; {6}
    BonusSpeed = 6;
    FieldHeight = 20;
    FieldWidth = 20;
    BlockRowSize = FieldWidth - 2;
    BlockRows = FieldHeight div 3;
    BonusesCount = 5;
    BonusProbability = 5; { 1 / BonusProbability }
    WallColor = SLightGray;
    WallBgColor = SBlack;
    WallSymbol = '|';
type
    BallType = record
        BallShape: ShapePtr;
        dx, dy: integer;
    end;
    BonusTypes = (BTBall, BTPlatformSize, BTBombBalls, BTSlowBalls,
        BTFireBalls);
    BonusItemPtr = ^BonusItem;
    BonusItem = record
        BonusShape: ShapePtr;
        BonusType: BonusTypes;
        next: BonusItemPtr;
    end;
    {PlatformArray = array [1..PlatformSize] of ShapePtr;}
    BallItemPtr = ^BallItem;
    BallItem = record
        ball: BallType;
        next: BallItemPtr;
    end;
    BlocksArray = array [1..BlockRows, 1..BlockRowSize] of ShapePtr;
var
    time, BallsCount, BlocksCount, PlatformSize, PlatformBonusTime,
        BombBallsBonusTime, BallSpeed, SlowBallsBonusTime, 
        FireBallsBonusTime: integer;
    {platform: PlatformArray;}
    platform: ShapePtr;
    blocks: BlocksArray;
    ListOfBonuses: BonusItemPtr;
    ListOfBalls: BallItemPtr;
    ActiveBombBalls, ActiveFireBalls: boolean;

function GameOver: boolean;
begin
    GameOver := (ListOfBalls = nil) or (BlocksCount = 0);
end;

function GetRandomBonus: BonusTypes;
var
    n: integer;
begin
    n := random(BonusesCount) + 1;
    case n of
        1:
            GetRandomBonus := BTBall;
        2:
            GetRandomBonus := BTPlatformSize;
        3:
            GetRandomBonus := BTBombBalls;
        4:
            GetRandomBonus := BTSlowBalls;
        5:
            GetRandomBonus := BTFireBalls;
    end;
end;

function GetBonusSymbol(BonusType: BonusTypes): char;
begin
    case BonusType of
        BTBall:
            GetBonusSymbol := 'B';
        BTPlatformSize:
            GetBonusSymbol := 'P';
        BTBombBalls:
            GetBonusSymbol := 'T';
        BTSlowBalls:
            GetBonusSymbol := 'S';
        BTFireBalls:
            GetBonusSymbol := 'F';
    end;
end;

function CheckWallCollision(TempShape: ShapePtr): boolean;
begin
    CheckWallCollision :=
        (TempShape^.x + TempShape^.width - 1 >= GetFieldWidth) or 
        (TempShape^.x <= 1) or 
        (TempShape^.y + TempShape^.Height - 1 >= GetFieldHeight) or 
        (TempShape^.y <= 1);
end;

procedure BallPlatformCollision(var ball: BallType);
begin
    if ball.BallShape^.x = platform^.x then
    begin
        ball.dy := -1;
        ball.dx := -1;
    end
    else if ball.BallShape^.x = platform^.x + PlatformSize - 1 then
    begin
        ball.dy := -1;
        ball.dx := 1;
    end
    else
        ball.dy := -ball.dy;
end;

function CheckPlatformCollision(CollisionShape: ShapePtr): boolean;
begin
    CheckPlatformCollision := ((CollisionShape^.x >= platform^.x) and
        (CollisionShape^.x <= platform^.x + PlatformSize - 1) and
        (CollisionShape^.y = platform^.y));
end;

procedure AddBonus(x, y: integer);
var
    TempBonusItem: BonusItemPtr;
    TempBonusShape: ShapePtr;
    rand: integer;
    BonusType: BonusTypes;
begin
    rand := random(BonusProbability) + 1;
    if rand <> 1 then
        exit;
    BonusType := GetRandomBonus;
    TempBonusShape := CreateShape(1, 1, x, y, SBlack, SWhite,
        GetBonusSymbol(BonusType));
    AddShape(TempBonusShape);
    new(TempBonusItem);
    TempBonusItem^.BonusShape := TempBonusShape;
    TempBonusItem^.BonusType := BonusType;
    TempBonusItem^.next := ListOfBonuses;
    ListOfBonuses := TempBonusItem;
end;

procedure RemoveBall(var BallPtr: BallItemPtr);
var
    PtrToBallItemPtr: ^BallItemPtr;
    tmp: BallItemPtr;
begin
    PtrToBallItemPtr := @ListOfBalls;
    while PtrToBallItemPtr^ <> nil do
    begin
        if PtrToBallItemPtr^ = BallPtr then
        begin
            tmp := PtrToBallItemPtr^;
            RemoveShape(tmp^.ball.BallShape); 
            PtrToBallItemPtr^ := PtrToBallItemPtr^^.next;
            dispose(tmp);
            BallsCount := BallsCount - 1;
            exit;
        end;
        PtrToBallItemPtr := @(PtrToBallItemPtr^^.next);
    end;
end;

function CheckBallBlockCollision(CollisionShape: ShapePtr): boolean;
var
    i, j: integer;
begin
    for i:=1 to BlockRows do
        for j:=1 to BlockRowSize do
            if CollisionShape = blocks[i, j] then
            begin
                CheckBallBlockCollision := true;
                exit;
            end;
    CheckBallBlockCollision := false;
end;

procedure BallBlockCollision(var ball: BallType; dx, dy: integer;
    CollisionShape: ShapePtr);
var
    i, j, k, l, x, y, FirstX, FirstY, SecondX, SecondY: integer;
begin
    for i:=1 to BlockRows do
        for j:=1 to BlockRowSize do
            if CollisionShape = blocks[i, j] then
            begin
                FirstX := ball.BallShape^.x;
                FirstY := ball.BallShape^.y;
                SecondX := FirstX;
                SecondY := FirstY;
                x := ball.BallShape^.x - dx;
                y := ball.BallShape^.y - dy;
                if ActiveBombBalls then
                begin
                    if x > 2 then
                        FirstX := x - 1;
                    if x = 1 + BlockRowSize then
                        SecondX := x;
                    if x < 1 + BlockRowSize then
                        SecondX := x + 1;
                    if y > 2 then
                        FirstY := y - 1;
                    if y = 1 + BlockRows then
                        SecondY := y;
                    if y < 1 + BlockRows then
                        SecondY := y + 1;
                end;
                if not ActiveFireBalls then
                begin
                    ball.dy := ball.dy;
                    ball.dx := -ball.dx;
                end;
                for k:=(FirstY - 1) to (SecondY - 1) do
                    for l:=(FirstX - 1) to (SecondX - 1) do
                    begin
                        if blocks[k, l] = nil then
                            continue;
                        AddBonus(blocks[k, l]^.x, blocks[k, l]^.y);
                        RemoveShape(blocks[k, l]);
                        blocks[k, l] := nil;
                        BlocksCount := BlocksCount - 1;
                    end;
                exit;
            end;
end;

function CheckBallShapeCollision(CollisionShape: ShapePtr): boolean;
var
    tmp: BallItemPtr;
begin
    tmp := ListOfBalls;
    while tmp <> nil do
    begin
        if tmp^.ball.BallShape = CollisionShape then
        begin
            CheckBallShapeCollision := true;
            exit;
        end;
        tmp := tmp^.next;
    end;
    CheckBallShapeCollision := false;
end;

procedure TwoBallsCollision(var ball: BallType; CollisionShape: ShapePtr);
var
    tmp: BallItemPtr;
begin
    ball.dx := -ball.dx;
    ball.dy := -ball.dy;
    {MoveShape(ball.BallShape, ball.dx, ball.dy);}
    tmp := ListOfBalls;
    while tmp <> nil do
    begin
        if tmp^.ball.BallShape = CollisionShape then
        begin
            tmp^.ball.dx := -tmp^.ball.dx;
            tmp^.ball.dy := -tmp^.ball.dy;
            exit;
        end;
        tmp := tmp^.next;
    end;
end;

function CheckBallCollision(var ball: BallType): boolean;
var
    CollisionShape: ShapePtr;
begin
    if CheckCollision(ball.BallShape) then
    begin
        CollisionShape := GetCollision(ball.BallShape); 
        CheckBallCollision := (CheckWallCollision(CollisionShape) or
            CheckPlatformCollision(CollisionShape) or
            CheckBallBlockCollision(CollisionShape));
    end
    else
        CheckBallCollision := false;
end;

{procedure GetObjInDirection(var ball: BallType; var x, y: integer);
var
    k: integer;
    dx, dy: array[1..3] of integer;
    TempBall: BallType;
begin
    dx[1] := ball.dx;
    dy[1] := 0;
    dx[2] := 0;
    dy[2] := ball.dy;
    dx[3] := ball.dx;
    dy[3] := ball.dy;
    TempBall := ball;
    for k := 1 to 3 do
    begin
        MoveShape(TempBall.BallShape, dx[k], dy[k]);
        TempBall.dx := dx[k];
        TempBall.dy := dy[k];
        if CheckBallCollision(TempBall) then
        begin
            x := TempBall.BallShape^.x;
            y := TempBall.BallShape^.y;
            MoveShape(TempBall.BallShape, -dx[k], -dy[k]);
            exit;
        end;
        MoveShape(TempBall.BallShape, -dx[k], -dy[k]);
    end;
    x := ball.dx;
    y := ball.dy;
end;}

procedure BallWallCollision(var ball: BallType);
begin
    if (ball.BallShape^.x <= 1) or (ball.BallShape^.x >= GetFieldWidth) then
        ball.dx := -ball.dx;
    if (ball.BallShape^.y <= 1) or (ball.BallShape^.y >= GetFieldHeight) then
        ball.dy := -ball.dy;
end;

procedure BallCollision(var ball: BallType; dx, dy: integer);
var
    CollisionShape: ShapePtr;
begin
    CollisionShape := GetCollision(ball.BallShape); 
    if CheckWallCollision(CollisionShape) then
    begin
        BallWallCollision(ball)
    end
    else if CheckPlatformCollision(CollisionShape) then
    begin
        {PlatformNumber := CollisionShape^.x - platform[1]^.x + 1;}
        BallPlatformCollision(ball)
    end
    {else if CheckTwoBallsCollision(CollisionShape) then
    begin
        TwoBallsCollision(ball, CollisionShape)
    end}
    else if CheckBallBlockCollision(CollisionShape) then
        BallBlockCollision(ball, dx, dy, CollisionShape);
    {MoveShape(ball.BallShape, ball.dx, ball.dy);}
end;

function CheckDoubleBallCollision(var ball: BallType): boolean;
begin
    MoveShape(ball.BallShape, ball.dx, 0);
    if CheckBallCollision(ball) then
    begin
        MoveShape(ball.BallShape, -ball.dx, ball.dy);
        CheckDoubleBallCollision := CheckBallCollision(ball);
        MoveShape(ball.BallShape, 0, -ball.dy);
        exit;
    end;
    MoveShape(ball.BallShape, -ball.dx, 0);
    CheckDoubleBallCollision := false;
end;

procedure DoubleBallCollision(var ball: BallType);
var
    dx, dy: integer;
begin
    dx := ball.dx;
    dy := ball.dy;
    MoveShape(ball.BallShape, 0, dy);
    BallCollision(ball, 0, dy);
    MoveShape(ball.BallShape, dx, -dy);
    if CheckBallCollision(ball) then
        BallCollision(ball, dx, 0);
    ball.dx := -dx;
    ball.dy := -dy;
    MoveShape(ball.BallShape, -dx, 0);
end;

procedure MoveBall(var ball: BallType);
var
    k: integer;
    dx, dy: array[1..3] of integer;
begin
    dx[1] := ball.dx;
    dy[1] := 0;
    dx[2] := 0;
    dy[2] := ball.dy;
    dx[3] := ball.dx;
    dy[3] := ball.dy;
    if CheckDoubleBallCollision(ball) then
        DoubleBallCollision(ball)
    else
        for k := 1 to 3 do
        begin
            MoveShape(ball.BallShape, dx[k], dy[k]);
            if CheckBallCollision(ball) then
            begin
                BallCollision(ball, dx[k], dy[k]);
                MoveShape(ball.BallShape, -dx[k], -dy[k]);
                break;
            end;
            MoveShape(ball.BallShape, -dx[k], -dy[k]);
        end;
    MoveShape(ball.BallShape, ball.dx, ball.dy);
end;

procedure MoveBalls;
var
    tmp: ^BallItemPtr;
begin
    tmp := @ListOfBalls;
    while tmp^ <> nil do 
    begin
        if tmp^^.ball.BallShape^.y >= GetFieldHeight - 1 then
            RemoveBall(tmp^)
        else 
        begin
            if CheckBallCollision(tmp^^.ball) then
            begin
                BallCollision(tmp^^.ball, tmp^^.ball.dx, tmp^^.ball.dy);
                MoveShape(tmp^^.ball.BallShape, tmp^^.ball.dx,
                    tmp^^.ball.dy)
            end
            else
                MoveBall(tmp^^.ball);
            tmp := @(tmp^^.next);
        end;
    end;
end;

procedure RemoveBonus(var TempBonus: ShapePtr);
var
    PtrToBonusItemPtr: ^BonusItemPtr;
    tmp: BonusItemPtr;
begin
    PtrToBonusItemPtr := @ListOfBonuses;
    while PtrToBonusItemPtr^ <> nil do
    begin
        if PtrToBonusItemPtr^^.BonusShape = TempBonus then
        begin
            tmp := PtrToBonusItemPtr^; 
            PtrToBonusItemPtr^ := PtrToBonusItemPtr^^.next;
            RemoveShape(TempBonus);
            dispose(tmp);
            exit;
        end;
        PtrToBonusItemPtr := @(PtrToBonusItemPtr^^.next);
    end;
end;

procedure AddBall(x, y, dx, dy: integer);
var
    TempBallItem: BallItemPtr;
    TempBallShape: ShapePtr;
begin
    TempBallShape := CreateShape(1, 1, x, y, SWhite, SBlack, '*');
    AddShape(TempBallShape);
    new(TempBallItem);
    TempBallItem^.ball.BallShape := TempBallShape;
    TempBallItem^.ball.dx := dx;
    TempBallItem^.ball.dy := dy;
    TempBallItem^.next := ListOfBalls;
    ListOfBalls := TempBallItem;
    BallsCount := BallsCount + 1;
end;

procedure PlatformResize(NewSize: integer);
var
    NewX: integer;
begin
    if NewSize > PlatformSize then
        NewX := platform^.x - (NewSize - PlatformSize) div 2
    else
        NewX := platform^.x + (PlatformSize - NewSize) div 2;
    SetShapeSize(platform, 1, NewSize);
    SetShapePos(platform, NewX, platform^.y);
    PlatformSize := NewSize;
    PlatformBonusTime := time;
end;

procedure MoveBonus(var TempBonus: ShapePtr; BonusType: BonusTypes);
var
    CollisionShape: ShapePtr;
begin
    MoveShape(TempBonus, 0, 1);
    if CheckWallCollision(TempBonus) then
    begin
        RemoveBonus(TempBonus);
        exit;
    end;
    if CheckCollision(TempBonus) then
    begin
        CollisionShape := GetCollision(TempBonus);
        if CheckPlatformCollision(CollisionShape) then
        begin
            case BonusType of
                BTBall:
                    AddBall(platform^.x + PlatformSize div 2, 
                        CollisionShape^.y - 1, 1, -1);
                BTPlatformSize:
                    PlatformResize(5);
                BTBombBalls:
                begin
                    ActiveBombBalls := true;
                    BombBallsBonusTime := time;
                end;
                BTSlowBalls:
                begin
                    BallSpeed := DefaultBallSpeed div 2;
                    SlowBallsBonusTime := time;
                end;
                BTFireBalls:
                begin
                    ActiveFireBalls := true;
                    FireBallsBonusTime := time;
                end;
            end;
            RemoveBonus(TempBonus);
        end;
    end;
end;

procedure MoveBonuses;
var
    tmp: BonusItemPtr;
begin
    tmp := ListOfBonuses;
    while tmp <> nil do
    begin
        MoveBonus(tmp^.BonusShape, tmp^.BonusType);
        tmp := tmp^.next;
    end;
end;

function PlatformCollision(TempShape: ShapePtr): boolean;
begin
    PlatformCollision := CheckWallCollision(TempShape) {or
        CheckBallShapeCollision(TempShape);}
end;

procedure MovePlatform(dx, dy: integer);
begin
    {MoveShape(platform[1], dx, dy);
    if PlatformCollision(platform[1]) then
    begin
        MoveShape(platform[1], -dx, -dy);
        exit;
    end;
    MoveShape(platform[1], -dx, -dy);
    MoveShape(platform[PlatformSize], dx, dy);
    if PlatformCollision(platform[PlatformSize]) then
    begin
        MoveShape(platform[PlatformSize], -dx, -dy);
        exit;
    end;
    MoveShape(platform[PlatformSize], -dx, -dy);
    for i:=1 to PlatformSize do
    begin
        MoveShape(platform[i], dx, dy);
    end;
    }
    MoveShape(platform, dx, dy);
    if PlatformCollision(platform) then
        MoveShape(platform, -dx, -dy);
end;

procedure AddBlocks;
var
    i, j, rand: integer;
    NewBlock: ShapePtr;
begin
    for i:=1 to BlockRows do
        for j:=1 to BlockRowSize do
        begin
            NewBlock := nil;
            rand := random(2);
            if rand = 1 then
            begin
                NewBlock := CreateShape(1, 1, j + 1, i + 1, SWhite, 
                    SGreen, '#');
                AddShape(NewBlock);
                BlocksCount := BlocksCount + 1;
            end;
            blocks[i, j] := NewBlock;
        end;
end;

procedure AddPlatform(x, y, size: integer);
begin
    platform := CreateShape(1, PlatformSize, x, y, SWhite, SBlack, '-');
    AddShape(platform);
end;

procedure AddWalls;
var
    TempShape: ShapePtr;
    i: integer;
begin
    TempShape := CreateShape(1, FieldWidth, 1, 1, WallColor,
        WallBgColor, WallSymbol);
    AddShape(TempShape);
    for i:=2 to FieldHeight-1 do
    begin
        TempShape := CreateShape(1, 1, 1, i, WallColor, 
            WallBgColor, WallSymbol);
        AddShape(TempShape);
        TempShape := CreateShape(1, 1, FieldWidth, i,
            WallColor, WallBgColor, WallSymbol);
        AddShape(TempShape);
    end;
    TempShape := CreateShape(1, FieldWidth, 1, FieldHeight, 
        WallColor, WallBgColor, WallSymbol);
    AddShape(TempShape);
end;

procedure InitGame;
var
    PlatformStartPosX, PlatformStartPosY: integer;
begin
    InitPasGame(FieldHeight, FieldWidth);
    Randomize;
    BlocksCount := 0;
    ListOfBalls := nil;
    BallsCount := 0;
    BallSpeed := DefaultBallSpeed;
    ActiveBombBalls := false;
    ActiveFireBalls := false;
    ListOfBonuses := nil;
    PlatformSize := 3;
    PlatformStartPosX := (FieldWidth - PlatformSize) div 2 + 1;
    PlatformStartPosY := FieldHeight - 2;
    AddWalls;
    AddPlatform(PlatformStartPosX, PlatformStartPosY, PlatformSize);
    AddBall(PlatformStartPosX + PlatformSize div 2, PlatformStartPosY - 1,
        1, -1);
    AddBlocks;
    SetFrameRate(FramesPerSecond);
end;

procedure StartGame;
var
    KeyCode, tick: integer;
    GameOverMsg: string;
begin
    InitGame;
    time := 0;
    tick := 0;
    while not GameOver do
    begin
        if not CheckEvent then
        begin
            Draw;
            tick := tick + 1;
            if tick = FramesPerSecond then
            begin
                time := time + 1;
                if (time - PlatformBonusTime) = 30 then
                    PlatformResize(3);
                if (time - BombBallsBonusTime) = 10 then
                    ActiveBombBalls := false;
                if (time - SlowBallSBonusTime) = 30 then
                    BallSpeed := DefaultBallSpeed;
                if (time - FireBallsBonusTime) = 10 then
                    ActiveFireBalls := false;
            end;
            if tick mod (FramesPerSecond div BallSpeed) = 0 then 
                MoveBalls;
            if tick mod (FramesPerSecond div BonusSpeed) = 0 then
                MoveBonuses;
            if (tick >= FramesPerSecond) and
                (tick mod (FramesPerSecond div BallSpeed) = 0) and 
                (tick mod (FramesPerSecond div BonusSpeed) = 0) then
                tick := 0;
        end
        else
        begin
            GetKey(KeyCode);
            case KeyCode of
                -75:
                    MovePlatform(-1, 0);
                -77:
                    MovePlatform(1, 0);
                27:
                    break
            end
        end;
    end;
    Draw;
    GameOverMsg := 'Game Over!';
    ShowMessage(GameOverMsg);
    ClearScreen;
end;

procedure HideCursor;
begin
    fpSystem('tput civis');
end;

procedure ShowCursor;
begin
    fpSystem('tput cnorm');
end;

var
    menu: TMenuPtr;
    SelectedItem, AboutGame, AboutAuthor: string;
begin
    HideCursor;
    AboutGame := 'It is arkanoid game in terminal. Control: <- ->' +
        ' buttons';
    AboutAuthor := 'Github: github.com/jakosv';
    menu := CreateMenu;
    AddMenuItem('Start game', menu);
    AddMenuItem('Random game', menu);
    AddMenuItem('About game', menu);
    AddMenuItem('About author', menu);
    AddMenuItem('Exit', menu);
    while true do
    begin
        ClearScreen;
        ShowMenu(menu);
        SelectedItem := GetSelectedItem(menu);
        if (SelectedItem = 'Start game') or (SelectedItem = 'Random game') then
            StartGame
        else if SelectedItem = 'About game' then
        begin
            ClearScreen;
            ShowMessage(AboutGame)
        end
        else if SelectedItem = 'About author' then
        begin
            ClearScreen;
            ShowMessage(AboutAuthor)
        end
        else
            break;
    end;
    ShowCursor;
    ClearScreen;
end.
