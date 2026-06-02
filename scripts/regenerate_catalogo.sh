#!/usr/bin/env bash
# Regenera catalogo_tiendas_106.json desde Plan Junio 2026.xlsx (pestaña Seg Diario)
set -euo pipefail
cd "$(dirname "$0")/.."
python3 << 'PY'
import pandas as pd, json, re, openpyxl

def normalize_cadena(val):
    if pd.isna(val): return "SUBURBIA"
    low = str(val).strip().lower()
    if 'coppel' in low: return 'COPPEL'
    if 'elektra' in low: return 'ELEKTRA'
    if 'suburbia' in low: return 'SUBURBIA'
    return str(val).strip().upper()

def clean_id(idpv):
    s = str(int(idpv)) if isinstance(idpv, float) and idpv == int(idpv) else str(idpv).strip()
    return re.sub(r'^0+', '', s.split('.')[0])

df = pd.read_excel('Plan Junio 2026.xlsx', sheet_name='Seg Diario', header=4)
wb = openpyxl.load_workbook('Plan Junio 2026.xlsx', read_only=True, data_only=True)
dia_act = wb['Seg Diario']['F3'].value
wb.close()

records = []
for _, row in df.iterrows():
    if pd.isna(row.get('IDPV')): continue
    est = row.get('ESTATUS')
    records.append({
        'id': clean_id(row['IDPV']),
        'tienda': str(row['NOMBRE_IDPV']).strip(),
        'plaza': str(row['PLAZA']).strip().upper(),
        'lider': str(row['LIDER']).strip() if pd.notna(row.get('LIDER')) else '',
        'sup': str(row['SUPERVISOR']).strip() if pd.notna(row.get('SUPERVISOR')) else '',
        'estatus': str(est).strip().upper() if pd.notna(est) and str(est).strip() else 'ACTIVO',
        'cad': normalize_cadena(row.get('CADENA')),
        'altas': int(round(float(row['ALTAS.1'] or 0))),
        'cuota': int(round(float(row['CUOTA.1'] or 0))),
        'altas_total': int(round(float(row['ALTAS'] or 0))),
        'cuota_total': int(round(float(row['CUOTA'] or 0))),
        'altas_porta': int(round(float(row['ALTAS.2'] or 0))),
        'cuota_porta': int(round(float(row['CUOTA.2'] or 0))),
        'altas_voz': int(round(float(row['ALTAS.3'] or 0))),
        'cuota_voz': int(round(float(row['CUOTA.3'] or 0))),
    })

payload = {'actualizado_al': str(dia_act) if dia_act else 'Junio 2026', 'list': records}
with open('catalogo_tiendas_106.json', 'w', encoding='utf-8') as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
print(f"OK: {len(records)} tiendas -> catalogo_tiendas_106.json")
PY
