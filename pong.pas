program juegocompleto_final;
{$codepage utf-8}

uses
  crt, sysutils
  {$IFDEF WINDOWS}, Windows{$ENDIF};


const
  Xi = 10; Xf = 70;
  Yi = 4;  Yf = 20;
  RecordsFile = 'records.txt';
  MaxRecords = 50;
type
  TRecordEntry = record
    mode: string;   
    name: string;
    score: integer;
    timeSec: integer;
    dateStr: string;
  end;

var
  c,s: char;
  puntos1,puntos2: integer;
  jugador1,jugador2: string;
  limitepuntos: integer;
  tiempoInicio: QWord;

  // Ranking
  records: array[1..MaxRecords] of TRecordEntry;
  recordsCount: integer;



procedure escribirxy(x,y,color,fondo:integer;texto:string);
begin
  gotoxy(x,y);
  textcolor(color);
  textbackground(fondo);
  write(texto);
  normvideo;
end;

procedure safeReadLn(var outStr: string);
begin
  // Lee de forma segura incluso si hay restos en buffer
  readln(outStr);
end;

procedure playTone(freq, ms: Cardinal);
begin
  {$IFDEF WINDOWS}
  // Windows API Beep
  if freq>37 then
    Beep(freq, ms)
  else
    Sleep(ms);
  {$ELSE}

  Sleep(ms);
  {$ENDIF}
end;

procedure playBounceSound();
begin
  playTone(1000,40);
  playTone(800,30);
end;

procedure playScoreSound();
begin
  playTone(700,120);
  playTone(900,80);
end;

procedure playGameOverSound();
begin
  playTone(300,200);
  playTone(200,200);
  playTone(150,200);
end;

procedure ensureRecordsFileExists();
var
  f: TextFile;
begin
  if not FileExists(RecordsFile) then
  begin
    AssignFile(f, RecordsFile);
    Rewrite(f);
    // records de ejemplo
    writeln(f, 'IA|CPU|10|0|2025-01-01 12:00');
    writeln(f, 'SOLITARIO|PlayerA|25|120|2025-02-14 19:20');
    writeln(f, 'MULTI|Ana|15|60|2025-03-03 09:15');
    CloseFile(f);
  end;
end;

procedure loadRecords();
var
  f: TextFile;
  line, part: string;
  parts: array[1..5] of string;
  i, p, n: integer;
  dt: TDateTime;
begin
  ensureRecordsFileExists();
  recordsCount := 0;
  AssignFile(f, RecordsFile);
  Reset(f);
  while not Eof(f) do
  begin
    readln(f, line);
    // Format: mode|name|score|timeSec|dateStr
    n := 0;
    p := 1;
    while p <= Length(line) do
    begin
      part := '';
      while (p <= Length(line)) and (line[p] <> '|') do
      begin
        part := part + line[p];
        inc(p);
      end;
      inc(p); // skip '|' or move beyond
      inc(n);
      if n<=5 then parts[n] := part;
      if n>=5 then break;
    end;
    if (n >= 5) and (recordsCount < MaxRecords) then
    begin
      inc(recordsCount);
      records[recordsCount].mode := parts[1];
      records[recordsCount].name := parts[2];
      records[recordsCount].score := StrToIntDef(parts[3], 0);
      records[recordsCount].timeSec := StrToIntDef(parts[4], 0);
      records[recordsCount].dateStr := parts[5];
    end;
  end;
  CloseFile(f);
end;

procedure saveRecords();
var
  f: TextFile;
  i: integer;
begin
  AssignFile(f, RecordsFile);
  Rewrite(f);
  for i := 1 to recordsCount do
  begin
    writeln(f, records[i].mode + '|' + records[i].name + '|' +
      IntToStr(records[i].score) + '|' + IntToStr(records[i].timeSec) + '|' +
      records[i].dateStr);
  end;
  CloseFile(f);
end;

procedure addRecord(mode, name: string; score: integer; timeSec: integer);
var
  i: integer;
  dt: string;
  entry: TRecordEntry;
