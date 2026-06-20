class_name Pal
extends RefCounted
## Paleta alegre estilo plataformero clásico (Super Mario Bros / NES).
## Fuente única de verdad de color del juego. Ver docs/adr/0002.

# Cielo / fondo
const SKY := Color("#5c94fc")        # celeste clásico

# Pasto / vegetación
const GRASS := Color("#58d858")      # verde claro alegre
const GRASS_DK := Color("#1c9c1c")   # verde oscuro (follaje/sombra)

# Caminos / asfalto
const ROAD := Color("#9c9c9c")       # gris asfalto
const ROAD_DK := Color("#5c5c5c")
const ROAD_LINE := Color("#fcfcfc")  # líneas blancas

# Veredas
const SIDEWALK := Color("#e8d8b0")   # crema vereda
const SIDEWALK_DK := Color("#b8a880")

# Edificios / ladrillo
const BRICK := Color("#d85820")      # naranja ladrillo
const BRICK_DK := Color("#a02000")   # rojo oscuro
const ROOF := Color("#fc7460")       # techo
const WALL_TAN := Color("#fce0a8")   # pared clara

# Agua
const WATER := Color("#3cbcfc")      # celeste agua
const WATER_DK := Color("#0070ec")

# Madera / troncos
const WOOD := Color("#a05000")
const WOOD_DK := Color("#7c3800")

# Neutros / acentos
const WHITE := Color("#fcfcfc")
const BLACK := Color("#181018")
const YELLOW := Color("#fcd800")     # faroles, detalles alegres
const SKIN := Color("#fcc0a0")
const RED := Color("#e03020")
const BLUE := Color("#2038ec")
const PINK := Color("#fc74a0")
const PURPLE := Color("#c040c0")
