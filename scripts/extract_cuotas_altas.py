#!/usr/bin/env python3
"""Extrae cuotas y altas diarias (TEMM, PORTA, PREPAGO) desde Plan Junio 2026.xlsx"""
import json
import re
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
EXCEL = ROOT / "Plan Junio 2026.xlsx"
MES = sys.argv[1] if len(sys.argv) > 1 else "2026-06"


def clean_id(v):
    if pd.isna(v):
        return None
    s = str(int(v)) if isinstance(v, float) and v == int(v) else str(v).strip()
    return re.sub(r"^0+", "", s.split(".")[0])


def parse_cuota():
    df = pd.read_excel(EXCEL, sheet_name="Cuota", header=5)
    stores = {}
    for _, row in df.iterrows():
        idpv = clean_id(row.get("IDPV"))
        if not idpv:
            continue
        dias = {}
        for d in range(1, 32):
            dias[str(d)] = {
                "PORTA": {"cuota": float(row.get(f"{d} porta") or 0)},
                "TEMM": {"cuota": float(row.get(f"{d} temm") or 0)},
                "PREPAGO": {"cuota": float(row.get(f"{d} gral") or 0)},
            }
        stores[idpv] = {
            "idpdv": idpv,
            "tienda": str(row.get("NOMBRE_IDPV", "")).strip(),
            "sup": str(row.get("SUPERVISOR", "")).strip(),
            "cadena": str(row.get("CADENA", "")).strip(),
            "dias": dias,
        }
    return stores


def parse_altas_section(df, start_row, end_row):
    stores = {}
    for i in range(start_row, end_row):
        row = df.iloc[i]
        idpv = clean_id(row.iloc[0])
        if not idpv:
            continue
        dias = {}
        for d in range(1, 32):
            col_idx = 3 + d
            val = row.iloc[col_idx] if col_idx < len(row) else None
            dias[str(d)] = 0 if pd.isna(val) else float(val)
        stores[idpv] = dias
    return stores


def main():
    df_a = pd.read_excel(EXCEL, sheet_name="Altas", header=None)
    porta_altas = parse_altas_section(df_a, 2, 109)
    temm_altas = parse_altas_section(df_a, 111, 218)
    prepago_altas = parse_altas_section(df_a, 220, len(df_a))

    cuota = parse_cuota()
    merged = []
    for idpv, c in cuota.items():
        dias_out = {}
        for d in range(1, 32):
            dk = str(d)
            pa = porta_altas.get(idpv, {}).get(dk, 0)
            ta = temm_altas.get(idpv, {}).get(dk, 0)
            pra = prepago_altas.get(idpv, {}).get(dk, 0)
            dias_out[dk] = {}
            for prod, cu, al in [
                ("PORTA", c["dias"][dk]["PORTA"]["cuota"], pa),
                ("TEMM", c["dias"][dk]["TEMM"]["cuota"], ta),
                ("PREPAGO", c["dias"][dk]["PREPAGO"]["cuota"], pra),
            ]:
                dias_out[dk][prod] = {
                    "cuota": round(cu, 4),
                    "altas": round(al, 4),
                    "gap": round(al - cu, 4),
                }
        merged.append(
            {
                "idpdv": idpv,
                "mes": MES,
                "tienda": c["tienda"],
                "sup": c["sup"],
                "cadena": c["cadena"],
                "dias": dias_out,
            }
        )

    out = ROOT / f"cuotas_altas_{MES}.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"mes": MES, "tiendas": merged}, f, ensure_ascii=False, indent=2)
    print(f"OK: {len(merged)} tiendas -> {out.name}")


if __name__ == "__main__":
    main()