begin
  dt := FormatDateTime('yyyy-mm-dd hh:nn', Now);
  entry.mode := mode;
  entry.name := name;
  entry.score := score;
  entry.timeSec := timeSec;
  entry.dateStr := dt;

  // Inserta al final y luego ordena por score descendente
  if recordsCount < MaxRecords then
  begin
    inc(recordsCount);
    records[recordsCount] := entry;
  end
  else
  begin
    // reemplaza el peor si el nuevo es mejor
    if score > records[recordsCount].score then
      records[recordsCount] := entry;
  end;

  // ordenar simple por score desc
  for i := 1 to recordsCount-1 do
    if records[i].score < records[i+1].score then
      swap(records[i], records[i+1]); // quick bubble step (we'll do bubble fully)
  // Full bubble
  for i := 1 to recordsCount do
  begin
    var j: integer;
    for j := 1 to recordsCount-1 do
    begin
      if records[j].score < records[j+1].score then
        swap(records[j], records[j+1]);
    end;
  end;

  saveRecords();
end;

procedure showRanking();
var
  i, lineY: integer;
begin
  clrscr;
  textbackground(black);
  textcolor(yellow);
  gotoxy(10,2);
  writeln('=== RANKING GLOBAL (Top ', recordsCount, ') ===');
  textcolor(lightcyan);
  lineY := 4;
  for i := 1 to recordsCount do
  begin
    gotoxy(6, lineY);
    writeln(i:2, '. [', records[i].mode:8, '] ', records[i].name:10, ' - Puntos: ', records[i].score:4,
      ' Tiempo(s): ', records[i].timeSec:5, ' - ', records[i].dateStr);
    inc(lineY);
    if lineY > 20 then break;
  end;
  writeln;
  writeln('Presiona cualquier tecla para volver al menú...');
  readkey;
end;



procedure pintar_campo();
var
  i, j, medioX: integer;
begin
  medioX := (Xi + Xf) div 2;
  // usamos fondo verde para campo, pero sin clrscr global
  textbackground(green);
  // rellenar solo area del campo (no toda la consola)
  for j := Yi to Yf do
    for i := Xi to Xf do
    begin
      gotoxy(i, j);
      write(' ');
    end;

  // Bordes en blanco
  textbackground(white);
  for i := Xi to Xf do
  begin
    gotoxy(i, Yi); write(' ');
    gotoxy(i, Yf); write(' ');
  end;

  for j := Yi to Yf do
  begin
    gotoxy(Xi, j); write(' ');
    gotoxy(Xf, j); write(' ');
  end;

  // Linea central punteada (blanco)
  textcolor(white);
  for j := Yi + 1 to Yf - 1 do
  begin
    if (j mod 2 = 0) then
    begin
      gotoxy(medioX, j);
      textbackground(white);
      write(' ');
    end;
  end;

  // Restaurar
  textbackground(green);
  textcolor(lightgray);
end;

function tecla():char;
begin
  if keypressed then tecla := readkey
  else tecla := #0;
end;

procedure preguntar_nombre();
begin
  // Lee nombres y límite de puntos sin pintar el campo encima
  cursoron;
  textbackground(black);
  textcolor(lightmagenta);
  gotoxy(50,10);
  write('Elige el nombre de los jugadores           ');
  gotoxy(50,12);
  write('Jugador 1:                              ');
  gotoxy(61,12);
  readln(jugador1);
  if Trim(jugador1) = '' then jugador1 := 'Player1';
  gotoxy(50,13);
  write('Jugador 2:                              ');
  gotoxy(61,13);
  readln(jugador2);
  if Trim(jugador2) = '' then jugador2 := 'Player2';
  gotoxy(50,15);
  write('Límite de puntos para ganar:            ');
  gotoxy(79,15);
  readln(limitePuntos);
  if limitePuntos <= 0 then limitePuntos := 5;
  cursoroff;
end;

procedure preguntar_nombre_2();
begin
  // Un jugador
  cursoron;
  textbackground(black);
  textcolor(lightmagenta);
  gotoxy(50,10);
  write('Elige tu nombre                          ');
  gotoxy(50,12);
  write('Jugador 1:                              ');
  gotoxy(61,12);
  readln(jugador1);
  if Trim(jugador1) = '' then jugador1 := 'SoloPlayer';
  gotoxy(50,15);
  write('Límite de puntos para ganar:            ');
  gotoxy(79,15);
  readln(limitePuntos);
  if limitePuntos <= 0 then limitePuntos := 5;
  cursoroff;
