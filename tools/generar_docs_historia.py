#!/usr/bin/env python3
"""Genera la documentación de personajes y misiones desde los datos reales del juego.

Fuentes: scenes/main.tscn (NPCs, objetos, misiones), scenes/mapas/*.tscn (vecinos de otros
mapas) y data/personajes/*.json (fichas). Salida: docs/historia/.
Uso: python3 tools/generar_docs_historia.py   (correrlo después de cambiar personajes o misiones)
"""
import json, os, re, unicodedata

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDA = os.path.join(RAIZ, "docs", "historia")
T = 16

ZONAS = [  # (nombre, x0, y0, x1, y1) en celdas del mapa principal
    ("Estación y andén", 0, 0, 43, 6),
    ("Plaza Mitre", 17, 28, 27, 38),
    ("Alrededores de la plaza", 12, 24, 32, 42),
    ("Norte (Alem y comercios)", 0, 7, 43, 23),
    ("Sur del barrio", 0, 39, 43, 47),
    ("Este del barrio", 28, 0, 43, 47),
    ("Oeste del barrio", 0, 0, 15, 47),
]
NOMBRES_ITEM = {}


def zona(c):
    for n, x0, y0, x1, y1 in ZONAS:
        if x0 <= c[0] <= x1 and y0 <= c[1] <= y1:
            return n
    return "Barrio"


def fid(nombre):
    n = "".join(ch for ch in unicodedata.normalize("NFD", nombre.lower().strip()) if unicodedata.category(ch) != "Mn")
    return n.replace(" ", "_")


def bloques(texto):
    return re.split(r"\n(?=\[node )", texto)


def valor(b, clave):
    m = re.search(r"^" + clave + r" = (.+?)(?=\n[a-z_]+ = |\n\n|\Z)", b, re.S | re.M)
    if not m:
        return None
    crudo = m.group(1).strip()
    # Los textos de la escena pueden tener saltos de línea reales dentro de las comillas.
    escapado = re.sub(r'"(?:[^"\\]|\\.)*"', lambda q: q.group(0).replace("\n", "\\n"), crudo, flags=re.S)
    try:
        return json.loads(escapado)
    except Exception:
        return crudo.strip('"')


