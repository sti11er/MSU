uses {$IFDEF UNIX} cthreads, {$ENDIF} ptcGraph, Math;
    
type
    TF = function(x :real) :real;

var x1,x2,x3, square :real;
    count_steps :integer;
    
{$F+}
{$mode TP}
{$R+,B+,X-}
{$codepage UTF-8}

(* given functions *)
function f1(x :real) :real; begin f1 := 1+4/(sqr(x) + 1) end;

function f2(x :real) :real; begin f2 := Power(x, 3) end;

function f3(x :real) :real; begin f3 := Power(2, -x) end;

(* derivatives *)
function df1(x :real) :real; begin df1 := -(8*x/sqr(sqr(x) + 1)) end; 

function df2(x :real) :real; begin df2 := 3*sqr(x) end;

function df3(x :real) :real; begin df3 := -(Ln(2)/Power(2, x)) end;

function Integral(g :TF; a, b, eps2 :real) :real;
var
    h, m, I, I1 :real;
    n, x :integer;
begin
    n := 2;
    I := 0;
    I1 := 100000;
    repeat
        h := (b-a)/n;
        I := h/3*(g(a) + g(b));
        for x:=1 to (n div 2)-1 do
        begin
            I1 := I;
            m := a + 2*h*x;
            I := I + h/3*(2*g(m) + 4*g(m+h));
        end;
        n := n + 2;
    until abs(I1 - I)/15 < eps2;
    Integral := I;
end;

procedure Root(f, g, f_1, g_1 :TF; a, b, eps :real; var x :real; var count_steps :integer);
var
    c, d :real;
    
function H(x :real) :real;
begin
    H := f(x) - g(x)
end;

function H_1(x :real) :real;
begin
    H_1 := f_1(x) - g_1(x)
end;

begin
    count_steps := 0;
    if ((H((a+b)/2) > (H(a) + H(b))/2) and (H(a) > 0)) or ((H((a+b)/2) < (H(a) + H(b))/2) and (H(a) < 0))then
    begin
        d := b; 
        repeat
            if H_1(d) <> 0 then
            begin
                count_steps := count_steps + 1;
                c := d - H(d)/H_1(d);
                d := c;
            end;
        until (H(c)*H(c-eps) < 0)
    end
    else
    begin
        d := a;
        repeat
            count_steps := count_steps + 1;
            c := d - H(d)/H_1(d);
            d := c;
        until (H(c)*H(c+eps) < 0);
    end;
    x := c;
end;