end;

procedure Marcador();
begin
 
  textcolor(lightcyan);
  textbackground(black);
  gotoxy(Xi+1, Yi-2); write('╔════════════════════════════╗');
  gotoxy(Xi+1, Yi-1); write('Jugador1: ', puntos1:3, ' | Jugador2: ', puntos2:3,'  ');
  gotoxy(Xi+1, Yi);   write('╚════════════════════════════╝');
end;

procedure marcador_2();
begin
  textcolor(lightcyan);
  textbackground(black);
  gotoxy(Xi+1, Yi-2); write('╔════════════════╗');
  gotoxy(Xi+1, Yi-1); write('Jugador1: ', puntos1:3,'      ');
  gotoxy(Xi+1, Yi);   write('╚════════════════╝');
end;

procedure mostrarTiempo();
begin
  gotoxy(Xf-18, Yi-2);
  write('Tiempo: ', ((GetTickCount64 - tiempoInicio) div 1000):4, ' seg   ');
end;

procedure noBorrarcampo(x, y: integer);
var
  medioX: integer;
begin
  medioX := (Xi + Xf) div 2;
  if (x = Xi) or (x = Xf) or (y = Yi) or (y = Yf) then
    textbackground(white)
  else if (x = medioX) and (y mod 2 = 0) then
    textbackground(white)
  else
    textbackground(green);

  gotoxy(x, y);
  write(' ');
  textbackground(green);
end;

procedure pausa();
var
  teclaP: char;
  medioX, medioY, i, j: integer;
begin
  medioX := (Xi + Xf) div 2;
  medioY := (Yi + Yf) div 2;

  textcolor(yellow);
  textbackground(blue);
  for j := medioY - 1 to medioY + 1 do
    for i := medioX - 12 to medioX + 12 do
    begin
      gotoxy(i, j);
      write(' ');
    end;

  gotoxy(medioX - 9, medioY);
  write('-- JUEGO EN PAUSA --');
  gotoxy(medioX - 5, medioY + 1);
  write('Presiona R');

  repeat
    if keypressed then
    begin
      teclaP := upcase(readkey);
      if teclaP = 'R' then break;
    end;
  until false;


  textbackground(green);
  for j := medioY - 1 to medioY + 1 do
    for i := medioX - 12 to medioX + 12 do
    begin
      gotoxy(i, j);
      write(' ');
    end;
end;

procedure gameOver(ganador: string; puntosGanador, puntosPerdedor: integer);
const
  texto: array[1..7] of string = (
    '   G A M E   O V E R    -   R E T R O 2 0 8 4    ',
    '                                                 ',
    '                                                 ',
    '                                                 ',
    '                                                 ',
    '                                                 ',
    '                                                 '
  );
var
  i, j: integer;
  timeSec: integer;
begin
  clrscr;
  cursoroff;
  textbackground(black);

  // Animación simple del título (neón)
  for j := 1 to 3 do
  begin
    for i := 1 to 7 do
    begin
      textcolor(red + random(7));
      gotoxy(12, 5 + i);
      write(texto[i]);
    end;
    playBounceSound();
    delay(180);
    clrscr;
  end;

  textcolor(lightred);
  for i := 1 to 7 do
  begin
    gotoxy(12, 5 + i);
    write(texto[i]);
  end;

  delay(300);
  textcolor(yellow);
  gotoxy(25, 14);
  write('GANADOR: ', ganador, '  (', puntosGanador, ' - ', puntosPerdedor, ')');
  gotoxy(25, 16);
  textcolor(lightcyan);
  write('Presiona cualquier tecla para volver al menú...');
  playGameOverSound();


  timeSec := ((GetTickCount64 - tiempoInicio) div 1000);
  if jugador2 = '' then
    addRecord('SOLITARIO', ganador, puntosGanador, timeSec)
  else
    addRecord('MULTI', ganador, puntosGanador, timeSec);

  readkey;
end;

procedure juegoPrincipal();
var
  X, Y, IncX, IncY: integer;
  T1: qword;
  velocidad: integer;
  ch: char;
  x1,x2,y1,y2:integer;
