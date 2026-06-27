#!/usr/bin/env python3
"""Genera data/map.txt replicando la logica actual de monte_grande.gd.
Uso unico: crear el lienzo inicial editable a partir del mapa procedural.
Despues el mapa se edita a mano en data/map.txt; este script no se vuelve a usar."""

MAP_W, MAP_H = 44, 48

GRASS, BUILDING, ROAD, TREE, RAIL, PLAZA, WATER, SIDEWALK, MONUMENT, BENCH, PLATFORM, OMBU = range(12)

# char por tile de terreno
CH = {
    GRASS: '.', ROAD: '#', TREE: 'T', RAIL: '=', PLAZA: 'P',
    WATER: '~', SIDEWALK: ':', MONUMENT: 'M', PLATFORM: '_', OMBU: 'O', BENCH: 'b',
}

PLAZA_CX, PLAZA_CY, PLAZA_R = 22, 33, 7

t = [GRASS] * (MAP_W * MAP_H)
# capa de letras de edificio (sobreescribe terreno en el render del .txt)
blds = {}  # (x,y) -> letra


def setc(x, y, v):
    if 0 <= x < MAP_W and 0 <= y < MAP_H:
        t[y * MAP_W + x] = v


def getc(x, y):
    if 0 <= x < MAP_W and 0 <= y < MAP_H:
        return t[y * MAP_W + x]
    return BUILDING


# border
for x in range(MAP_W):
    setc(x, 0, TREE); setc(x, MAP_H - 1, TREE)
for y in range(MAP_H):
    setc(0, y, TREE); setc(MAP_W - 1, y, TREE)

# streets
for y in range(MAP_H):
    for x in range(MAP_W):
        d = abs(x - PLAZA_CX) + abs(y - PLAZA_CY)
        if d == 8 or d == 9:
            setc(x, y, ROAD)

def diag(sx, sy, dx, dy, n):
    for k in range(n):
        setc(sx + dx * k, sy + dy * k, ROAD)
        setc(sx + dx * k + dy, sy + dy * k + dx, ROAD)

diag(17, 28, -1, -1, 10)
diag(27, 28, 1, -1, 12)
diag(17, 38, -1, 1, 12)
diag(27, 38, 1, 1, 12)
for y in range(8, 25):
    setc(13, y, ROAD); setc(14, y, ROAD)

# sidewalks
for sy in [10, 24, 26, 40, 42]:
    for x in range(MAP_W):
        if getc(x, sy) == GRASS:
            setc(x, sy, SIDEWALK)
for sx in [12, 15, 29, 31]:
    for y in range(MAP_H):
        if getc(sx, y) == GRASS:
            setc(sx, y, SIDEWALK)

# tracks
for x in range(MAP_W):
    setc(x, 4, RAIL); setc(x, 5, RAIL)

# station
for x in range(18, 24):
    setc(x, 6, PLATFORM); setc(x, 7, PLATFORM)


def bld(x, y, w, h, letter):
    for dy in range(h):
        for dx in range(w):
            if getc(x + dx, y + dy) == GRASS:
                blds[(x + dx, y + dy)] = letter


# letra -> (nombre, tipo)
LEGEND = []

def special(x, y, w, h, letter, name, btype):
    bld(x, y, w, h, letter)
    LEGEND.append((letter, name, btype))


special(18, 1, 6, 3, 'S', 'ESTACION', 'station')
special(6, 8, 4, 2, 'A', 'TEATRO', 'teatro')
special(16, 13, 5, 3, 'V', 'VENECIANA', 'restaurant')
special(24, 13, 5, 3, 'F', 'MOSTAZA', 'fastfood')
special(2, 13, 6, 3, 'K', 'KATA', 'studio')
special(36, 13, 5, 3, 'C', 'CLUB ATL.', 'club')
special(18, 20, 8, 3, 'Q', 'COMISARIA', 'police')
special(18, 43, 8, 3, 'I', 'IGLESIA', 'church')
special(5, 30, 6, 6, 'G', 'MUNICIPIO', 'govt')
special(33, 30, 6, 6, 'H', 'ESC.N1', 'school')

# plaza mitre
cx, cy = PLAZA_CX, PLAZA_CY
for dy in range(-PLAZA_R, PLAZA_R + 1):
    w = PLAZA_R - abs(dy)
    for dx in range(-w, w + 1):
        setc(cx + dx, cy + dy, PLAZA)
for i in range(-PLAZA_R + 1, PLAZA_R):
    setc(cx + i, cy, SIDEWALK); setc(cx, cy + i, SIDEWALK)
for dx in range(-1, 2):
    for dy in range(-1, 2):
        setc(cx + dx, cy + dy, WATER)
for dx, dy in [(-3, -3), (3, -3), (3, 3), (-3, 3)]:
    setc(cx + dx, cy + dy, MONUMENT)
setc(cx - 4, cy, OMBU); setc(cx + 4, cy, OMBU)

# trees
for (px, py) in [(19, 29), (25, 29), (19, 37), (25, 37), (9, 13), (15, 8),
                 (29, 8), (40, 9), (9, 22), (35, 22), (9, 36), (35, 36),
                 (22, 27), (22, 39)]:
    if getc(px, py) in (GRASS, SIDEWALK):
        setc(px, py, TREE)

# --- emit ---
lines = []
lines.append('; ===== TinyMont :: Plano de Monte Grande (44x48) =====')
lines.append('; Edita este archivo a mano para cambiar la ciudad.')
lines.append('; TERRENO:  . pasto   # calle   : vereda   T arbol   O ginkgo')
lines.append(';           = via    _ anden   P plaza    ~ fuente   M monumento')
lines.append('; EDIFICIOS: una letra por tile. La forma del edificio = bloque de esa letra.')
lines.append('; LEYENDA de edificios (letra = nombre = tipo de render):')
for letter, name, btype in LEGEND:
    lines.append(';   %s = %s = %s' % (letter, name, btype))
lines.append('; CARTELES de calle (nombre@x,y):')
lines.append(';   @ ALEM@8,14  @ BV.BS AS@30,22  @ STA.MARINA@7,41  @ ALEM DOBLE@31,41')
lines.append(';   @ ESTACION MG@24,7  @ PLAZA MITRE@19,25')
lines.append('; Las lineas que empiezan con ; son comentarios. El mapa va abajo.')
lines.append('')

for y in range(MAP_H):
    row = []
    for x in range(MAP_W):
        if (x, y) in blds:
            row.append(blds[(x, y)])
        else:
            row.append(CH.get(t[y * MAP_W + x], '.'))
    lines.append(''.join(row))

import os
os.makedirs('data', exist_ok=True)
with open('data/map.txt', 'w') as f:
    f.write('\n'.join(lines) + '\n')

print('OK data/map.txt  %dx%d  edificios:%d' % (MAP_W, MAP_H, len(LEGEND)))