def celda(b):
    m = re.search(r"position = Vector2\(([-\d.]+), ([-\d.]+)\)", b)
    return (int(float(m.group(1))) // T, int(float(m.group(2))) // T) if m else None


def lista(lineas):
    if not lineas:
        return "_(sin definir)_\n"
    return "".join(f"- {str(l).replace(chr(10), ' ')}\n" for l in lineas)


def nombre_item(i):
    return NOMBRES_ITEM.get(i, i)


def cargar_nombres_items():
    s = open(os.path.join(RAIZ, "scripts/art/item_art.gd"), encoding="utf-8").read()
    for k, v in re.findall(r'"([a-z_]+)": "([^"]+)"', s.split("const NOMBRES")[1].split("}")[0]):
        NOMBRES_ITEM[k] = v


def main():
    cargar_nombres_items()
    escena = open(os.path.join(RAIZ, "scenes/main.tscn"), encoding="utf-8").read()
    npcs, objetos = [], {}
    for b in bloques(escena):
        nodo = re.search(r'\[node name="([^"]+)"', b)
        if not nodo:
            continue
        if 'npc_name = "' in b:
            npcs.append((nodo.group(1), b))
        elif re.search(r'^item = "', b, re.M):
            objetos[valor(b, "item")] = (nodo.group(1), celda(b), valor(b, "nombre") or "")
    os.makedirs(os.path.join(SALIDA, "personajes"), exist_ok=True)

    indice, misiones = [], []
    ayudas_por_mision = {}
    for nodo, b in npcs:
        for a in valor(b, "ayudas") or []:
            ayudas_por_mision.setdefault(a["mision"], []).append((valor(b, "npc_name"), a))

    for nodo, b in npcs:
        nombre = valor(b, "npc_name")
        ficha = json.load(open(os.path.join(RAIZ, "data/personajes", fid(nombre) + ".json"), encoding="utf-8"))
        c = celda(b)
        mision = valor(b, "mision_id") or ""
        es_ayudante_clasico = bool(valor(b, "otorga_item"))
        aspecto = ", ".join(f"{k}: {valor(b, k)}" for k in ["pelo", "gorra", "vello_facial", "lentes", "marca", "accesorio"] if valor(b, k) not in (None, ""))
        plan = "".join(f"- {e['poi']}: {e['desde']} a {e['hasta']} h" + (f" (días {e['dias']})" if e['dias'] else " (todos los días)") + "\n" for e in ficha["plan_semanal"])
        afin = ficha["personalidad"]["afinidad"]
        doc = [f"# {nombre}\n",
               f"- **Nodo:** `{nodo}` en `scenes/main.tscn`",
               f"- **Ficha:** `data/personajes/{fid(nombre)}.json`",
               f"- **Ubicación:** celda {c}, {zona(c)}",
               f"- **Aspecto:** {aspecto or 'pelo corto, sin accesorios'}",
               "",
               "## Quién es\n", ficha["descripcion"] + "\n",
               "## Personalidad\n",
               "Afinidades (0 a 1): " + ", ".join(f"{k} {v}" for k, v in afin.items()) + f". Fuerza de rutina: {ficha['personalidad']['fuerza_rutina']}.\n",
               "## Rutina semanal\n", plan,
               "## Presentación (primera charla)\n", lista(valor(b, "dialog_presentacion")),
               "## Diálogo ambiental\n", lista(valor(b, "dialog_lines"))]
        if mision and not es_ayudante_clasico:
            doc += [f"## Misión: `{mision}`\n",
                    "**Encargo**\n", lista(valor(b, "dialog_encargo")),
                    "**Recordatorio**\n", lista(valor(b, "dialog_recordatorio")),
                    "**Entrega**\n", lista(valor(b, "dialog_entrega"))]
            if valor(b, "dialog_bloqueada"):
                doc += ["**Si todavía no alcanza el progreso**\n", lista(valor(b, "dialog_bloqueada"))]
            misiones.append((mision, nombre, nodo, b))
        if es_ayudante_clasico:
            doc += [f"## Ayuda en `{mision}`\n", f"Entrega {nombre_item(valor(b, 'otorga_item'))}.\n", lista(valor(b, "dialog_entrega"))]
        for a in valor(b, "ayudas") or []:
            doc += [f"## Ayuda en `{a['mision']}`\n", f"Entrega {nombre_item(a['item'])}.\n", lista(a.get("lineas"))]
        doc += ["## Rumores que sabe\n", lista(ficha["rumores_semilla"]),
                "## Diálogos por humor\n"]
        for h, ls in ficha.get("dialogos_por_humor", {}).items():
            doc.append(f"- **{h}:** " + " / ".join(ls))
        doc += ["", "## Notas para trabajar\n", "- [ ] Revisar identidad y tono", "- [ ] Revisar misión y diálogos", "- [ ] Revisar aspecto visual", ""]
        open(os.path.join(SALIDA, "personajes", fid(nombre) + ".md"), "w", encoding="utf-8").write("\n".join(doc))
        objetivo = f"Misión `{mision}`" if mision and not es_ayudante_clasico else ("Ayuda en `" + mision + "`" if es_ayudante_clasico else "Ambiental (rutina)")
        indice.append(f"| [{nombre}](personajes/{fid(nombre)}.md) | {ficha['descripcion']} | {objetivo} | {zona(c)} |")

    otros = []
    for archivo in sorted(os.listdir(os.path.join(RAIZ, "scenes/mapas"))):
        t = open(os.path.join(RAIZ, "scenes/mapas", archivo), encoding="utf-8").read()
        mapa = valor(t.split("[node")[1] if "[node" in t else t, "nombre_mapa") or archivo
        for nodo, b in [(re.search(r'\[node name="([^"]+)"', x).group(1), x) for x in bloques(t) if 'npc_name = "' in x]:
            otros.append(f"| {valor(b, 'npc_name')} | {archivo.replace('.tscn', '')} | " + " / ".join(valor(b, "dialog_lines") or []) + " |")

    readme = ["# Personajes de TinyMont\n",
              "Documentación generada desde los datos del juego con `python3 tools/generar_docs_historia.py`.",
              "Cada personaje tiene su archivo para trabajarlo en detalle. Si se edita el juego, regenerar.\n",
              f"## Mapa principal ({len(indice)} vecinos)\n",
              "| Personaje | Quién es | Objetivo | Zona |", "|---|---|---|---|"] + indice + [
              "", f"## Otros mapas ({len(otros)} vecinos, sin misión ni cerebro)\n",
              "| Personaje | Mapa | Qué dice |", "|---|---|---|"] + otros + [
              "", "Ver también: [misiones](misiones.md).", ""]
    open(os.path.join(SALIDA, "README.md"), "w", encoding="utf-8").write("\n".join(readme))

    m = ["# Misiones de TinyMont\n",
         "Generado desde los datos del juego con `python3 tools/generar_docs_historia.py`.\n",
         f"Total: {len(misiones)} misiones. Al completarlas todas, el barrio se reúne en la Plaza Mitre.\n",
         "| # | Misión | Quién la da | Tipo | Qué pide | Recompensa |", "|---|---|---|---|---|---|"]
    detalle = []
    for i, (mid, nombre, nodo, b) in enumerate(misiones, 1):
        req, cont, prev, lim = valor(b, "requisito_item"), valor(b, "requisito_contador"), valor(b, "requiere_completadas"), valor(b, "limite_segundos")
        ayud = ayudas_por_mision.get(mid, [])
        clasico = [ (valor(x, "npc_name")) for _, x in npcs if valor(x, "mision_id") == mid and valor(x, "otorga_item")]
        if lim:
            tipo, pide = f"Contrarreloj ({float(lim):.0f} s)", f"{nombre_item(req)}, que da {ayud[0][0] if ayud else '?'}"
        elif cont:
            tipo, pide = "Contador", f"Hablar con {cont} vecinos distintos"
        elif prev:
            tipo, pide = f"Requiere {prev} misiones completadas", "Volver con el progreso"
        elif req in objetos:
            o = objetos[req]
            tipo, pide = "Búsqueda", f"{nombre_item(req)} (objeto `{o[0]}`, celda {o[1]}, {zona(o[1])})"
        elif ayud or clasico:
            quien = ayud[0][0] if ayud else clasico[0]
            tipo, pide = "Recado", f"{nombre_item(req)}, que da {quien}"
        else:
            tipo, pide = "Otro", nombre_item(req or "")
        rec = nombre_item(valor(b, "recompensa_item") or "")
        m.append(f"| {i} | `{mid}` | [{nombre}](personajes/{fid(nombre)}.md) | {tipo} | {pide} | {rec} |")
        detalle += [f"### {i}. `{mid}`: {nombre}\n", f"- **Tipo:** {tipo}", f"- **Qué pide:** {pide}", f"- **Recompensa:** {rec}",
                    "", "**Encargo**\n", lista(valor(b, "dialog_encargo")), "**Entrega**\n", lista(valor(b, "dialog_entrega")),
                    "- [ ] Revisada", ""]
    open(os.path.join(SALIDA, "misiones.md"), "w", encoding="utf-8").write("\n".join(m + ["", "## Detalle", ""] + detalle))
    print(f"OK: {len(indice)} personajes, {len(otros)} de otros mapas, {len(misiones)} misiones -> docs/historia/")


if __name__ == "__main__":
    main()