begin
  clrscr;
  puntos1 := 0;
  puntos2 := 0;
  tiempoInicio := GetTickCount64;


  textbackground(black);
  clrscr;
  pintar_campo();
  textcolor(white);
  gotoxy(Xi, Yf+3);
  write('M-> Pausa');
  gotoxy(Xf-18, Yf+3);
  write('1-> Volver al menú');
  Marcador();

  X := (Xi + Xf) div 2;
  Y := (Yi + Yf) div 2;

  IncX := 1;
  IncY := 1;
  velocidad := 200;

  x1 := Xi + 2; y1 := (Yi + Yf) div 2;
  x2 := Xf - 2; y2 := y1;

  textbackground(red);
  gotoxy(x1,y1-1); write(' ');
  gotoxy(x1,y1);   write(' ');
  gotoxy(x1,y1+1); write(' ');

  textbackground(blue);
  gotoxy(x2,y2); write(' ');
  gotoxy(x2,y2+1); write(' ');
  gotoxy(x2,y2-1); write(' ');

  textbackground(green);
  gotoxy(X, Y); write('o');

  T1 := GetTickCount64;
  cursoroff;

  repeat
    ch := upcase(tecla);
    mostrarTiempo();
    if ch = 'M' then pausa();

    // Movimiento paleta 1
    if (ch='W') and (y1>Yi+2) then
    begin
      textbackground(green);
      gotoxy(x1,y1-1); write(' ');
      gotoxy(x1,y1);   write(' ');
      gotoxy(x1,y1+1); write(' ');
      y1 := y1 - 1;
      textbackground(red);
      gotoxy(x1,y1-1); write(' ');
      gotoxy(x1,y1);   write(' ');
      gotoxy(x1,y1+1); write(' ');
    end;
    if (ch='S') and (y1<Yf-2) then
    begin
      textbackground(green);
      gotoxy(x1,y1-1); write(' ');
      gotoxy(x1,y1);   write(' ');
      gotoxy(x1,y1+1); write(' ');
      y1 := y1 + 1;
      textbackground(red);
      gotoxy(x1,y1-1); write(' ');
      gotoxy(x1,y1);   write(' ');
      gotoxy(x1,y1+1); write(' ');
    end;

    // Paleta 2
    if (ch='P') and (y2>Yi+2) then
    begin
      textbackground(green);
      gotoxy(x2,y2-1); write(' ');
      gotoxy(x2,y2);   write(' ');
      gotoxy(x2,y2+1); write(' ');
      y2 := y2 - 1;
      textbackground(blue);
      gotoxy(x2,y2-1); write(' ');
      gotoxy(x2,y2);   write(' ');
      gotoxy(x2,y2+1); write(' ');
    end;
    if (ch='L') and (y2<Yf-2) then
    begin
      textbackground(green);
      gotoxy(x2,y2-1); write(' ');
      gotoxy(x2,y2);   write(' ');
      gotoxy(x2,y2+1); write(' ');
      y2 := y2 + 1;
      textbackground(blue);
      gotoxy(x2,y2-1); write(' ');
      gotoxy(x2,y2);   write(' ');
      gotoxy(x2,y2+1); write(' ');
    end;

    if (GetTickCount64 - T1) > velocidad then
    begin
      noBorrarcampo(X, Y);
      X := X + IncX;
      Y := Y + IncY;

      // Control de puntos
      if (X <= Xi + 1) then
      begin
        puntos2 := puntos2 + 1;
        Marcador();
        playScoreSound();
        X := (Xi + Xf) div 2;
        Y := (Yi + Yf) div 2;
        IncX := 1; IncY := 1;
      end
      else if (X >= Xf - 1) then
      begin
        puntos1 := puntos1 + 1;
        Marcador();
        playScoreSound();
        X := (Xi + Xf) div 2;
        Y := (Yi + Yf) div 2;
        IncX := -1; IncY := -1;
      end;

      if (puntos1 >= limitePuntos) or (puntos2 >= limitePuntos) then
      begin
        if puntos1 > puntos2 then
        begin
          gameOver(jugador1, puntos1, puntos2);
          addRecord('MULTI', jugador1, puntos1, ((GetTickCount64 - tiempoInicio) div 1000));
        end
        else
        begin
          gameOver(jugador2, puntos2, puntos1);
          addRecord('MULTI', jugador2, puntos2, ((GetTickCount64 - tiempoInicio) div 1000));
        end;
        exit;
      end;

      if (Y <= Yi + 1) or (Y >= Yf - 1) then
        IncY := -IncY;

      if ((X = x1 + 1) and (Y >= y1 - 1) and (Y <= y1 + 1)) then
      begin
        IncX := -IncX;
        playBounceSound();
      end;

      if ((X = x2 - 1) and (Y >= y2 - 1) and (Y <= y2 + 1)) then
      begin
        IncX := -IncX;
        playBounceSound();
      end;

      gotoxy(X, Y); write('o');
      T1 := GetTickCount64;
    end;

  until ch = chr(27);

  // Al salir, restablecer fondo y limpiar
  textbackground(black); textcolor(white); clrscr;