procedure Graph(f1, f2, f3 :TF; x1, x2, x3 :real);
const
        color_OXY = 15;
        color_OXY_text = 11;
        color_num = 15;
        color_f1 = 3;
        color_f2 = 12;
        color_f3 = 13;
        color_points = 6;
        color_area = 14;
    var
        drive, { graph driver }
        mode, { graph mode }
        n, { количество засечек }
        x0, y0, { начальные координаты }
        x_coord, y_coord, { координаты на графике }
        xMin, xMax, yMin, yMax, { значения на осях }
        p_xMin, p_xMax, p_yMin, p_yMax, { граница }
        i, { счётчик }
        runner: integer;
        MX, MY, { масштаб }
        x, dx, x_num,
        y, dy, y_num: real;
        slovo, point1, point2, point3: string;

    { draw graph function }
    procedure draw_func(color_f: integer; F: TF; desc: string; xt, yt: integer);
    begin
        SetColor(color_f);
        OutTextXY(x0+xt, y0-trunc(F(0)*MY)-yt, desc);
        x := xMin;

        while (x <= xMax) do
        begin
            y := F(x);

            { coordinate in window }
            x_coord := x0 + round(x*MX);
            y_coord := y0 - round(y*MY);

            if (y_coord >= p_yMin) and (y_coord <= p_yMax) then
            begin
                PutPixel(x_coord, y_coord, color_f);
            end;

            x := x + 0.00001
        end;
    end;

    begin
        drive := VGA;
        mode := VGAHi;

        (* initialithation graphic mode *)
        InitGraph(drive, mode, '');
        SetColor(color_OXY);
        
        { padding in window }
        p_xMin := 50; p_xMax := GetMaxX - 50;
        p_yMin := 50; p_yMax := GetMaxY - 50;
        xMin := -4; xMax := 3; dx := 0.5;
        yMin := -2; yMax := 6; dy := 0.5;

        { coordinate normalization }
        MX := (p_xMax - p_xMin) / (xMax - xMin); 
        MY := (p_yMax - p_yMin) / (yMax - yMin);
        x0 := p_xMax - trunc(xMax*MX);
        y0 := p_yMin + trunc(yMax*MY);

        { trace the axes }
        Line(p_xMin, y0, p_xMax, y0); { OX }
        Line(x0, p_yMin, x0, p_yMax); { OY }
        

        { axis signature }
        SetColor(color_OXY_text);
        SetTextStyle(1, 0, 1);
        OutTextXY(GetMaxX - 30, y0, 'OX');
        OutTextXY(x0, 30, 'OY');

        { draw serifs on OX }
        SetColor(color_num);
        OutTextXY(x0 - 10, y0 + 10, '0');
        n := round((xMax - xMin)/dx);

        for i := 0 to n do
        begin
            x_num := xMin + i*dx;
            { coordinate in window }
            x_coord := p_xMin + trunc((x_num - xMin)*MX);
            { draw serif }
            Line(x_coord, y0-3, x_coord, y0+3);
            
            { if x_num not nil then draw number }
            str(x_num:0:1, slovo);
            if (abs(x_num) > 1E-10) then
                OutTextXY(x_coord - TextWidth(slovo) div 2, y0+10, slovo)
        end;

        { draw serifs on OY }
        n := round((yMax - yMin)/dy);
        for i := 0 to n do
        begin
            y_num := yMin + i*dy;
            { coordinate in window }
            y_coord := p_yMax - trunc((y_num - yMin)*MY);
            { draw serif }
            Line(x0-3, y_coord, x0+3, y_coord);
            { if x_num not nil then draw number }
            str(y_num:0:1, slovo);
            if (abs(y_num) > 1E-10) then
                OutTextXY(x0+10, y_coord - TextHeight(slovo) div 2, slovo)
        end;

        { draw functions }
        draw_func(color_f1, F1, 'y = 1+4/(x^2 + 1)', 60, 5);
        draw_func(color_f2, F2, 'y = x^3', 120, 140);
        draw_func(color_f3, F3, 'y = 2^(-x)', -250, 140);
        
        { mark the intersection points }
        SetColor(color_points);
        Str(x1:0:4, point1); 
        Str(x2:0:4, point2); 
        Str(x3:0:4, point3); 
        point1 := 'x1 =' + point1;
        point2 := 'x2 =' + point2;
        point3 := 'x3 =' + point3;
        OutTextXY(x0+trunc(x1*MX)-70, y0+40, point1);
        OutTextXY(x0+trunc(x2*MX), y0+40, point2);
        OutTextXY(x0+trunc(x3*MX), y0+25, point3);

        { drop the perpendiculars }
        line(x0+round(x1*MX), y0-round(F1(x1)*MY), x0+round(x1*MX), y0);
        line(x0+round(x2*MX), y0-round(F3(x2)*MY), x0+round(x2*MX), y0);
        line(x0+round(x3*MX), y0-round(F1(x3)*MY), x0+round(x3*MX), y0);

        
        Readln;
    end;


begin
    Root(@f1, @f3, @df1, @df3, -1.5, -1, 0.0001, x1, count_steps);
    writeln('x1 = ', x1:0:4, ' за ', count_steps, ' шагов');
    Root(@f3, @f2, @df3, @df2, 0, 2, 0.0001, x2, count_steps);
    writeln('x2 = ', x2:0:4, ' за ', count_steps, ' шагов');
    Root(@f1, @f2, @df1, @df2, 1, 1.5, 0.0001, x3, count_steps);
    writeln('x3 = ', x3:0:4, ' за ',count_steps, ' шагов');
    square := Integral(@f1, x1, x3, 2*0.0001/3) - Integral(@f2, x2, x3, 0.0001/3) - Integral(@f3, x1, 0, 0.0001/3);
    writeln('площадь фигуры: ', square:0:4);
    Graph(@f1, @f2, @f3, x1, x2, x3);
end.