end;

{ ============================
  Juego IA (mejorado - velocidad IA variable)
  ============================ }

procedure juegoIA(velocidadIA: integer);
var
  X, Y, IncX, IncY: integer;
  T1: qword;
  velocidad: integer;
  ch: char;
  x1,x2,y1,y2:integer;
  lastMoveTick: QWord;
begin
  clrscr;
  puntos1 := 0;
  puntos2 := 0;
  tiempoInicio := GetTickCount64;

  pintar_campo();
  textcolor(white);
  gotoxy(Xi, Yf+3);
  write('M-> Pausa');
  gotoxy(Xf-18, Yf+3);
  write('1-> Volver al menú');
  Marcador();

  X := (Xi + Xf) div 2;
  Y := (Yi + Yf) div 2;
  IncX := 1; IncY := 1;
  velocidad := 200;

  x1 := Xi + 2; y1 := (Yi + Yf) div 2;
  x2 := Xf - 2; y2 := y1;

  textbackground(red);
  gotoxy(x1,y1-1); write(' ');
  gotoxy(x1,y1);   write(' ');
  gotoxy(x1,y1+1); write(' ');

  textbackground(blue);
  gotoxy(x2,y2); write(' ');
  gotoxy(x2,y2+1); write(' ');
  gotoxy(x2,y2-1); write(' ');

  gotoxy(X, Y); write('o');

  T1 := GetTickCount64;
  lastMoveTick := T1;
  cursoroff;

  repeat
    ch := upcase(tecla);
    if ch = 'M' then pausa();

    // Paleta jugador
    if (ch='W') and (y1>Yi+2) then
    begin
      textbackground(green);
      gotoxy(x1,y1-1); write(' ');
      gotoxy(x1,y1);   write(' ');
      gotoxy(x1,y1+1); write(' ');
      y1 := y1 - 1;
      textbackground(red);
      gotoxy(x1,y1-1); write(' ');
      gotoxy(x1,y1);   write(' ');
      gotoxy(x1,y1+1); write(' ');
    end;
    if (ch='S') and (y1<Yf-2) then
    begin
      textbackground(green);
      gotoxy(x1,y1-1); write(' ');
      gotoxy(x1,y1);   write(' ');
      gotoxy(x1,y1+1); write(' ');
      y1 := y1 + 1;
      textbackground(red);
      gotoxy(x1,y1-1); write(' ');
      gotoxy(x1,y1);   write(' ');
      gotoxy(x1,y1+1); write(' ');
    end;

    // IA simple que sigue la Y de la pelota con retardo
    if (GetTickCount64 - lastMoveTick) mod (velocidadIA * 40) = 0 then
    begin
      if y2 < Y then
      begin
        if y2 < Yf - 2 then
        begin
          textbackground(green);
          gotoxy(x2, y2 - 1); write(' ');
          inc(y2);
          textbackground(blue);
          gotoxy(x2, y2 + 1); write(' ');
        end;
      end
      else if y2 > Y then
      begin
        if y2 > Yi + 2 then
        begin
          textbackground(green);
          gotoxy(x2, y2 + 1); write(' ');
          dec(y2);
          textbackground(blue);
          gotoxy(x2, y2 - 1); write(' ');
        end;
      end;
      lastMoveTick := GetTickCount64;
    end;

    if (GetTickCount64 - T1) > velocidad then
    begin
      noBorrarcampo(X, Y);
      X := X + IncX; Y := Y + IncY;

      if (X <= Xi + 1) then
      begin
        puntos2 := puntos2 + 1;
        Marcador();
        playScoreSound();
        X := (Xi + Xf) div 2; Y := (Yi + Yf) div 2;
        IncX := 1; IncY := 1;
      end
      else if (X >= Xf - 1) then
      begin
        puntos1 := puntos1 + 1;
        Marcador();
        playScoreSound();
        X := (Xi + Xf) div 2; Y := (Yi + Yf) div 2;
        IncX := -1; IncY := -1;
      end;

      if (puntos1 >= limitePuntos) or (puntos2 >= limitePuntos) then
      begin
        if puntos1 > puntos2 then
        begin
          gameOver(jugador1, puntos1, puntos2);
          addRecord('IA', jugador1, puntos1, ((GetTickCount64 - tiempoInicio) div 1000));
        end
        else
        begin
          gameOver('CPU', puntos2, puntos1);
          addRecord('IA', 'CPU', puntos2, ((GetTickCount64 - tiempoInicio) div 1000));
        end;
        exit;
      end;

      if (Y <= Yi + 1) or (Y >= Yf - 1) then IncY := -IncY;

      if ((X = x1 + 1) and (Y >= y1 - 1) and (Y <= y1 + 1)) then
      begin
        IncX := -IncX;
        playBounceSound();
      end;

      if ((X = x2 - 1) and (Y >= y2 - 1) and (Y <= y2 + 1)) then
      begin
        IncX := -IncX;
        playBounceSound();
      end;

      gotoxy(X, Y); write('o');
      T1 := GetTickCount64;
    end;

  until ch = chr(27);

  textbackground(black); textcolor(white); clrscr;
end;

{ ============================
  Juego Solitario (solo una paleta)
  ============================ }

procedure juegoSolitario();
var
  X, Y, IncX, IncY: integer;
  T1: qword;
  velocidad: integer;
  ch: char;
  x1, y1: integer;
  velocidadInput: integer;
begin
  clrscr;
  preguntar_nombre_2();

  // Pedir velocidad ANTES de pintar el campo para que no se borre el prompt
  textbackground(black);
  textcolor(yellow);
  gotoxy(50,13);
  write('Elige la velocidad del juego (1-10, 1 rápido): ');
  gotoxy(95,13);
  readln(velocidadInput);
  if velocidadInput < 1 then velocidadInput := 1;
  if velocidadInput > 10 then velocidadInput := 10;
  velocidad := 300 - (velocidadInput * 25);

  puntos1 := 0;
  tiempoInicio := GetTickCount64;

  // ahora pintar campo y HUD
  pintar_campo();
  textcolor(white);
  gotoxy(Xi, Yf+3);
  write('M-> Pausa');
  gotoxy(Xf-18, Yf+3);
  write('1-> Volver al menú');
  marcador_2();

  X := (Xi + Xf) div 2;
  Y := (Yi + Yf) div 2;
  IncX := 1; IncY := 1;

  x1 := Xi + 2;
  y1 := (Yi + Yf) div 2;

  textbackground(red);
  gotoxy(x1, y1-1); write(' ');
  gotoxy(x1, y1);   write(' ');
  gotoxy(x1, y1+1); write(' ');

  textbackground(green);
  gotoxy(X, Y); write('o');

  T1 := GetTickCount64;
  cursoroff;

  repeat
    ch := upcase(tecla);
    if ch = 'M' then pausa();

    if (ch='W') and (y1>Yi+2) then
    begin
      textbackground(green);
      gotoxy(x1, y1-1); write(' ');
      gotoxy(x1, y1);   write(' ');
      gotoxy(x1, y1+1); write(' ');
      y1 := y1 - 1;
      textbackground(red);
      gotoxy(x1, y1-1); write(' ');
      gotoxy(x1, y1);   write(' ');
      gotoxy(x1, y1+1); write(' ');
    end;

    if (ch='S') and (y1<Yf-2) then
    begin
      textbackground(green);
      gotoxy(x1, y1-1); write(' ');
      gotoxy(x1, y1);   write(' ');
      gotoxy(x1, y1+1); write(' ');
      y1 := y1 + 1;
      textbackground(red);
      gotoxy(x1, y1-1); write(' ');
      gotoxy(x1, y1);   write(' ');
      gotoxy(x1, y1+1); write(' ');
    end;

    if (GetTickCount64 - T1) > velocidad then
    begin
      noBorrarcampo(X, Y);
      X := X + IncX;
      Y := Y + IncY;

      if (X >= Xf - 1) then
      begin
        puntos1 := puntos1 + 1;
        marcador_2();
        playScoreSound();
        X := (Xi + Xf) div 2;
        Y := (Yi + Yf) div 2;
        IncX := -1; IncY := -1;
      end;

      if (Y <= Yi + 1) or (Y >= Yf - 1) then
        IncY := -IncY;

      if ((X = x1 + 1) and (Y >= y1 - 1) and (Y <= y1 + 1)) then
      begin
        IncX := -IncX;
        playBounceSound();
      end;

      // Comprobar límite de puntos
      if puntos1 >= limitePuntos then
      begin
        gameOver(jugador1, puntos1, 0);
        addRecord('SOLITARIO', jugador1, puntos1, ((GetTickCount64 - tiempoInicio) div 1000));
        exit;
      end;

      gotoxy(X, Y); write('o');
      T1 := GetTickCount64;
    end;

  until ch = chr(27);

  textbackground(black);
  textcolor(white);
  clrscr;
  gotoxy(((Xi+Xf) - Length('Juego terminado')) div 2, (Yi+Yf) div 2);
  writeln('Juego terminado');
  readkey;
end;

{ ============================
  Loading, menu e intro
  ============================ }

procedure loading_screen();
var
  i, medioX: integer;
begin
  medioX := (Xi + Xf) div 2;
  textbackground(black);
  clrscr;
  escribirxy(medioX - 5, Yf - 2, white, black, 'LOADING...');
  textbackground(green);
  for i := 1 to 19 do
  begin
    gotoxy((medioX - 9) + i, Yf - 4);
    write(' ');
    delay(40);
  end;
  textbackground(BLACK);
  textcolor(white);
  gotoxy(medioX - 12, Yf - 2);
  write('¡Listo! Presiona una tecla para continuar...');
  readkey;
end;

procedure introAnim();
var
  i, midX, midY: integer;
  colors: array[1..6] of byte = (lightmagenta, magenta, lightblue, cyan, yellow, lightgreen);
  idx: integer;
begin
  textbackground(black); clrscr;
  midX := 40; midY := 8;
  for idx := 1 to 3 do
  begin
    for i := 1 to 40 do
    begin
      textcolor(colors[(i mod 6)+1]);
      gotoxy(midX - i + 10, midY);
      write('PONG RETRO 2084');
      delay(40);
    end;
    playTone(500 + idx*100, 80);
  end;
  delay(300);
  textbackground(black); clrscr;
end;

procedure escribirmenu();
var
  medioX, j, i: integer;
  campo: array [1..17,1..17] of byte =
    ((1,1,1,1,1,1,0,0,0,0,0,1,1,1,1,1,1),
     (1,1,1,1,0,0,15,10,10,10,10,0,0,1,1,1,1),
     (1,1,1,0,10,10,15,10,10,10,10,10,10,0,1,1,1),
     (1,1,0,10,10,10,10,15,10,10,10,10,10,10,0,1,1),
     (1,0,10,10,10,10,10,15,10,10,10,10,10,10,10,10,1),
     (0,10,10,10,10,10,10,15,10,10,10,10,10,10,10,10,0),
     (0,10,10,10,10,10,15,10,10,10,10,10,10,10,10,10,0),
     (0,10,10,10,10,15,10,10,10,10,10,10,10,10,10,10,0),
     (0,10,10,10,15,10,10,10,10,10,10,10,10,10,10,10,0),
     (0,10,10,10,15,10,10,10,10,10,10,10,10,10,10,10,0),
     (0,10,10,10,15,10,10,10,10,10,10,10,10,10,10,10,0),
     (1,0,10,10,10,15,10,10,10,10,10,10,10,10,10,10,1),
     (1,1,0,10,10,10,15,10,10,10,10,10,10,10,0,1,1),
     (1,1,1,0,10,10,10,15,10,10,10,10,10,0,1,1,1),
     (1,1,1,1,0,0,10,10,15,10,10,0,0,1,1,1,1),
     (1,1,1,1,1,1,0,0,0,0,0,1,1,1,1,1,1),
     (1,1,1,1,1,1,0,0,0,0,0,1,1,1,1,1,1));

begin
  medioX := (Xi + Xf) div 2;
  textbackground(black);
  clrscr;
  textcolor(yellow);
  textbackground(magenta);

  escribirxy(2, 2, yellow, magenta, '╔' + StringOfChar('═', 76) + '╗');

  for j := 3 to 22 do
  begin
    escribirxy(2, j, yellow, magenta, '║');
    escribirxy(79, j, yellow, magenta, '║');
  end;

  escribirxy(2, 23, yellow, magenta, '╚' + StringOfChar('═', 76) + '╝');

  // pintar pequeños bloques decorativos
  for i := 1 to 17 do
    for j := 1 to 17 do
      if campo[j,i] <> 1 then
        escribirxy(10+2*i, 2+j, 0, campo[j,i], '  ' );

  // Menú - usa colores neón
  textbackground(black);
  escribirxy(medioX - 15, 14, lightcyan, black, '1 - MULTIJUGADOR');
  escribirxy(medioX - 15, 15, lightcyan, black, '2 - JUGAR CONTRA ORDENADOR');
  escribirxy(medioX - 15, 16, lightcyan, black, '3 - SOLITARIO');
  escribirxy(medioX - 15, 17, lightcyan, black, '4 - CONTROLES');
  escribirxy(medioX - 15, 18, lightcyan, black, '5 - RANKING');
  escribirxy(medioX - 15, 19, lightcyan, black, '6 - SALIR');
  escribirxy(medioX - 22, 21, yellow, black, 'Controles: W/S, P/L, M pausa, Esc salir');
end;

{ ============================
  Procedimientos del menú (mantengo nombres)
  ============================ }

procedure procedimiento1();
begin
  clrscr;
  escribirxy(50,8,green,black,'Has elegido la opción 1');
  escribirxy(50,10,yellow,black,'1- VOLVER AL MENÚ');
  readkey;
end;

procedure procedimiento2();
begin
  clrscr;
  preguntar_nombre();
  juegoPrincipal();
end;

procedure procedimiento3();
begin
  clrscr;
  var dificultad: integer;
  begin
    clrscr;
    preguntar_nombre_2();
    textbackground(black);
    textcolor(yellow);
    gotoxy(50,17);
    write('Elige dificultad de la IA (1=Fácil, 2=Media, 3=Difícil): ');
    readln(dificultad);
    case dificultad of
      1: juegoIA(12);
      2: juegoIA(6);
      3: juegoIA(2);
    else
      juegoIA(6);
    end;
  end;
end;

procedure procedimiento4();
begin
  clrscr;
  preguntar_nombre_2();
  juegoSolitario();
end;

procedure controles();
begin
  clrscr;
  escribirxy(50, 14, yellow,black,'CONTROLES');
  escribirxy(50, 16, yellow,black,'Mover paleta izq: arriba->W  abajo->S');
  escribirxy(50, 18, yellow,black,'Mover paleta der: arriba->P  abajo->L');
  escribirxy(50, 20, yellow,black,'Pausa: M     Reanudar juego: R');
  escribirxy(50, 22, yellow,black,'Volver al menú: Esc + cualquier tecla');
  readkey;
end;

{ ============================
  Programa principal
  ============================ }

var
  key: char;
begin
  // Inicialización
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(65001);
  SetConsoleCP(65001);
  {$ENDIF}
  cursoroff;
  loadRecords();
  introAnim();
  loading_screen();

  repeat
    textbackground(black);
    textcolor(white);
    clrscr;
    escribirmenu();
    key := readkey;
    case key of
      '1': begin procedimiento2(); end;
      '2': begin procedimiento3(); end;
      '3': begin procedimiento4(); end;
      '4': begin controles(); end;
      '5': begin showRanking(); end;
      '6': begin key := '6'; end;
    end;
  until key = '6';

  clrscr;
  escribirxy(50,8,lightmagenta,black,'~~SAYONARA~~');
  delay(500);
  textbackground(black);
  textcolor(white);
  clrscr;
end.
